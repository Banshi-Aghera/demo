import { FieldValue, Timestamp } from 'firebase-admin/firestore';
import { onCall } from 'firebase-functions/v2/https';
import { db, COL, RAZORPAY_KEY_ID, RAZORPAY_KEY_SECRET } from '../config';
import { fail, isAdmin, optStr, requireAuth, str } from '../lib/errors';
import { notifyUser } from '../lib/notify';
import type { OrderDoc, OrderStatus } from '../lib/types';
import { applyStockDelta, readProducts, writeProducts } from '../lib/stock';
import { ordersCol, refundIfPaid } from '../orders/orderOps';

/** Only these moves are allowed, so the timeline can't go backwards. */
const NEXT: Record<string, OrderStatus[]> = {
  placed: ['packed'],
  packed: ['shipped'],
  shipped: ['outForDelivery'],
  outForDelivery: ['delivered'],
};

async function requireAdmin(uid: string) {
  if (!(await isAdmin(uid))) fail('permission-denied', 'This action is for administrators only.');
}

export const adminUpdateOrderStatus = onCall(async (req) => {
  const uid = requireAuth(req);
  await requireAdmin(uid);
  const orderId = str(req.data?.orderId, 'order', 100);
  const next = str(req.data?.status, 'status', 30) as OrderStatus;

  const ref = ordersCol().doc(orderId);
  const order = (await ref.get()).data() as OrderDoc | undefined;
  if (!order) return fail('not-found', 'Order not found.');
  if (!(NEXT[order.status] ?? []).includes(next)) {
    return fail('failed-precondition', `An order that is "${order.status}" cannot be moved to "${next}".`);
  }
  // onOrderUpdated adds the timeline entry, delivery stamp and notification.
  await ref.update({ status: next, updatedAt: FieldValue.serverTimestamp() });
  return { ok: true };
});

/**
 * Approves a return (restocks the items and refunds an online payment) or
 * rejects it, putting the order back to delivered.
 */
export const adminResolveReturn = onCall(
  { secrets: [RAZORPAY_KEY_ID, RAZORPAY_KEY_SECRET] },
  async (req) => {
    const uid = requireAuth(req);
    await requireAdmin(uid);
    const orderId = str(req.data?.orderId, 'order', 100);
    const approve = req.data?.approve === true;
    const reason = optStr(req.data?.reason, 300);

    const result = await db.runTransaction(async (tx) => {
      const ref = ordersCol().doc(orderId);
      const snap = await tx.get(ref);
      const order = snap.data() as OrderDoc | undefined;
      if (!order) return fail('not-found', 'Order not found.');
      if (order.status !== 'returnRequested') {
        return fail('failed-precondition', 'This order has no open return request.');
      }

      if (!approve) {
        tx.update(ref, {
          status: 'delivered',
          returnRequest: { ...order.returnRequest!, status: 'rejected', rejectReason: reason },
          statusHistory: FieldValue.arrayUnion({
            status: 'delivered', at: Timestamp.now(), note: reason || 'Return not approved',
          }),
          updatedAt: FieldValue.serverTimestamp(),
        });
        return { refund: false, userId: order.userId, orderNumber: order.orderNumber, approved: false };
      }

      const products = await readProducts(tx, order.items.map((i) => i.productId));
      for (const item of order.items) {
        const p = products.get(item.productId)?.data;
        if (p) applyStockDelta(p, item.variantId, item.quantity);
      }
      writeProducts(tx, products);

      const refund = order.paymentStatus === 'paid' || order.paymentStatus === 'codCollected';
      tx.update(ref, {
        status: 'returned',
        paymentStatus: order.paymentStatus === 'paid' ? 'refundPending' : order.paymentStatus,
        returnRequest: { ...order.returnRequest!, status: 'approved' },
        statusHistory: FieldValue.arrayUnion({ status: 'returned', at: Timestamp.now() }),
        updatedAt: FieldValue.serverTimestamp(),
      });
      return { refund, userId: order.userId, orderNumber: order.orderNumber, approved: true };
    });

    if (result.approved && result.refund) await refundIfPaid(orderId);
    if (!result.approved) {
      await notifyUser(result.userId, {
        title: 'Return not approved',
        body: `Your return for order ${result.orderNumber} was not approved.${reason ? ` ${reason}` : ''}`,
        type: 'order',
        orderId,
        pref: 'orderUpdates',
      });
    }
    return { ok: true };
  },
);

/** Retries a refund that failed earlier (order stays "refundPending"). */
export const adminRetryRefund = onCall(
  { secrets: [RAZORPAY_KEY_ID, RAZORPAY_KEY_SECRET] },
  async (req) => {
    const uid = requireAuth(req);
    await requireAdmin(uid);
    const orderId = str(req.data?.orderId, 'order', 100);
    await refundIfPaid(orderId);
    const after = (await ordersCol().doc(orderId).get()).data() as OrderDoc | undefined;
    if (after?.paymentStatus !== 'refunded') {
      return fail('failed-precondition', 'The refund did not go through. Check the Razorpay dashboard.');
    }
    return { ok: true };
  },
);

/** Role and block changes are server-side so clients can't self-promote. */
export const adminSetUserFlags = onCall(async (req) => {
  const uid = requireAuth(req);
  await requireAdmin(uid);
  const targetId = str(req.data?.userId, 'user', 100);
  if (targetId === uid) fail('failed-precondition', 'You cannot change your own role or access.');

  const patch: Record<string, unknown> = {};
  if (typeof req.data?.blocked === 'boolean') patch.blocked = req.data.blocked;
  if (typeof req.data?.role === 'string') {
    if (req.data.role !== 'customer' && req.data.role !== 'admin') {
      fail('invalid-argument', 'Invalid role.');
    }
    patch.role = req.data.role;
  }
  if (Object.keys(patch).length === 0) fail('invalid-argument', 'Nothing to update.');

  const ref = db.collection(COL.users).doc(targetId);
  if (!(await ref.get()).exists) fail('not-found', 'User not found.');
  await ref.update(patch);
  return { ok: true };
});
