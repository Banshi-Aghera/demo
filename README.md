# SocietyCart

Flutter e-commerce app for Indian apartment societies, with a customer app
(Android, iOS) and an admin panel (Web and mobile). Features: normal shopping,
plus **Neighbour Drop**, **Neighbour Lending** and **Group Buy**.

**Current status: Phases 1–4 of 7 done** (auth and roles; catalog, search, cart, wishlist; checkout, Razorpay + COD, orders, returns, GST invoices, push notifications, verified reviews; full admin panel).

Remaining: Neighbour Drop (Phase 5), Lending (Phase 6), Group Buy (Phase 7).

---

## 1. Prerequisites

- Flutter (latest stable, Dart 3.8 or newer): `flutter --version`
- Node.js 20+ (for Firebase CLI now, Cloud Functions from Phase 5)
- Firebase CLI: `npm install -g firebase-tools`, then `firebase login`
- FlutterFire CLI: `dart pub global activate flutterfire_cli`
- Android Studio / Xcode for device builds

## 2. Generate the platform folders

This repo contains `lib/` and config only. Create the Android, iOS and Web
folders (existing files are not overwritten):

```bash
cd societycart
flutter create . --org com.societycart --project-name societycart --platforms android,ios,web
```

Then:

- **Android:** in `android/app/build.gradle.kts` (or `build.gradle`) set `minSdk = 23`.
- **iOS:** in `ios/Podfile` set `platform :ios, '13.0'` (or higher).

## 3. Create the Firebase project

