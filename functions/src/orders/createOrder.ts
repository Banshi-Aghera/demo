import { FieldValue, Timestamp } from 'firebase-admin/firestore';
import { onCall } from 'firebase-functions/v2/https';
import { logger } from 'firebase-functions';
import { db, COL, RAZORPAY_KEY_ID, RAZORPAY_KEY_SECRET } from '../config';
import { fail, optStr, requireActiveUser, requireAuth, str } from '../lib/errors';
import { DEFAULT_PRICING, couponProblem, priceOrder, type BaseLine } from '../lib/pricing';
import { createRazorpayOrder, toPaise } from '../lib/razorpay';
import { applyStockDelta, availableStock, readProducts, writeProducts } from '../lib/stock';
import type {
  AddressSnapshot, BusinessSettings, CartItemDoc, CouponDoc, OrderDoc, PaymentMethod, PricingSettings,
} from '../lib/types';
import { cancelAndRestock } from './orderOps';

/** Indian financial year label for a date, e.g. "26-27" (April to March, IST). */
function financialYear(now: Date): string {
  const ist = new Date(now.getTime() + 5.5 * 3600 * 1000);
  const y = ist.getUTCFullYear();
  const start = ist.getUTCMonth() + 1 >= 4 ? y : y - 1;
  const two = (n: number) => String(n % 100).padStart(2, '0');
  return `${two(start)}-${two(start + 1)}`;
}

/**
 * Places an order from the user's cart. Everything is priced and checked on
 * the server: products, variants, stock, coupon, delivery fee, COD limit.
 * Stock is reserved here; unpaid Razorpay orders release it after 30 minutes.
 */
