import { FieldValue, Timestamp } from 'firebase-admin/firestore';
import { onDocumentCreated, onDocumentUpdated } from 'firebase-functions/v2/firestore';
import { notifyUser, orderStatusMessage } from '../lib/notify';
import type { OrderDoc } from '../lib/types';

/** COD orders are created already "placed". */
export const onOrderCreated = onDocumentCreated('orders/{orderId}', async (event) => {
  const order = event.data?.data() as OrderDoc | undefined;
  if (!order || order.status !== 'placed') return;
  const msg = orderStatusMessage('placed', order.orderNumber)!;
  await notifyUser(order.userId, { ...msg, type: 'order', orderId: event.params.orderId, pref: 'orderUpdates' });
});

/**
 * Runs on every status change, including edits made in the Firebase console
 * or the admin panel: keeps the timeline complete, stamps delivery time,
 * marks COD as collected, and notifies the customer.
 */
export const onOrderUpdated = onDocumentUpdated('orders/{orderId}', async (event) => {
  const before = event.data?.before.data() as OrderDoc | undefined;
  const after = event.data?.after.data() as OrderDoc | undefined;
  if (!before || !after || before.status === after.status) return;

  const patch: Record<string, unknown> = {};
  const last = after.statusHistory?.[after.statusHistory.length - 1];
  if (last?.status !== after.status) {
    patch.statusHistory = FieldValue.arrayUnion({ status: after.status, at: Timestamp.now() });
  }
  if (after.status === 'delivered') {
    if (!after.deliveredAt) patch.deliveredAt = Timestamp.now();
    if (after.paymentMethod === 'cod' && after.paymentStatus === 'codPending') {
      patch.paymentStatus = 'codCollected';
    }
  }
  if (Object.keys(patch).length > 0) {
    patch.updatedAt = FieldValue.serverTimestamp();
    await event.data!.after.ref.update(patch);
  }

  // pendingPayment -> placed is the "order placed" moment for online payments.
  const msg = orderStatusMessage(after.status, after.orderNumber);
  if (msg) {
    await notifyUser(after.userId, { ...msg, type: 'order', orderId: event.params.orderId, pref: 'orderUpdates' });
  }
});
