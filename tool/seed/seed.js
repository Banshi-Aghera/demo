// SocietyCart seed script.
// Phases 2-3 seed the catalog (6 categories, 30 products, banners, coupons,
// reviews) plus pricing and seller (GST invoice) settings. Phase 7 extends this with users,
// societies, delivery slots, lending listings and group deals.
//
// Usage:
//   1. Firebase console > Project settings > Service accounts >
//      "Generate new private key". Save it as tool/seed/service-account.json
//      (it is git-ignored; never commit it).
//   2. cd tool/seed && npm install && npm run seed
//
// Safe to re-run: documents use fixed ids and are overwritten.

import { readFileSync } from 'node:fs';
import admin from 'firebase-admin';

const serviceAccount = JSON.parse(
  readFileSync(new URL('./service-account.json', import.meta.url), 'utf8'),
);
admin.initializeApp({ credential: admin.credential.cert(serviceAccount) });
const db = admin.firestore();
const now = admin.firestore.Timestamp.now();

// Placeholder photos (random per product). Replace with real product
// photos from the admin panel in Phase 4.
const img = (seed, n = 0) =>
  `https://picsum.photos/seed/sc-${seed}-${n}/800/800`;

// Same algorithm as CatalogRepository.buildKeywords in the app.
function keywords(name, brand) {
  const out = new Set();
  for (const word of `${name} ${brand}`.toLowerCase().split(/[^a-z0-9]+/)) {
    for (let i = 1; i <= word.length; i++) out.add(word.slice(0, i));
  }
  return [...out];
}

const categories = [
  { id: 'groceries', name: 'Groceries & Staples', sortOrder: 1 },
  { id: 'fruits-veg', name: 'Fruits & Vegetables', sortOrder: 2 },
  { id: 'home-cleaning', name: 'Home & Cleaning', sortOrder: 3 },
  { id: 'kitchen', name: 'Kitchen & Appliances', sortOrder: 4 },
  { id: 'tools', name: 'Tools & DIY', sortOrder: 5 },
  { id: 'personal-care', name: 'Personal Care', sortOrder: 6 },
];

