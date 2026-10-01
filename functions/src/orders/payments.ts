import { onCall, onRequest } from 'firebase-functions/v2/https';
import { logger } from 'firebase-functions';
import { RAZORPAY_KEY_ID, RAZORPAY_KEY_SECRET, RAZORPAY_WEBHOOK_SECRET } from '../config';
import { fail, requireAuth, str } from '../lib/errors';
import { toPaise, verifyPaymentSignature, verifyWebhookSignature } from '../lib/razorpay';
import type { OrderDoc } from '../lib/types';
import { markOrderPaid, ordersCol } from './orderOps';

/** Called by the app after Razorpay checkout succeeds. */
export const verifyPayment = onCall(
  { secrets: [RAZORPAY_KEY_ID, RAZORPAY_KEY_SECRET] },
  async (req) => {
    const uid = requireAuth(req);
    const orderId = str(req.data?.orderId, 'order', 100);
    const paymentId = str(req.data?.razorpayPaymentId, 'payment id', 100);
    const rzpOrderId = str(req.data?.razorpayOrderId, 'Razorpay order id', 100);
    const signature = str(req.data?.razorpaySignature, 'signature', 200);

    const order = (await ordersCol().doc(orderId).get()).data() as OrderDoc | undefined;
    if (!order || order.userId !== uid) return fail('not-found', 'Order not found.');
    if (order.razorpayOrderId !== rzpOrderId) {
      return fail('permission-denied', 'This payment does not belong to this order.');
    }
    if (!verifyPaymentSignature(rzpOrderId, paymentId, signature, RAZORPAY_KEY_SECRET.value())) {
      logger.warn('Bad payment signature', { orderId, uid });
      return fail('permission-denied', 'We could not verify this payment. If money was deducted, it will be refunded automatically.');
    }

    const result = await markOrderPaid(orderId, paymentId);
    return { status: result === 'refunded' ? 'refunded' : 'paid' };
  },
);

/** Gives the app what it needs to reopen Razorpay for an unpaid order. */
export const retryPayment = onCall(
  { secrets: [RAZORPAY_KEY_ID] },
  async (req) => {
    const uid = requireAuth(req);
    const orderId = str(req.data?.orderId, 'order', 100);
    const order = (await ordersCol().doc(orderId).get()).data() as OrderDoc | undefined;
    if (!order || order.userId !== uid) return fail('not-found', 'Order not found.');
    if (order.status !== 'pendingPayment' || !order.razorpayOrderId) {
      return fail('failed-precondition', 'This order does not need payment.');
    }
    return {
      orderId,
      orderNumber: order.orderNumber,
      paymentMethod: order.paymentMethod,
      grandTotal: order.pricing.grandTotal,
      totalSavings: order.pricing.productDiscount + order.pricing.couponDiscount,
      razorpay: {
        keyId: RAZORPAY_KEY_ID.value(),
        orderId: order.razorpayOrderId,
        amountPaise: toPaise(order.pricing.grandTotal),
        name: order.customerName,
        email: order.customerEmail,
        contact: order.customerPhone,
      },
    };
  },
);

/**
 * Razorpay webhook (backup for when the app closes before verifyPayment).
 * Dashboard > Settings > Webhooks: URL of this function, events
 * "payment.captured", secret = RAZORPAY_WEBHOOK_SECRET.
 */
export const razorpayWebhook = onRequest(
  { secrets: [RAZORPAY_KEY_ID, RAZORPAY_KEY_SECRET, RAZORPAY_WEBHOOK_SECRET] },
  async (req, res) => {
    const signature = req.get('x-razorpay-signature') ?? '';
    if (req.method !== 'POST' || !verifyWebhookSignature(req.rawBody, signature, RAZORPAY_WEBHOOK_SECRET.value())) {
      res.status(400).send('invalid');
      return;
    }
    const event = req.body?.event as string | undefined;
    const payment = req.body?.payload?.payment?.entity;
    if (event === 'payment.captured' && payment) {
      const orderId = payment.notes?.orderId as string | undefined;
      if (orderId) {
        const outcome = await markOrderPaid(orderId, payment.id as string);
        logger.info('Webhook processed', { orderId, outcome });
      }
    }
    res.status(200).send('ok');
  },
);
