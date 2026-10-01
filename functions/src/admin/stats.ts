import { FieldValue, Timestamp } from 'firebase-admin/firestore';
import { onDocumentUpdated, onDocumentCreated } from 'firebase-functions/v2/firestore';
import { db, COL } from '../config';
import type { OrderDoc } from '../lib/types';

/** YYYY-MM-DD in IST, the business day used across the dashboard. */
function istDay(d: Date): string {
  return new Date(d.getTime() + 5.5 * 3600 * 1000).toISOString().slice(0, 10);
}

/**
 * Keeps dailyStats/{YYYY-MM-DD} up to date so the dashboard reads a handful
 * of small documents instead of scanning every order.
 */
async function record(order: OrderDoc, sign: 1 | -1) {
  const day = istDay((order.createdAt ?? Timestamp.now()).toDate());
  const perProduct: Record<string, FirebaseFirestore.FieldValue> = {};
  for (const item of order.items) {
    perProduct[`productUnits.${item.productId}`] = FieldValue.increment(sign * item.quantity);
  }
  await db.collection(COL.dailyStats).doc(day).set(
    {
      day,
      revenue: FieldValue.increment(sign * order.pricing.grandTotal),
      orders: FieldValue.increment(sign),
      items: FieldValue.increment(sign * order.pricing.itemCount),
      ...perProduct,
      updatedAt: FieldValue.serverTimestamp(),
    },
    { merge: true },
  );
}

/** Counts when an order is confirmed, and backs it out if it's cancelled. */
export const statsOnOrderCreated = onDocumentCreated('orders/{orderId}', async (event) => {
  const order = event.data?.data() as OrderDoc | undefined;
  if (order?.status === 'placed') await record(order, 1);
});

export const statsOnOrderUpdated = onDocumentUpdated('orders/{orderId}', async (event) => {
  const before = event.data?.before.data() as OrderDoc | undefined;
  const after = event.data?.after.data() as OrderDoc | undefined;
  if (!before || !after || before.status === after.status) return;

  const counted = (s: string) => s !== 'pendingPayment' && s !== 'cancelled' && s !== 'returned';
  if (!counted(before.status) && counted(after.status)) await record(after, 1);
  else if (counted(before.status) && !counted(after.status)) await record(after, -1);
});
