import { FieldValue } from 'firebase-admin/firestore';
import { onCall } from 'firebase-functions/v2/https';
import { db, COL } from '../config';
import { fail, optStr, requireActiveUser, requireAuth, str } from '../lib/errors';
import { round2 } from '../lib/pricing';
import type { OrderDoc, ProductDoc } from '../lib/types';

/**
 * Verified-purchase review. One review per user per product (editing
 * replaces it). Keeps the product's average rating up to date.
 */
export const submitReview = onCall(async (req) => {
  const uid = requireAuth(req);
  const user = await requireActiveUser(uid);
  const orderId = str(req.data?.orderId, 'order', 100);
  const productId = str(req.data?.productId, 'product', 100);
  const rating = Number(req.data?.rating);
  if (!Number.isInteger(rating) || rating < 1 || rating > 5) fail('invalid-argument', 'Choose 1 to 5 stars.');
  const comment = optStr(req.data?.comment, 1000);
  const imageUrls = Array.isArray(req.data?.imageUrls) ? (req.data.imageUrls as unknown[]) : [];
  if (imageUrls.length > 3 || imageUrls.some((u) => typeof u !== 'string' || !u.startsWith('https://'))) {
    fail('invalid-argument', 'Attach up to 3 photos.');
  }

  const orderRef = db.collection(COL.orders).doc(orderId);
  const productRef = db.collection(COL.products).doc(productId);
  const reviewRef = db.collection(COL.reviews).doc(`${productId}_${uid}`);

  await db.runTransaction(async (tx) => {
    const [orderSnap, productSnap, reviewSnap] = await tx.getAll(orderRef, productRef, reviewRef);
    const order = orderSnap.data() as OrderDoc | undefined;
    if (!order || order.userId !== uid) fail('not-found', 'Order not found.');
    if (!['delivered', 'returnRequested', 'returned'].includes(order!.status)) {
      fail('failed-precondition', 'You can review items after they are delivered.');
    }
    if (!order!.items.some((i) => i.productId === productId)) {
      fail('failed-precondition', 'This product is not part of this order.');
    }
    const product = productSnap.data() as ProductDoc | undefined;
    if (!product) fail('not-found', 'This product is no longer available.');

    const count = product!.ratingCount ?? 0;
    const avg = product!.ratingAvg ?? 0;
    const old = reviewSnap.exists ? (reviewSnap.data()!.rating as number) : null;
    const newCount = old === null ? count + 1 : count;
    const total = avg * count - (old ?? 0) + rating;
    const newAvg = newCount === 0 ? 0 : round2(total / newCount);

    tx.set(reviewRef, {
      productId,
      userId: uid,
      userName: (user.fullName as string | undefined)?.split(' ')[0] || 'Customer',
      rating,
      comment,
      imageUrls,
      orderId,
      createdAt: FieldValue.serverTimestamp(),
    });
    tx.update(productRef, { ratingAvg: newAvg, ratingCount: newCount });
    tx.update(orderRef, {
      items: order!.items.map((i) => (i.productId === productId ? { ...i, reviewed: true } : i)),
    });
  });
  return { ok: true };
});