// [id, name, brand, categoryId, price, mrp, stock, gstRate, soldCount,
//  rating, ratingCount, isDealOfDay, description, variants?]
const products = [
  ['basmati-rice-5kg', 'Premium Basmati Rice', 'India Gate', 'groceries', 649, 799, 120, 5, 540, 4.5, 210, true,
    'Long-grain aged basmati rice. Fluffy, aromatic grains that stay separate after cooking. Ideal for biryani and pulao.',
    { label: 'Pack size', items: [['1kg', 1 , 149, 175, 60], ['5kg', 5, 649, 799, 60]] }],
  ['toor-dal-1kg', 'Unpolished Toor Dal 1 kg', 'Tata Sampann', 'groceries', 179, 210, 200, 5, 820, 4.4, 340, false,
    'Unpolished arhar dal with natural protein intact. Cooks soft and creamy for everyday dal.'],
  ['groundnut-oil-1l', 'Cold Pressed Groundnut Oil 1 L', 'Saffola', 'groceries', 239, 280, 90, 5, 410, 4.2, 120, false,
    'Cold pressed groundnut oil from Saurashtra peanuts. Light taste, good for deep frying and theplas.'],
  ['atta-10kg', 'Whole Wheat Atta 10 kg', 'Aashirvaad', 'groceries', 489, 560, 75, 5, 930, 4.6, 610, true,
    'Chakki-ground whole wheat atta for soft rotis. Made from carefully selected grains.'],
  ['sugar-5kg', 'Refined Sugar 5 kg', 'Madhur', 'groceries', 249, 275, 150, 5, 300, 4.1, 80, false,
    'Pure sulphur-free refined sugar crystals.'],
  ['tea-500g', 'Masala Tea 500 g', 'Wagh Bakri', 'groceries', 265, 300, 140, 5, 760, 4.7, 450, false,
    'Strong Gujarati-style tea blended with cardamom and ginger notes. Brews a rich, full-bodied cup.'],

  ['bananas-dozen', 'Robusta Bananas (12 pcs)', 'Fresh', 'fruits-veg', 59, 70, 60, 0, 1200, 4.3, 300, false,
    'Ripe, naturally sweet bananas sourced from local farms every morning.'],
  ['onion-2kg', 'Onion 2 kg', 'Fresh', 'fruits-veg', 79, 100, 80, 0, 1500, 4.0, 220, true,
    'Medium-sized red onions, sorted and cleaned.'],
  ['tomato-1kg', 'Tomato 1 kg', 'Fresh', 'fruits-veg', 39, 50, 70, 0, 1100, 3.9, 180, false,
    'Firm, juicy tomatoes for curries and salads.'],
  ['kesar-mango-1kg', 'Kesar Mango 1 kg', 'Gir Orchards', 'fruits-veg', 189, 240, 4, 0, 280, 4.8, 95, false,
    'Seasonal Kesar mangoes from the Gir region of Gujarat. Sweet, fragrant and fibre-free.'],
  ['potato-2kg', 'Potato 2 kg', 'Fresh', 'fruits-veg', 69, 80, 90, 0, 980, 4.1, 150, false,
    'Clean, all-purpose potatoes.'],

  ['floor-cleaner-2l', 'Disinfectant Floor Cleaner 2 L', 'Lizol', 'home-cleaning', 379, 449, 60, 18, 650, 4.5, 390, true,
    'Kills 99.9% of germs. Citrus fragrance that lasts.'],
  ['detergent-4kg', 'Matic Detergent Powder 4 kg', 'Surf Excel', 'home-cleaning', 799, 935, 40, 18, 520, 4.4, 280, false,
    'Designed for front and top load washing machines. Removes tough stains in one wash.'],
  ['dishwash-gel-1l', 'Dishwash Gel 1 L', 'Vim', 'home-cleaning', 199, 230, 100, 18, 700, 4.3, 260, false,
    'Lemon-powered gel that cuts grease. A little goes a long way.'],
  ['garbage-bags', 'Garbage Bags Medium (90 pcs)', 'Clean Home', 'home-cleaning', 149, 199, 3, 18, 330, 4.0, 70, false,
    'Leak-proof, biodegradable garbage bags. 19 x 21 inches.'],
  ['mop-set', 'Spin Mop with Bucket', 'Gala', 'home-cleaning', 1299, 1999, 25, 18, 210, 4.2, 140, false,
    '360-degree spin mop with steel wringer and two microfibre refills.'],

  ['mixer-grinder', 'Mixer Grinder 750 W, 3 Jars', 'Bajaj', 'kitchen', 3299, 4499, 15, 18, 160, 4.4, 230, true,
    'Powerful 750 W motor with 3 stainless steel jars for wet and dry grinding, and chutneys.'],
  ['pressure-cooker', 'Aluminium Pressure Cooker', 'Prestige', 'kitchen', 1599, 1999, 30, 12, 240, 4.6, 410, false,
    'Induction base pressure cooker with gasket release system.',
    { label: 'Capacity', items: [['3L', 3, 1599, 1999, 15], ['5L', 5, 1999, 2499, 10], ['7L', 7, 2399, 2999, 0]] }],
  ['nonstick-tawa', 'Non-stick Dosa Tawa 28 cm', 'Hawkins', 'kitchen', 899, 1250, 35, 18, 190, 4.3, 120, false,
    'Triple-layer non-stick coating, works on gas and induction.'],
  ['air-fryer', 'Digital Air Fryer 4.2 L', 'Philips', 'kitchen', 6999, 9995, 8, 18, 95, 4.5, 160, false,
    'Fry, bake, grill and roast with up to 90% less fat. Rarely needed every day; a good one to borrow from a neighbour first.'],
  ['water-bottle-set', 'Steel Water Bottles (Set of 3)', 'Milton', 'kitchen', 749, 999, 50, 18, 260, 4.2, 90, false,
    'Leak-proof stainless steel bottles, 1 L each.'],

  ['drill-machine', 'Impact Drill Machine 13 mm', 'Bosch', 'tools', 2899, 3999, 12, 18, 70, 4.6, 210, true,
    '600 W impact drill with variable speed. Drills into wall, wood and metal. Most homes use a drill only a few times a year.'],
  ['ladder-6step', 'Aluminium Ladder 6 Steps', 'Bathla', 'tools', 3499, 4999, 10, 18, 55, 4.5, 85, false,
    'Foldable 6-step ladder with wide anti-slip steps and safety lock.'],
  ['toolkit-108', 'Home Tool Kit (108 pcs)', 'Stanley', 'tools', 1999, 2799, 20, 18, 90, 4.3, 60, false,
    'Screwdrivers, sockets, pliers and more in a sturdy case.'],
  ['glue-gun', 'Hot Glue Gun with 10 Sticks', 'Pidilite', 'tools', 399, 549, 45, 18, 140, 4.0, 45, false,
    '40 W glue gun for crafts and quick home repairs.'],
  ['pressure-washer', 'Pressure Washer 1500 W', 'Karcher', 'tools', 8999, 11999, 6, 18, 30, 4.4, 40, false,
    'Cleans cars, balconies and parking areas. Great to share within a building.'],

  ['shampoo-650ml', 'Anti-Dandruff Shampoo 650 ml', 'Head & Shoulders', 'personal-care', 549, 699, 70, 18, 480, 4.3, 300, false,
    'Clinically proven anti-dandruff formula for clean, flake-free hair.'],
  ['toothpaste-pack', 'Toothpaste 150 g (Pack of 3)', 'Colgate', 'personal-care', 279, 330, 110, 18, 900, 4.5, 520, true,
    'Strong teeth and fresh breath with calcium boost.'],
  ['soap-pack', 'Sandal Soap 125 g (Pack of 4)', 'Mysore Sandal', 'personal-care', 259, 300, 0, 18, 600, 4.6, 380, false,
    'Pure sandalwood oil soap with a classic fragrance.'],
  ['face-wash', 'Neem Face Wash 150 ml', 'Himalaya', 'personal-care', 179, 215, 95, 18, 710, 4.4, 410, false,
    'Purifying neem and turmeric face wash for clear skin.',
    { label: 'Size', items: [['100ml', 100, 129, 155, 50], ['150ml', 150, 179, 215, 45]] }],
];

