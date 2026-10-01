import { FieldValue, Timestamp } from 'firebase-admin/firestore';
import { logger } from 'firebase-functions';
import { db, COL, RAZORPAY_KEY_ID, RAZORPAY_KEY_SECRET } from '../config';
import { refundPayment, toPaise } from '../lib/razorpay';
import { applyStockDelta, readProducts, writeProducts } from '../lib/stock';
import type { OrderDoc, OrderStatus, PaymentStatus } from '../lib/types';

export const ordersCol = () => db.collection(COL.orders);

/**
 * Cancels an order and puts its stock back, if it is still in one of
 * [allowed]. Returns the order as it was before, or null if not cancelled.
 */
export async function cancelAndRestock(
  orderId: string,
  reason: string,
  allowed: OrderStatus[],
): Promise<OrderDoc | null> {
  return db.runTransaction(async (tx) => {
    const ref = ordersCol().doc(orderId);
    const snap = await tx.get(ref);
    if (!snap.exists) return null;
    const order = snap.data() as OrderDoc;
    if (!allowed.includes(order.status)) return null;

    const products = await readProducts(tx, order.items.map((i) => i.productId));
    for (const item of order.items) {
      const p = products.get(item.productId)?.data;
      if (p) applyStockDelta(p, item.variantId, item.quantity);
    }
    writeProducts(tx, products);

    let paymentStatus: PaymentStatus = order.paymentStatus;
    if (order.paymentStatus === 'paid') paymentStatus = 'refundPending';
    else if (order.paymentStatus === 'pending') paymentStatus = 'failed';

    tx.update(ref, {
      status: 'cancelled',
      paymentStatus,
      cancelReason: reason,
      statusHistory: FieldValue.arrayUnion({ status: 'cancelled', at: Timestamp.now(), note: reason }),
      updatedAt: FieldValue.serverTimestamp(),
    });
    return order;
  });
}

/**
 * Refunds a Razorpay payment in full. On failure the order stays
 * "refundPending" so an admin can retry from the panel.
 */
export async function refundIfPaid(orderId: string): Promise<void> {
  const ref = ordersCol().doc(orderId);
  const order = (await ref.get()).data() as OrderDoc | undefined;
  if (!order || order.paymentStatus !== 'refundPending' || !order.razorpayPaymentId) return;
  try {
    const refund = await refundPayment(
      RAZORPAY_KEY_ID.value(),
      RAZORPAY_KEY_SECRET.value(),
      order.razorpayPaymentId,
      toPaise(order.pricing.grandTotal),
    );
    await ref.update({
      paymentStatus: 'refunded',
      refundId: refund.id,
      updatedAt: FieldValue.serverTimestamp(),
    });
  } catch (e) {
    logger.error('Refund failed', { orderId, error: String(e) });
  }
}

/**
 * Marks a Razorpay order paid (idempotent). Used by the app after checkout
 * and by the webhook as a backup. If the order was already auto-cancelled
 * for taking too long, the payment is refunded instead.
 */
export async function markOrderPaid(orderId: string, paymentId: string): Promise<'paid' | 'refunded' | 'noop'> {
  const outcome = await db.runTransaction(async (tx) => {
    const ref = ordersCol().doc(orderId);
    const snap = await tx.get(ref);
    if (!snap.exists) return 'noop' as const;
    const order = snap.data() as OrderDoc;

    if (order.paymentStatus === 'paid' || order.paymentStatus === 'refunded') return 'noop' as const;

    if (order.status === 'cancelled') {
      tx.update(ref, {
        razorpayPaymentId: paymentId,
        paymentStatus: 'refundPending',
        updatedAt: FieldValue.serverTimestamp(),
      });
      return 'refund' as const;
    }

    if (order.status !== 'pendingPayment') return 'noop' as const;

    // Reads first: cart items and coupon.
    const cartRef = db.collection(COL.carts).doc(order.userId).collection(COL.items);
    const cartSnap = await tx.get(cartRef);
    const couponRef = order.pricing.couponCode
      ? db.collection(COL.coupons).doc(order.pricing.couponCode)
      : null;
    const couponSnap = couponRef ? await tx.get(couponRef) : null;

    tx.update(ref, {
      status: 'placed',
      paymentStatus: 'paid',
      razorpayPaymentId: paymentId,
      statusHistory: FieldValue.arrayUnion({ status: 'placed', at: Timestamp.now() }),
      updatedAt: FieldValue.serverTimestamp(),
    });
    // Only remove what was ordered; items added after checkout stay.
    const ordered = new Set(order.items.map((i) => (i.variantId ? `${i.productId}__${i.variantId}` : i.productId)));
    cartSnap.docs.filter((d) => ordered.has(d.id)).forEach((d) => tx.delete(d.ref));
    if (couponRef && couponSnap?.exists) tx.update(couponRef, { usedCount: FieldValue.increment(1) });
    return 'paid' as const;
  });

  if (outcome === 'refund') {
    await refundIfPaid(orderId);
    return 'refunded';
  }
  return outcome;
}
