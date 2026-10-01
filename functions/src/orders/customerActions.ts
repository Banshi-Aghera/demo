import { FieldValue, Timestamp } from 'firebase-admin/firestore';
import { onCall } from 'firebase-functions/v2/https';
import { RAZORPAY_KEY_ID, RAZORPAY_KEY_SECRET, RETURN_WINDOW_DAYS, MAX_RETURN_PHOTOS } from '../config';
import { fail, isAdmin, optStr, requireAuth, str } from '../lib/errors';
import type { OrderDoc } from '../lib/types';
import { cancelAndRestock, ordersCol, refundIfPaid } from './orderOps';

const CUSTOMER_CANCELLABLE = ['pendingPayment', 'placed', 'packed'] as const;

/** Customers can cancel until the order ships; paid orders are refunded. */
export const cancelOrder = onCall(
  { secrets: [RAZORPAY_KEY_ID, RAZORPAY_KEY_SECRET] },
  async (req) => {
    const uid = requireAuth(req);
    const orderId = str(req.data?.orderId, 'order', 100);
    const reason = optStr(req.data?.reason, 300) || 'Cancelled by customer';

    const order = (await ordersCol().doc(orderId).get()).data() as OrderDoc | undefined;
    if (!order) return fail('not-found', 'Order not found.');
    const admin = order.userId !== uid && (await isAdmin(uid));
    if (order.userId !== uid && !admin) return fail('not-found', 'Order not found.');

    const before = await cancelAndRestock(orderId, reason, [...CUSTOMER_CANCELLABLE]);
    if (!before) {
      return fail('failed-precondition', 'This order has already shipped and can no longer be cancelled. You can request a return after delivery.');
    }
    if (before.paymentStatus === 'paid') await refundIfPaid(orderId);
    return { ok: true };
  },
);

const RETURN_REASONS = ['damaged', 'wrongItem', 'notAsDescribed', 'qualityIssue', 'other'];

export const requestReturn = onCall(async (req) => {
  const uid = requireAuth(req);
  const orderId = str(req.data?.orderId, 'order', 100);
  const reason = str(req.data?.reason, 'reason', 40);
  if (!RETURN_REASONS.includes(reason)) fail('invalid-argument', 'Choose a return reason.');
  const comment = optStr(req.data?.comment, 1000);
  const photoUrls = Array.isArray(req.data?.photoUrls) ? (req.data.photoUrls as unknown[]) : [];
  if (photoUrls.length > MAX_RETURN_PHOTOS || photoUrls.some((u) => typeof u !== 'string' || !u.startsWith('https://'))) {
    fail('invalid-argument', `Attach up to ${MAX_RETURN_PHOTOS} photos.`);
  }

  const ref = ordersCol().doc(orderId);
  const order = (await ref.get()).data() as OrderDoc | undefined;
  if (!order || order.userId !== uid) return fail('not-found', 'Order not found.');
  if (order.status !== 'delivered') {
    return fail('failed-precondition', 'Returns can be requested only after delivery.');
  }
  const deliveredAt = order.deliveredAt?.toDate() ?? order.updatedAt.toDate();
  const ageDays = (Date.now() - deliveredAt.getTime()) / 86_400_000;
  if (ageDays > RETURN_WINDOW_DAYS) {
    return fail('failed-precondition', `The ${RETURN_WINDOW_DAYS}-day return window for this order has closed.`);
  }

  await ref.update({
    status: 'returnRequested',
    returnRequest: {
      reason,
      comment,
      photoUrls,
      requestedAt: Timestamp.now(),
      status: 'requested',
    },
    statusHistory: FieldValue.arrayUnion({ status: 'returnRequested', at: Timestamp.now() }),
    updatedAt: FieldValue.serverTimestamp(),
  });
  return { ok: true };
});