const banners = [
  { id: 'b1', title: 'Free delivery with Neighbour Drop', subtitle: 'Join your building\'s slot and save on every order',
    imageUrl: img('banner-drop'), sortOrder: 1, targetCategoryId: 'groceries' },
  { id: 'b2', title: 'Borrow before you buy', subtitle: 'Drills, ladders and more from neighbours',
    imageUrl: img('banner-lend'), sortOrder: 2, targetCategoryId: 'tools' },
  { id: 'b3', title: 'Kitchen upgrades', subtitle: 'Up to 30% off appliances',
    imageUrl: img('banner-kitchen'), sortOrder: 3, targetCategoryId: 'kitchen' },
];

const in90Days = admin.firestore.Timestamp.fromMillis(Date.now() + 90 * 864e5);
const coupons = [
  { code: 'WELCOME10', type: 'percent', value: 10, minOrder: 299, maxDiscount: 150,
    expiresAt: in90Days, usageLimit: 0, usedCount: 0, active: true },
  { code: 'FLAT50', type: 'flat', value: 50, minOrder: 499, maxDiscount: null,
    expiresAt: in90Days, usageLimit: 1000, usedCount: 0, active: true },
  { code: 'OLD20', type: 'percent', value: 20, minOrder: 0, maxDiscount: null,
    expiresAt: admin.firestore.Timestamp.fromMillis(Date.now() - 864e5),
    usageLimit: 0, usedCount: 0, active: true }, // expired, for testing errors
];

const reviewers = ['Priya S.', 'Rahul M.', 'Neha P.', 'Amit K.', 'Kavita D.'];
const reviewTexts = [
  [5, 'Great quality and arrived well packed.'],
  [4, 'Good value for the price. Would buy again.'],
  [5, 'Exactly as described. Delivery was quick.'],
  [3, 'Decent, but the packaging could be better.'],
];