1. Go to https://console.firebase.google.com and create a project (e.g. `societycart-dev`).
2. **Authentication > Sign-in method**, enable:
   - Email/Password
   - Phone (add a test number such as `+91 9999999999` with code `123456` for development, so you don't spend SMS credits)
   - Google
3. **Firestore Database**: create a database (region `asia-south1` (Mumbai) is closest to Indian users). Start in production mode; the rules in this repo are deployed below.
4. Upgrade to the **Blaze** plan before Phase 5 (Cloud Functions need it). Phone OTP is also billed per SMS beyond the free quota.

## 4. Connect the app to Firebase

```bash
flutterfire configure --project=<your-project-id> --platforms=android,ios,web
```

This creates `lib/firebase_options.dart`, `android/app/google-services.json`
and `ios/Runner/GoogleService-Info.plist`.

**Google sign-in extra steps**

- **Android:** add your debug SHA-1 and SHA-256 in Firebase console > Project settings > Your Android app, then run `flutterfire configure` again.
  Get them with `cd android && ./gradlew signingReport`.
- **iOS:** open `ios/Runner/GoogleService-Info.plist`, copy `REVERSED_CLIENT_ID`, and add it as a URL scheme in Xcode (Runner > Info > URL Types). Also add a `GIDClientID` key in `Info.plist` with the value of `CLIENT_ID`.
- **Web:** add `localhost` to Authentication > Settings > Authorized domains (usually there by default).

**Phone OTP on Android:** the SHA keys above are also required for Play Integrity / reCAPTCHA verification.

## 5. Install packages and generate code

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
```

Run `build_runner` again whenever you change a model (`@freezed`) or a provider (`@riverpod`).
During development, `dart run build_runner watch -d` regenerates automatically.

If `pub get` reports a version conflict between the code generators, run
`flutter pub upgrade --major-versions` and then `build_runner` again.

## 6. Deploy Firestore rules

```bash
firebase use <your-project-id>
firebase deploy --only firestore:rules,firestore:indexes
```

## 7. Run

```bash
# Customer app on a phone or emulator
flutter run

# Admin panel in Chrome
flutter run -d chrome
```

Both are the same app; the router sends admins to the admin panel and customers to Home.

## 8. Seed sample data

1. Firebase console > Project settings > Service accounts > **Generate new private key**.
2. Save the file as `tool/seed/service-account.json` (git-ignored; never commit it).
3. Run:

```bash
cd tool/seed
npm install
npm run seed
```

This creates 6 categories, 30 products (some with variants, some low or out of
stock), 3 banners, sample reviews, delivery pricing, and coupons:
`WELCOME10` (10% off, min ₹299, max ₹150), `FLAT50` (₹50 off, min ₹499), and
`OLD20` (expired, to test errors). Product photos are random placeholders until
you upload real ones from the admin panel (Phase 4).

Also deploy the indexes (`firebase deploy --only firestore:indexes`). Index
builds take a few minutes; until then "Popular now" and reviews stay empty.

## 9. Make yourself an admin (until the Phase 7 seed script exists)

1. Register a normal account in the app.
2. Firebase console > Firestore > `users` > your document > change `role` from `customer` to `admin`.
3. Log out and log in again (or just wait a second; the router reacts live).

Users can never change their own role: the security rules block it.

## 10. Add a test society (until the Phase 5 admin screen exists)

Firestore > `societies` > Add document (auto-ID) with fields:

| field | type | example |
|---|---|---|
| name | string | Green Park Residency |
| nameLower | string | green park residency |
| address | string | 150 Ft Ring Road |
| city | string | Ahmedabad |
| code | string | GREENPARK01 |
| securityDeskIsDefaultReceiver | boolean | false |

To approve a membership request manually, open `societyMemberships/<uid>` and set `status` to `approved`.

## 11. Phase 3 setup: payments, Cloud Functions, notifications

### 11.1 Firebase plan and services
- Upgrade the project to the **Blaze** plan (Cloud Functions need it; there's a generous free tier).
- Enable **Storage** (Build > Storage > Get started, region `asia-south1`).
- Enable **Cloud Messaging** (on by default).

### 11.2 Razorpay test keys
1. Sign up at https://dashboard.razorpay.com and stay in **Test mode**.
2. Account & Settings > API keys > Generate test key. You get a Key ID (`rzp_test_...`) and a Key Secret.
3. Store them as Cloud Functions secrets (they never go into the app):

```bash
firebase functions:secrets:set RAZORPAY_KEY_ID
firebase functions:secrets:set RAZORPAY_KEY_SECRET
firebase functions:secrets:set RAZORPAY_WEBHOOK_SECRET   # any long random string
```

### 11.3 Deploy the backend
```bash
cd functions && npm install && cd ..
firebase deploy --only functions,firestore:rules,firestore:indexes,storage
```

After deploy, copy the URL of `razorpayWebhook` from the output. In Razorpay:
Settings > Webhooks > Add: that URL, event **payment.captured**, secret = the
`RAZORPAY_WEBHOOK_SECRET` you set. The webhook confirms payments even if the
app closes right after paying.

Re-run the seed script once (`cd tool/seed && npm run seed`) to add the
seller details used on GST invoices (`appSettings/business`). **Replace the
sample business name and GSTIN with your own before going live.**

### 11.4 Android
- `android/app/build.gradle.kts`: `minSdk = 23` (already required).
- For release builds, add to `android/app/proguard-rules.pro`:
  ```
  -keepattributes *Annotation*
  -dontwarn com.razorpay.**
  -keep class com.razorpay.** {*;}
  -optimizations !method/inlining/
  -keepclasseswithmembers class * { public void onPayment*(...); }
  ```

### 11.5 iOS
- In Xcode, Runner > Signing & Capabilities: add **Push Notifications** and **Background Modes > Remote notifications**.
- Upload an APNs key: Apple Developer > Keys > create a key with APNs, then Firebase console > Project settings > Cloud Messaging > Apple app configuration.
- `ios/Runner/Info.plist`: add `NSPhotoLibraryUsageDescription` ("Attach photos to returns and reviews") and `NSCameraUsageDescription`.

### 11.6 How the money flow works
1. **Checkout** calls `createOrder`. The server reads the cart and re-prices
   everything from Firestore (prices, variants, stock, coupon, delivery fee,
   COD limit), reserves stock, assigns an order number (`SC000001`) and a GST
   invoice number in a per-financial-year series (`SC/26-27/00001`).
2. **COD**: the order is placed immediately and the cart is cleared.
3. **Razorpay**: the server creates a Razorpay order; the app opens checkout;
   on success `verifyPayment` checks the HMAC signature and marks it paid.
   The webhook is a backup. Unpaid orders release their stock after 30
   minutes (`releaseUnpaidOrders`, every 15 minutes).
4. **Cancel** (until shipped) puts stock back and refunds online payments in full via the Razorpay API.
5. **Status changes** (from the admin panel in Phase 4, or by editing
   `status` in the Firestore console now) trigger `onOrderUpdated`, which
   adds the timeline entry, stamps the delivery time, marks COD as collected,
   and sends a push + in-app notification.

Order status values: `pendingPayment`, `placed`, `packed`, `shipped`,
`outForDelivery`, `delivered`, `cancelled`, `returnRequested`, `returned`.

### 11.7 Known limits (by design, for now)
- A cancelled-after-invoicing order would need a GST credit note; that's outside the app's scope.
- Coupon usage is limited globally (`usageLimit`), not per customer yet.
- Return approval and refunds of returns are handled in the admin panel (Phase 4).

---

## Project structure

```
lib/
  core/          constants (strings!), theme, router, utils, widgets, providers, error
  features/
    auth/        splash, onboarding, login, register, OTP, Google, forgot password
    society/     join society, membership, My Society tab
    home/        customer shell (bottom nav) + home tab
    catalog/     categories, product list, filters, search, product page, reviews
    cart/        cart, coupons, price breakdown (GST-inclusive)
    wishlist/    saved products
    checkout/    checkout, Razorpay service, payment flow, success screen
    orders/      orders list, detail + timeline, returns, reviews, GST invoice PDF
    notifications/ in-app list, settings (push handled in core/services)
    profile/     profile, addresses
    admin/       dashboard, products, categories/banners, orders, users, societies, coupons, settings, reports
functions/       Cloud Functions (TypeScript): orders, payments, refunds, notifications, reviews
tool/seed/       Node seed script (firebase-admin)
```

**Pricing model:** prices are GST-inclusive (standard in Indian retail). The
cart shows the GST component inside the total. Delivery is free above the
`appSettings/pricing.freeDeliveryAbove` amount. Cart prices are a snapshot; in
Phase 3 a Cloud Function re-prices the order on the server before payment, so
a tampered client can't change what it pays.

**Search:** Firestore has no full-text search, so products store prefix
`searchKeywords`. Good for a few thousand products; for typo tolerance at
scale, move to Algolia or Typesense.

All user-facing text is in `lib/core/constants/app_strings.dart`, ready for Hindi and Gujarati later.

## Firestore collections used so far

- `users/{uid}`: fullName, email, phone, role (`customer` | `admin`), blocked, photoUrl, createdAt
- `societies/{id}`: name, nameLower, address, city, code, securityDeskIsDefaultReceiver
- `societyMemberships/{uid}`: userId, societyId, societyName, wing, flatNumber, status (`pending` | `approved` | `rejected`), createdAt, reviewedAt
- `categories/{id}`: name, imageUrl, sortOrder, active
- `banners/{id}`: imageUrl, title, subtitle, targetCategoryId?, targetProductId?, sortOrder, active
- `products/{id}`: name, nameLower, description, brand, categoryId, images[], price, mrp, stock, gstRate, variantLabel, variants[{id, label, price, mrp, stock}], ratingAvg, ratingCount, soldCount, isDealOfDay, active, searchKeywords[], createdAt
- `reviews/{id}`: productId, userId, userName, rating, comment, imageUrls[], createdAt
- `carts/{uid}/items/{productId[__variantId]}`: product snapshot, unitPrice, mrp, gstRate, quantity, maxStock, addedAt
- `wishlists/{uid}/items/{productId}`: productId, addedAt
- `coupons/{CODE}`: code, type (`percent` | `flat`), value, minOrder, maxDiscount, expiresAt, usageLimit, usedCount, active
- `appSettings/pricing`: deliveryFee, freeDeliveryAbove, codMaxAmount
- `appSettings/business`: seller legalName, gstin, address, state, stateCode (for invoices)
- `users/{uid}/addresses/{id}`: label, fullName, phone, line1, line2, landmark, city, state, stateCode, pincode, isDefault
- `users/{uid}/fcmTokens/{token}`: platform, updatedAt
- `orders/{id}` (server-written): orderNumber, invoiceNumber, userId, items[] with taxableValue/taxAmount, address snapshot, paymentMethod, paymentStatus, status, statusHistory[], pricing, taxType (`intra` → CGST+SGST, `inter` → IGST), seller snapshot, razorpay ids, returnRequest, deliveredAt
- `notifications/{id}` (server-written): userId, title, body, type, orderId, read, createdAt
- `counters/{orders | invoice-YY-YY}`: seq (server only)
- `dailyStats/{YYYY-MM-DD}` (server-written): revenue, orders, items, productUnits map — powers the dashboard
- `appSettings/rewards`: pointsPerParcel, pointsPerRupee, lendingFeePercent, minOrdersPerSlot

---

## Phase 1 test checklist (auth)

**First launch**
- [ ] Splash animates, then onboarding appears with 3 swipeable slides.
- [ ] "Skip" and "Get started" both lead to Login. Restart the app: onboarding does not show again.

**Register**
- [ ] Each field shows its error live: bad email, 9-digit phone, phone starting with 1-5, password without a number, password under 8 characters, mismatched confirm.
- [ ] Registering with an email that already exists shows "An account already exists…".
- [ ] A successful sign-up lands on **Join your society**.

**Join your society**
- [ ] Search finds your test society after 2+ letters; code search works in any letter case.
- [ ] A wrong code shows a clear error.
- [ ] Sending a request shows a confirmation and goes to Home; Profile shows "Pending approval".
- [ ] "Skip for now" goes to Home and My Society shows the locked state.
- [ ] Approving in Firestore unlocks My Society live (3 tabs appear) without restarting.

**Login**
- [ ] Wrong password shows "Email or password is incorrect."
- [ ] Turn on airplane mode: the offline banner appears; a login attempt shows the no-internet message.
- [ ] Only the tapped button shows a spinner; other buttons are disabled while it runs.
- [ ] Forgot password sends the email, and the link works.
- [ ] OTP with the Firebase test number + code logs in; Resend unlocks after 30 seconds; "Change number" goes back.
- [ ] Google sign-in works on Android, iOS and Web; cancelling the Google sheet shows no error.

**Roles**
- [ ] A customer goes to Home. Typing `/admin` in the browser URL bounces back to Home.
- [ ] An admin goes to the admin panel: side nav on a wide window, drawer below 1000 px wide.
- [ ] Setting `blocked: true` on a user in Firestore logs them out with a message and blocks future logins.

**Theme**
- [ ] Switch the device to dark mode: every screen stays readable.

## Phase 2 test checklist (catalog, cart, wishlist)

**Home**
- [ ] Banners auto-scroll every 5 seconds; tapping one opens its category.
- [ ] Category chips, Deals of the day, Popular now all show seeded products.
- [ ] Open 2-3 products, come back: "Recently viewed" shows them, newest first.
- [ ] Pull down to refresh works.

**Catalog**
- [ ] Categories tab shows 6 tiles; each opens a product grid.
- [ ] Sort by price low-high / high-low / newest / popular reorders the grid.
- [ ] Filters: price slider, brand chips, 4★ & up. The badge shows the filter count; "Clear filters" appears when nothing matches.
- [ ] Out-of-stock items ("Sandal Soap") are dimmed and sorted last.

**Search**
- [ ] "rice", "bosch", "pressure" and partial words like "drill" find results.
- [ ] Two words ("steel bottle") narrow the results; nonsense shows "No results".

**Product page**
- [ ] The image animates (Hero) from the card into the gallery; swipe through 3 photos; tap to open full screen and pinch to zoom.
- [ ] Price, struck-through MRP and % off are shown; stock says "In stock", "Only 4 left" (Kesar Mango) or "Out of stock".
- [ ] "Pressure Cooker" variants: 7L is disabled (no stock); switching size changes the price.
- [ ] Reviews show on the first 8 products; others say no reviews yet.
- [ ] "You may also like" shows same-category products, not the current one.
- [ ] The quantity stepper stops at the available stock. "Add to cart" turns into "Go to cart".

**Cart**
- [ ] The cart badge on the bottom nav updates live.
- [ ] Change quantity, remove, and move to wishlist all work; the stepper can't exceed stock.
- [ ] Below ₹499 the amber bar says how much more is needed for free delivery; above it, delivery shows FREE.
- [ ] `WELCOME10` applies (max ₹150 off). `OLD20` shows "expired". `NOPE` shows "does not exist". `FLAT50` on a ₹300 cart shows the minimum-order message.
- [ ] Apply `FLAT50`, then reduce the cart below ₹499: the coupon turns red with the reason and stops discounting.
- [ ] The breakdown adds up: MRP total − product discount − coupon + delivery = grand total. "You save" matches the discounts.

**Wishlist**
- [ ] Hearts toggle on cards and the product page, with a snackbar.
- [ ] Wishlist opens from the Home heart icon and Profile.

**Security** (Firebase console > Firestore > Rules playground)
- [ ] A customer can't write to `products`, and can't read another user's `carts/{uid}/items`.
- [ ] Listing `coupons` as a customer is denied; getting `coupons/WELCOME10` is allowed.

## Phase 3 test checklist (checkout, payments, orders)

Use Razorpay **test mode**. Test payments use the test card / UPI details
from Razorpay's test-mode docs (for UPI, `success@razorpay` succeeds and
`failure@razorpay` fails).

**Addresses**
- [ ] Add an address: name and phone prefill from your profile; a 5-digit PIN or no state shows an error.
- [ ] Your first address becomes the default automatically; marking another as default moves the tag.
- [ ] Deleting the default makes another address the default.

**Checkout**
- [ ] Cart > Proceed to checkout shows the default address, Standard delivery, payment options and the same totals as the cart.
- [ ] "Change" picks another address; with no addresses, "Add address" returns straight to checkout.
- [ ] Set `appSettings/pricing.codMaxAmount` to 500: COD is disabled for a bigger cart, with the reason shown.
- [ ] In Firestore, set a product's stock to 1 while 2 are in the cart, then place the order: you get "Only 1 left of …" and nothing is charged.

**Cash on Delivery**
- [ ] Place a COD order: the success animation plays, the order number and "You saved ₹X" show, the cart is empty, and product stock dropped.
- [ ] A push notification "Order placed" arrives (real device) and appears under the Home bell with an unread badge.

**Razorpay**
- [ ] Pay with the success test method: you land on the success screen; the order shows "Paid online".
- [ ] Cancel the Razorpay sheet: the dialog offers Retry or Pay later. "Pay later" opens the order with a "Pay now" button that works.
- [ ] Leave an order unpaid for 30+ minutes: it becomes Cancelled ("Payment was not completed in time") and stock comes back.
- [ ] Coupon `WELCOME10` applied in the cart is charged correctly and its `usedCount` goes up by 1 after payment.

**Orders**
- [ ] My orders lists newest first with status chips.
- [ ] In the Firestore console, change `status` to `packed`, then `shipped`, `outForDelivery`, `delivered`: the timeline fills in with times, and each change sends a notification.
- [ ] Cancel a paid order before it ships: status Cancelled, payment "Refund in progress" then "Refunded" (check the refund in the Razorpay dashboard). Stock is restored.
- [ ] After `shipped`, "Cancel order" is gone.
- [ ] After delivery: "Request return" (reason, comment, up to 3 photos) changes status to Return requested. Not offered after 7 days.
- [ ] "Rate" on a delivered item saves a review that appears on the product page; the product rating updates. Rating again replaces your review instead of adding a second one.

**GST invoice**
- [ ] "Download GST invoice" opens a PDF with seller GSTIN, invoice number `SC/26-27/…`, each item's taxable value and tax, totals and amount in words.
- [ ] Gujarat address (same state as the sample seller) shows CGST + SGST; an address in another state shows IGST.
- [ ] With a coupon, item values are reduced proportionally and the total matches what you paid.

**Notifications**
- [ ] Turn off "Order updates" in Notification settings: status changes still appear in the in-app list but no push arrives.
- [ ] Tapping a push (app closed or in background) opens that order.
- [ ] Logging out removes this device's token, so pushes for that account stop.

**Security** (Rules playground)
- [ ] A customer can't create or update `orders`, can't read another user's order, and can't change `title` on a notification (only `read`).

## Phase 4: the admin panel

Open it by logging in as an admin (`role: admin` on your user doc). On a wide
window you get a side nav; below 1000 px it becomes a drawer. The same build
runs on web and mobile.

After deploying this phase, run `firebase deploy --only functions,firestore:rules,firestore:indexes`
again: it adds the admin functions and the `dailyStats` aggregation.

**Important:** the dashboard chart is built from `dailyStats`, which Cloud
Functions write as orders come in. Orders placed *before* you deploy Phase 4
are not counted. Place a test order after deploying to see the chart move.

### What each section does

- **Dashboard** — today's revenue, orders in the period, pending orders, new users (7 days), a 7/30-day sales line chart, top products by units sold, and low-stock alerts.
- **Products** — search, filter by category and stock level, create and edit products with up to 5 uploaded images, variants (each with its own price, MRP and stock), GST rate, visibility and "Deal of the day". Search keywords are regenerated on every save.
- **Categories & banners** — two tabs. Banners can open a category or a specific product.
- **Orders** — filter by status, search by order number, customer name or phone. The detail screen moves an order forward one step at a time (Placed → Packed → Shipped → Out for delivery → Delivered), approves or rejects returns (approval restocks and refunds), retries a failed refund, and downloads the GST invoice.
- **Users** — search, block or unblock (blocked users are signed out immediately), and grant or remove the admin role. You cannot change your own role or block yourself. Tapping a user shows their recent orders.
- **Societies** — create societies with a unique join code, and approve or reject membership requests. The side nav shows a badge with the number of pending requests.
- **Coupons** — percentage or flat, minimum order, maximum discount, expiry date, usage limit, and the live used count.
- **Settings** — delivery fee, free-delivery threshold, COD limit; reward and lending values (used by Phases 5 and 6); and the business details printed on GST invoices.
- **Reports** — pick a date range and export orders or product sales as CSV. Files are UTF-8 with a BOM so Excel displays ₹ correctly.

### Phase 4 test checklist

**Access**
- [ ] A customer who types `/admin` is sent back to Home; an admin lands in the panel.
- [ ] Resize the browser below 1000 px: the side nav becomes a drawer.

**Dashboard**
- [ ] Place a test order, then refresh: today's revenue and order count go up.
- [ ] Cancel that order: the dashboard numbers go back down.
- [ ] Switch 7 days / 30 days; the chart tooltip shows revenue and order count per day.
- [ ] Set a product's stock to 2: it appears under Low stock.

**Products**
- [ ] Create a product with two images and two variants; it appears in the customer app with the right prices.
- [ ] Set selling price above MRP: the form blocks it.
- [ ] Rename a product, then search the new name in the customer app — the keywords updated.
- [ ] Turn off "Visible in the store": it disappears from the customer catalog.

**Orders**
- [ ] Move an order through every status; the customer sees each step and gets a notification.
- [ ] Try to skip a step (e.g. Placed straight to Delivered) using an old screen: the server rejects it.
- [ ] Approve a return: stock comes back, the payment moves to Refunded, and the customer is notified.
- [ ] Reject a return with a reason: the order goes back to Delivered and the customer sees the reason.

**Users**
- [ ] Block a logged-in customer: they're signed out within seconds and can't log back in.
- [ ] Try to change your own role: blocked with a clear message.
- [ ] Promote a customer to admin; they reach the panel on next login.

**Societies & coupons**
- [ ] Create a society, then join it from the customer app by code; approve the request and My Society unlocks live.
- [ ] Create a coupon and use it at checkout; the used count goes up by 1.
- [ ] A duplicate society code or coupon code format error is blocked.

**Settings & reports**
- [ ] Change the delivery fee and free-delivery threshold; the customer cart updates immediately.
- [ ] Enter an invalid GSTIN: the form blocks it. Save valid business details and check they appear on a new invoice.
- [ ] Export orders CSV for the last 30 days and open it in Excel: ₹ and all columns look right.
