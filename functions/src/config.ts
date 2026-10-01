import { initializeApp } from 'firebase-admin/app';
import { getFirestore } from 'firebase-admin/firestore';
import { setGlobalOptions } from 'firebase-functions/v2';
import { defineSecret } from 'firebase-functions/params';

initializeApp();

// Mumbai region: closest to Indian users. The Flutter app calls this region.
setGlobalOptions({ region: 'asia-south1', maxInstances: 10 });

export const db = getFirestore();

// Set with: firebase functions:secrets:set RAZORPAY_KEY_ID  (etc.)
export const RAZORPAY_KEY_ID = defineSecret('RAZORPAY_KEY_ID');
export const RAZORPAY_KEY_SECRET = defineSecret('RAZORPAY_KEY_SECRET');
export const RAZORPAY_WEBHOOK_SECRET = defineSecret('RAZORPAY_WEBHOOK_SECRET');

export const PAYMENT_TIMEOUT_MINUTES = 30;
export const RETURN_WINDOW_DAYS = 7;
export const MAX_RETURN_PHOTOS = 3;

export const COL = {
  users: 'users',
  addresses: 'addresses',
  fcmTokens: 'fcmTokens',
  products: 'products',
  carts: 'carts',
  items: 'items',
  coupons: 'coupons',
  orders: 'orders',
  reviews: 'reviews',
  appSettings: 'appSettings',
  counters: 'counters',
  notifications: 'notifications',
  dailyStats: 'dailyStats',
} as const;
