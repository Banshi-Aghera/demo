import { Timestamp } from 'firebase-admin/firestore';
import { onSchedule } from 'firebase-functions/v2/scheduler';
import { logger } from 'firebase-functions';
import { PAYMENT_TIMEOUT_MINUTES } from '../config';
import { cancelAndRestock, ordersCol } from './orderOps';

/**
 * Releases stock held by Razorpay orders that were never paid.
 * Needs the composite index (status ASC, createdAt ASC).
 */
export const releaseUnpaidOrders = onSchedule(
  { schedule: 'every 15 minutes', timeZone: 'Asia/Kolkata' },
  async () => {
    const cutoff = Timestamp.fromMillis(Date.now() - PAYMENT_TIMEOUT_MINUTES * 60_000);
    const stale = await ordersCol()
      .where('status', '==', 'pendingPayment')
      .where('createdAt', '<', cutoff)
      .limit(200)
      .get();
    let released = 0;
    for (const doc of stale.docs) {
      const before = await cancelAndRestock(doc.id, 'Payment was not completed in time', ['pendingPayment']);
      if (before) released++;
    }
    logger.info('Released unpaid orders', { released });
  },
);