export const createOrder = onCall(
  { secrets: [RAZORPAY_KEY_ID, RAZORPAY_KEY_SECRET] },
  async (req) => {
    const uid = requireAuth(req);
    const user = await requireActiveUser(uid);

    const addressId = str(req.data?.addressId, 'address', 100);
    const paymentMethod = str(req.data?.paymentMethod, 'payment method', 20) as PaymentMethod;
    if (paymentMethod !== 'razorpay' && paymentMethod !== 'cod') {
      fail('invalid-argument', 'Choose a valid payment method.');
    }
    const couponCode = optStr(req.data?.couponCode, 30).toUpperCase();
    const deliveryOption = optStr(req.data?.deliveryOption, 20) || 'standard';
    if (deliveryOption !== 'standard') {
      // Neighbour Drop slots are added in Phase 5.
      fail('invalid-argument', 'This delivery option is not available yet.');
    }

    const now = new Date();
    const fy = financialYear(now);

    const created = await db.runTransaction(async (tx) => {
      // ---------- Reads ----------
      const cartRef = db.collection(COL.carts).doc(uid).collection(COL.items);
      const cartSnap = await tx.get(cartRef);
      if (cartSnap.empty) fail('failed-precondition', 'Your cart is empty.');
      const cart = cartSnap.docs.map((d) => d.data() as CartItemDoc);

      const addressSnap = await tx.get(
        db.collection(COL.users).doc(uid).collection(COL.addresses).doc(addressId),
      );
      if (!addressSnap.exists) fail('not-found', 'That address was not found. Choose another one.');
      const a = addressSnap.data()!;

      const products = await readProducts(tx, cart.map((c) => c.productId));

      const [pricingSnap, businessSnap, orderCounterSnap, invoiceCounterSnap] = await tx.getAll(
        db.collection(COL.appSettings).doc('pricing'),
        db.collection(COL.appSettings).doc('business'),
        db.collection(COL.counters).doc('orders'),
        db.collection(COL.counters).doc(`invoice-${fy}`),
      );
      const couponRef = couponCode ? db.collection(COL.coupons).doc(couponCode) : null;
      const couponSnap = couponRef ? await tx.get(couponRef) : null;

      // ---------- Validate and price ----------
      const settings: PricingSettings = { ...DEFAULT_PRICING, ...(pricingSnap.data() ?? {}) };
      const seller = (businessSnap.data() as BusinessSettings | undefined) ?? null;

      const base: BaseLine[] = cart.map((c) => {
        const p = products.get(c.productId)?.data;
        if (!p || !p.active) {
          return fail('failed-precondition', 'An item in your cart is no longer available. Remove it and try again.');
        }
        const variantId = c.variantId ?? null;
        const variant = variantId ? p.variants?.find((v) => v.id === variantId) : undefined;
        if (variantId && !variant) {
          fail('failed-precondition', `The selected option of ${p.name} is no longer available.`);
        }
        const stock = availableStock(p, variantId);
        if (stock <= 0) fail('failed-precondition', `${p.name} is out of stock. Remove it from your cart.`);
        if (c.quantity > stock) {
          fail('failed-precondition', `Only ${stock} left of ${p.name}. Reduce the quantity in your cart.`);
        }
        if (!Number.isInteger(c.quantity) || c.quantity < 1) {
          fail('invalid-argument', `Invalid quantity for ${p.name}.`);
        }
        return {
          productId: c.productId,
          variantId,
          variantLabel: variant?.label ?? null,
          name: p.name,
          imageUrl: p.images?.[0] ?? null,
          unitPrice: variant?.price ?? p.price,
          mrp: variant?.mrp ?? p.mrp,
          gstRate: p.gstRate ?? 18,
          quantity: c.quantity,
        };
      });

      let coupon: CouponDoc | null = null;
      if (couponRef) {
        if (!couponSnap?.exists) fail('failed-precondition', 'That coupon code does not exist.');
        coupon = couponSnap!.data() as CouponDoc;
        const subtotal = base.reduce((s, l) => s + l.unitPrice * l.quantity, 0);
        const problem = couponProblem(coupon, subtotal, now);
        if (problem) fail('failed-precondition', problem);
      }

      const { lines, pricing } = priceOrder(base, settings, coupon, false);

      if (paymentMethod === 'cod' && pricing.grandTotal > settings.codMaxAmount) {
        fail('failed-precondition',
          `Cash on Delivery is available for orders up to ₹${settings.codMaxAmount}. Please pay online.`);
      }

      const address: AddressSnapshot = {
        fullName: a.fullName ?? '', phone: a.phone ?? '', line1: a.line1 ?? '', line2: a.line2 ?? '',
        landmark: a.landmark ?? '', city: a.city ?? '', state: a.state ?? '',
        stateCode: a.stateCode ?? '', pincode: a.pincode ?? '',
      };

      const orderSeq = ((orderCounterSnap.data()?.seq as number | undefined) ?? 0) + 1;
      const invoiceSeq = ((invoiceCounterSnap.data()?.seq as number | undefined) ?? 0) + 1;
      const orderNumber = `SC${String(orderSeq).padStart(6, '0')}`;
      const invoiceNumber = `SC/${fy}/${String(invoiceSeq).padStart(5, '0')}`;

      // ---------- Writes ----------
      for (const l of lines) {
        const p = products.get(l.productId)!.data!;
        applyStockDelta(p, l.variantId, -l.quantity);
      }
      writeProducts(tx, products);
      tx.set(orderCounterSnap.ref, { seq: orderSeq }, { merge: true });
      tx.set(invoiceCounterSnap.ref, { seq: invoiceSeq }, { merge: true });

      const isCod = paymentMethod === 'cod';
      const ts = Timestamp.now();
      const orderRef = db.collection(COL.orders).doc();
      const order: OrderDoc = {
        orderNumber,
        invoiceNumber,
        userId: uid,
        customerName: user.fullName || address.fullName,
        customerEmail: user.email ?? '',
        customerPhone: user.phone || address.phone,
        items: lines,
        address,
        deliveryOption: 'standard',
        paymentMethod,
        paymentStatus: isCod ? 'codPending' : 'pending',
        status: isCod ? 'placed' : 'pendingPayment',
        statusHistory: [{ status: isCod ? 'placed' : 'pendingPayment', at: ts }],
        pricing,
        taxType: seller && seller.stateCode && seller.stateCode !== address.stateCode ? 'inter' : 'intra',
        seller,
        razorpayOrderId: null,
        razorpayPaymentId: null,
        cancelReason: null,
        returnRequest: null,
        deliveredAt: null,
        createdAt: ts,
        updatedAt: ts,
      };
      tx.set(orderRef, order);

      if (isCod) {
        cartSnap.docs.forEach((d) => tx.delete(d.ref));
        if (couponRef) tx.update(couponRef, { usedCount: FieldValue.increment(1) });
      }
      return { orderId: orderRef.id, order };
    });

    const { orderId, order } = created;
    const response = {
      orderId,
      orderNumber: order.orderNumber,
      paymentMethod: order.paymentMethod,
      grandTotal: order.pricing.grandTotal,
      totalSavings: order.pricing.productDiscount + order.pricing.couponDiscount,
      razorpay: null as null | {
        keyId: string; orderId: string; amountPaise: number;
        name: string; email: string; contact: string;
      },
    };

    if (order.paymentMethod === 'razorpay') {
      try {
        const rzp = await createRazorpayOrder(RAZORPAY_KEY_ID.value(), RAZORPAY_KEY_SECRET.value(), {
          amountPaise: toPaise(order.pricing.grandTotal),
          receipt: order.orderNumber,
          notes: { orderId, orderNumber: order.orderNumber, userId: uid },
        });
        await db.collection(COL.orders).doc(orderId).update({ razorpayOrderId: rzp.id });
        response.razorpay = {
          keyId: RAZORPAY_KEY_ID.value(),
          orderId: rzp.id,
          amountPaise: toPaise(order.pricing.grandTotal),
          name: order.customerName,
          email: order.customerEmail,
          contact: order.customerPhone,
        };
      } catch (e) {
        logger.error('Razorpay order creation failed', { orderId, error: String(e) });
        await cancelAndRestock(orderId, 'Payment could not be started', ['pendingPayment']);
        fail('failed-precondition', 'We could not start the payment. Please try again or choose Cash on Delivery.');
      }
    }

    return response;
  },
);