async function main() {
  const batch = db.batch();

  for (const c of categories) {
    batch.set(db.collection('categories').doc(c.id), {
      name: c.name, imageUrl: img(c.id), sortOrder: c.sortOrder, active: true,
    });
  }

  products.forEach((p, idx) => {
    const [id, name, brand, categoryId, price, mrp, stock, gstRate, soldCount,
      ratingAvg, ratingCount, isDealOfDay, description, variantSpec] = p;
    const variants = variantSpec
      ? variantSpec.items.map(([label, _, vPrice, vMrp, vStock]) => ({
          id: label.toLowerCase(), label, price: vPrice, mrp: vMrp, stock: vStock,
        }))
      : [];
    batch.set(db.collection('products').doc(id), {
      name, nameLower: name.toLowerCase(), description, brand, categoryId,
      images: [img(id, 0), img(id, 1), img(id, 2)],
      price, mrp, stock, gstRate,
      variantLabel: variantSpec ? variantSpec.label : '',
      variants,
      ratingAvg, ratingCount, soldCount, isDealOfDay, active: true,
      searchKeywords: keywords(name, brand),
      // Stagger creation dates so "Newest" sorting is visible.
      createdAt: admin.firestore.Timestamp.fromMillis(Date.now() - idx * 36e5),
    });
  });

  for (const b of banners) {
    const { id, ...data } = b;
    batch.set(db.collection('banners').doc(id), { ...data, active: true });
  }

  for (const c of coupons) {
    batch.set(db.collection('coupons').doc(c.code), c);
  }

  batch.set(db.collection('appSettings').doc('pricing'), {
    deliveryFee: 40, freeDeliveryAbove: 499, codMaxAmount: 10000,
  });

  // Seller details printed on GST invoices. Replace with your real business
  // details (and a real GSTIN) before going live; editable in the admin
  // panel from Phase 4.
  batch.set(db.collection('appSettings').doc('business'), {
    legalName: 'SocietyCart Retail Pvt. Ltd. (Sample)',
    gstin: '24ABCDE1234F1Z5',
    addressLine: 'Unit 4, Sample Business Park, 150 Ft Ring Road',
    city: 'Ahmedabad', state: 'Gujarat', stateCode: '24', pincode: '380015',
    email: 'support@societycart.example', phone: '+91 90000 00000',
  });

  // A few reviews on the first 8 products.
  products.slice(0, 8).forEach(([productId], pi) => {
    reviewTexts.slice(0, 2 + (pi % 3)).forEach(([rating, comment], ri) => {
      batch.set(db.collection('reviews').doc(`${productId}-r${ri}`), {
        productId, userId: `seed-user-${ri}`, userName: reviewers[(pi + ri) % reviewers.length],
        rating, comment, imageUrls: [],
        createdAt: admin.firestore.Timestamp.fromMillis(Date.now() - (ri + 1) * 864e5),
      });
    });
  });

  // ----------------- USER SEEDING -----------------
  // Create an Admin and a Normal User
  const usersToCreate = [
    {
      uid: 'admin-user-id',
      email: 'admin@societycart.com',
      password: 'AdminPassword123!',
      displayName: 'SocietyCart Admin',
      phone: '+919000000001',
      role: 'admin' // We will store this in Firestore
    },
    {
      uid: 'test-user-id',
      email: 'user@societycart.com',
      password: 'UserPassword123!',
      displayName: 'Test User',
      phone: '+919000000002',
      role: 'user'
    }
  ];

  for (const u of usersToCreate) {
    try {
      await admin.auth().createUser({
        uid: u.uid,
        email: u.email,
        password: u.password,
        displayName: u.displayName,
        phoneNumber: u.phone,
      });
      console.log(`Created Auth user: ${u.email}`);
    } catch (err) {
      if (err.code === 'auth/uid-already-exists' || err.code === 'auth/email-already-exists') {
        console.log(`Auth user already exists: ${u.email}`);
      } else {
        console.error(`Failed to create user ${u.email}:`, err.message);
      }
    }

    // Add user document in Firestore
    batch.set(db.collection('users').doc(u.uid), {
      uid: u.uid,
      email: u.email,
      fullName: u.displayName,
      phone: u.phone,
      role: u.role, // 'admin' or 'user'
      createdAt: admin.firestore.Timestamp.now(),
    });
  }

  await batch.commit();
  console.log(`Seeded ${categories.length} categories, ${products.length} products, ` +
    `${banners.length} banners, ${coupons.length} coupons, pricing settings, reviews, and test users.`);
}

main().catch((e) => { console.error(e); process.exit(1); });
