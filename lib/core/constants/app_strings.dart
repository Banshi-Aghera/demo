/// Every user-facing string lives here so Hindi and Gujarati can be added
/// later by swapping this file for ARB-based localisation.
class AppStrings {
  AppStrings._();

  // App
  static const appName = 'SocietyCart';
  static const tagline = 'Shop smarter with your neighbours';

  // Onboarding
  static const onboardingTitle1 = 'Everything you need, delivered';
  static const onboardingBody1 =
      'Groceries, home essentials and more, at fair prices with GST invoices on every order.';
  static const onboardingTitle2 = 'Neighbour Drop';
  static const onboardingBody2 =
      'Join a shared delivery slot with your building. Delivery is free, and a neighbour can receive your parcel if you are out.';
  static const onboardingTitle3 = 'Borrow before you buy';
  static const onboardingBody3 =
      'Need a drill for one afternoon? Borrow it from a neighbour for a small daily rent instead of buying it.';
  static const skip = 'Skip';
  static const next = 'Next';
  static const getStarted = 'Get started';

  // Login
  static const welcomeBack = 'Welcome back';
  static const loginSubtitle = 'Log in to continue shopping';
  static const email = 'Email';
  static const password = 'Password';
  static const login = 'Log in';
  static const loginWithOtp = 'Log in with OTP';
  static const continueWithGoogle = 'Continue with Google';
  static const forgotPassword = 'Forgot password?';
  static const noAccount = "Don't have an account?";
  static const register = 'Register';
  static const or = 'or';

  // Register
  static const createAccount = 'Create your account';
  static const registerSubtitle = 'It takes less than a minute';
  static const fullName = 'Full name';
  static const phone = 'Phone number';
  static const confirmPassword = 'Confirm password';
  static const haveAccount = 'Already have an account?';
  static const passwordHint = 'At least 8 characters, including a number';

  // Forgot password
  static const resetPassword = 'Reset password';
  static const resetSubtitle =
      "Enter your account email and we'll send you a link to set a new password.";
  static const sendResetLink = 'Send reset link';
  static const resetSentTitle = 'Check your email';
  static const resetSentBody =
      'We sent a password reset link to your email. Follow it, then log in with your new password.';
  static const backToLogin = 'Back to login';

  // OTP
  static const otpTitle = 'Log in with OTP';
  static const otpPhoneSubtitle = "We'll send a 6-digit code to your phone.";
  static const sendOtp = 'Send OTP';
  static const otpCodeSubtitle = 'Enter the 6-digit code sent to';
  static const otpCode = 'OTP code';
  static const verifyOtp = 'Verify and log in';
  static const resendOtp = 'Resend OTP';
  static const resendIn = 'Resend in';
  static const changeNumber = 'Change number';
  static const seconds = 's';

  // Join society
  static const joinSocietyTitle = 'Join your society';
  static const joinSocietySubtitle =
      'Unlock Neighbour Drop, Lending and Group Buy. A society admin will approve your request.';
  static const searchByName = 'Search by name';
  static const enterCode = 'Society code';
  static const searchSocietyHint = 'Type at least 2 letters';
  static const societyCodeHint = 'e.g. GREENPARK01';
  static const find = 'Find';
  static const noSocietiesFound =
      'No societies match that name. Try a society code instead.';
  static const change = 'Change';
  static const wingOrBuilding = 'Wing / building';
  static const flatNumber = 'Flat number';
  static const sendRequest = 'Send request';
  static const skipForNow = 'Skip for now';
  static const requestSent =
      'Request sent. You can shop now; My Society unlocks once approved.';

  // Customer navigation
  static const navHome = 'Home';
  static const navCategories = 'Categories';
  static const navMySociety = 'My Society';
  static const navCart = 'Cart';
  static const navProfile = 'Profile';

  // Home / tabs (content arrives in later phases)
  static const hello = 'Hello';
  static const helloGuest = 'Hello there';
  static const storeComingTitle = 'The store is being stocked';
  static const storeComingBody =
      'Products, deals and search arrive in the next update.';
  static const categoriesComingBody =
      'Browse by category once products are added.';
  static const cartEmptyTitle = 'Your cart is empty';
  static const cartEmptyBody = 'Items you add will appear here.';

  // My Society
  static const neighbourDrop = 'Neighbour Drop';
  static const lending = 'Lending';
  static const groupBuy = 'Group Buy';
  static const societyLockedTitle = 'My Society is locked';
  static const societyLockedBody =
      'Join your society to share delivery slots, borrow from neighbours and unlock group prices.';
  static const societyPendingTitle = 'Approval pending';
  static const societyPendingBody =
      'Your request has been sent. A society admin will review it soon.';
  static const societyRejectedTitle = 'Request not approved';
  static const societyRejectedBody =
      'Check your wing and flat number, then send a new request.';
  static const sendNewRequest = 'Send a new request';
  static const featureComingBody = 'This feature arrives in an upcoming update.';

  // Profile
  static const profile = 'Profile';
  static const societyMembership = 'Society membership';
  static const notJoined = 'Not joined';
  static const statusPending = 'Pending approval';
  static const statusApproved = 'Approved';
  static const statusRejected = 'Not approved';
  static const logout = 'Log out';
  static const logoutConfirmTitle = 'Log out?';
  static const logoutConfirmBody = 'You can log back in any time.';
  static const cancel = 'Cancel';
  static const addYourName = 'Add your name';

  // Admin
  static const adminPanel = 'Admin panel';
  static const adminDashboard = 'Dashboard';
  static const adminProducts = 'Products';
  static const adminCategories = 'Categories & banners';
  static const adminOrders = 'Orders';
  static const adminUsers = 'Users';
  static const adminSocieties = 'Societies';
  static const adminNeighbourDrop = 'Neighbour Drop';
  static const adminLending = 'Lending';
  static const adminGroupBuy = 'Group Buy';
  static const adminCoupons = 'Coupons';
  static const adminSettings = 'Settings';
  static const adminReports = 'Reports';
  static const adminSectionComing =
      'This section is built in an upcoming phase.';
  static const signedInAs = 'Signed in as';

  // Network
  static const offline =
      "You're offline. Some actions won't work until you reconnect.";

  // Validation
  static const errRequired = 'This field is required';
  static const errNameShort = 'Enter your full name';
  static const errEmail = 'Enter a valid email address';
  static const errPhone = 'Enter a valid 10-digit Indian mobile number';
  static const errPasswordLength = 'Use at least 8 characters';
  static const errPasswordNumber = 'Include at least one number';
  static const errPasswordMatch = "Passwords don't match";
  static const errOtp = 'Enter the 6-digit code';

  // Errors
  static const errWrongCredentials = 'Email or password is incorrect.';
  static const errEmailInUse =
      'An account already exists with this email. Try logging in instead.';
  static const errWeakPassword = 'Choose a stronger password.';
  static const errNoInternet =
      'No internet connection. Check your network and try again.';
  static const errTooManyRequests =
      'Too many attempts. Wait a few minutes and try again.';
  static const errUserDisabled = 'This account has been disabled.';
  static const errBlocked =
      'Your account is blocked. Contact SocietyCart support for help.';
  static const errInvalidOtp = "That code isn't right. Check it and try again.";
  static const errOtpExpired = 'This code has expired. Request a new one.';
  static const errInvalidPhone = 'This phone number is not valid.';
  static const errGoogle = "Google sign-in didn't complete. Try again.";
  static const errPermission = "You don't have permission to do that.";
  static const errSocietyCodeNotFound =
      'No society found with that code. Check it with your society office.';
  static const errSelectSociety = 'Select your society first';
  static const errNotSignedIn = 'Please log in again.';
  static const errGeneric = 'Something went wrong. Please try again.';
  static const retry = 'Try again';

  // ---------- Phase 2: catalog ----------
  static const searchHint = 'Search products and brands';
  static const dealsOfTheDay = 'Deals of the day';
  static const popularNow = 'Popular now';
  static const recentlyViewed = 'Recently viewed';
  static const shopByCategory = 'Shop by category';
  static const seeAll = 'See all';
  static const off = 'off';
  static const mrp = 'MRP';
  static const inclusiveOfTaxes = 'Inclusive of all taxes';
  static const inStock = 'In stock';
  static const onlyFewLeft = 'Only {n} left';
  static const outOfStock = 'Out of stock';
  static const description = 'Description';
  static const showMore = 'Show more';
  static const showLess = 'Show less';
  static const ratingsAndReviews = 'Ratings & reviews';
  static const noReviewsYet =
      'No reviews yet. Buyers can review this product after delivery.';
  static const ratings = 'ratings';
  static const youMayAlsoLike = 'You may also like';
  static const addToCart = 'Add to cart';
  static const goToCart = 'Go to cart';
  static const addedToCart = 'Added to cart';
  static const selectVariant = 'Select an option';
  static const quantity = 'Quantity';
  static const productNotFound = 'This product is no longer available.';
  static const noProductsTitle = 'Nothing here yet';
  static const noProductsInCategory =
      'No products in this category yet. Check back soon.';
  static const noProductsMatchFilters =
      'No products match these filters. Try widening your price range or clearing filters.';
  static const clearFilters = 'Clear filters';
  static const searchEmptyTitle = 'Search SocietyCart';
  static const searchEmptyBody = 'Type a product name or brand.';
  static const searchNoResultsTitle = 'No results';
  static const searchNoResultsBody =
      'Check the spelling or try a shorter word, like "rice" or "soap".';
  static const noCategories = 'Categories will appear here once added.';

  // Filters and sort
  static const filters = 'Filters';
  static const sortBy = 'Sort by';
  static const sortNewest = 'Newest';
  static const sortPriceLowHigh = 'Price: low to high';
  static const sortPriceHighLow = 'Price: high to low';
  static const sortPopular = 'Popular';
  static const priceRange = 'Price range';
  static const brand = 'Brand';
  static const customerRating = 'Customer rating';
  static const anyRating = 'Any';
  static const andUp = '& up';
  static const apply = 'Apply';
  static const reset = 'Reset';

  // Wishlist
  static const wishlist = 'Wishlist';
  static const wishlistEmptyTitle = 'Your wishlist is empty';
  static const wishlistEmptyBody =
      'Tap the heart on any product to save it here.';
  static const addedToWishlist = 'Saved to wishlist';
  static const removedFromWishlist = 'Removed from wishlist';
  static const moveToWishlist = 'Move to wishlist';
  static const movedToWishlist = 'Moved to wishlist';

  // Cart
  static const remove = 'Remove';
  static const startShopping = 'Start shopping';
  static const couponCode = 'Coupon code';
  static const applyCoupon = 'Apply';
  static const couponApplied = 'Coupon applied';
  static const removeCoupon = 'Remove coupon';
  static const priceDetails = 'Price details';
  static const itemTotalMrp = 'Item total (MRP)';
  static const productDiscount = 'Product discount';
  static const couponDiscount = 'Coupon discount';
  static const deliveryFee = 'Delivery fee';
  static const free = 'FREE';
  static const gstIncluded = 'GST (included in prices)';
  static const grandTotal = 'Grand total';
  static const youSave = 'You save';
  static const addMoreForFreeDelivery = 'Add {amount} more for free delivery';
  static const freeDeliveryUnlocked = 'You get free delivery on this order';
  static const proceedToCheckout = 'Proceed to checkout';
  static const checkoutNextPhase = 'Checkout is added in the next update.';
  static const items = 'items';
  static const item = 'item';
  static const maxQuantityReached = 'No more stock available for this item';

  // Coupon errors
  static const errCouponNotFound = 'That coupon code does not exist.';
  static const errCouponInvalid = 'This coupon is no longer active.';
  static const errCouponExpired = 'This coupon has expired.';
  static const errCouponUsedUp = 'This coupon has reached its usage limit.';
  static const errCouponMinOrder = 'Add items worth at least {amount} to use this coupon.';
  static const errOutOfStock = 'This item is out of stock.';

  // ---------- Phase 3: addresses ----------
  static const addresses = 'Saved addresses';
  static const addAddress = 'Add address';
  static const editAddress = 'Edit address';
  static const noAddressesTitle = 'No saved addresses';
  static const noAddressesBody = 'Add a delivery address to place orders.';
  static const addressLine1 = 'Flat, house no., building';
  static const addressLine2 = 'Area, street, sector';
  static const landmark = 'Landmark (optional)';
  static const city = 'City';
  static const state = 'State';
  static const pincode = 'PIN code';
  static const addressLabel = 'Save as';
  static const labelHome = 'Home';
  static const labelWork = 'Work';
  static const labelOther = 'Other';
  static const setAsDefault = 'Use as my default address';
  static const defaultTag = 'Default';
  static const saveAddress = 'Save address';
  static const deleteAddress = 'Delete address';
  static const deleteAddressConfirm = 'Delete this address?';
  static const delete = 'Delete';
  static const edit = 'Edit';
  static const errPincode = 'Enter a valid 6-digit PIN code';
  static const errSelectState = 'Select your state';

  // ---------- Checkout ----------
  static const checkout = 'Checkout';
  static const deliverTo = 'Deliver to';
  static const changeAddress = 'Change';
  static const deliveryOption = 'Delivery';
  static const standardDelivery = 'Standard delivery';
  static const standardDeliveryBody = 'Delivered to your door in 1-3 days';
  static const paymentMethod = 'Payment';
  static const payOnline = 'Pay online';
  static const payOnlineBody = 'UPI, cards, net banking and wallets via Razorpay';
  static const cashOnDelivery = 'Cash on Delivery';
  static const codBody = 'Pay in cash or UPI when the order arrives';
  static const codUnavailable = 'Cash on Delivery is available for orders up to {amount}';
  static const onlineUnavailableWeb = 'Online payment is available in the mobile app';
  static const orderSummary = 'Order summary';
  static const placeOrder = 'Place order';
  static const payAmount = 'Pay {amount}';
  static const selectAddressFirst = 'Add a delivery address to continue';
  static const paymentCancelled = 'Payment was cancelled. Your order is saved; you can pay from My orders within 30 minutes.';
  static const paymentFailedTitle = 'Payment not completed';
  static const payLater = 'Pay later';
  static const retryPayment = 'Retry payment';
  static const verifyingPayment = 'Confirming your payment…';

  // ---------- Order success ----------
  static const orderPlaced = 'Order placed!';
  static const orderNumberLabel = 'Order number';
  static const youSavedOnOrder = 'You saved {amount} on this order';
  static const viewOrder = 'View order';
  static const continueShopping = 'Continue shopping';

  // ---------- Orders ----------
  static const myOrders = 'My orders';
  static const noOrdersTitle = 'No orders yet';
  static const noOrdersBody = 'Orders you place will show up here.';
  static const orderDetails = 'Order details';
  static const placedOn = 'Placed on';
  static const itemsInOrder = 'Items';
  static const deliveryAddress = 'Delivery address';
  static const paymentLabel = 'Payment';
  static const statusPendingPayment = 'Awaiting payment';
  static const statusPlaced = 'Placed';
  static const statusPacked = 'Packed';
  static const statusShipped = 'Shipped';
  static const statusOutForDelivery = 'Out for delivery';
  static const statusDelivered = 'Delivered';
  static const statusCancelled = 'Cancelled';
  static const statusReturnRequested = 'Return requested';
  static const statusReturned = 'Returned';
  static const payStatusPending = 'Payment pending';
  static const payStatusPaid = 'Paid online';
  static const payStatusFailed = 'Payment failed';
  static const payStatusRefunded = 'Refunded';
  static const payStatusRefundPending = 'Refund in progress';
  static const payStatusCodPending = 'Cash on Delivery';
  static const payStatusCodCollected = 'Paid on delivery';
  static const cancelOrder = 'Cancel order';
  static const cancelOrderTitle = 'Cancel this order?';
  static const cancelOrderBody = 'If you paid online, the full amount is refunded to your original payment method in 5-7 working days.';
  static const cancelReasonHint = 'Reason (optional)';
  static const keepOrder = 'Keep order';
  static const orderCancelled = 'Order cancelled';
  static const requestReturn = 'Request return';
  static const downloadInvoice = 'Download GST invoice';
  static const payNow = 'Pay now';
  static const rateItem = 'Rate';
  static const rated = 'Rated';
  static const cancelledReason = 'Reason';
  static const items2 = 'items';

  // ---------- Returns ----------
  static const returnTitle = 'Request a return';
  static const returnReason = 'Why are you returning this?';
  static const reasonDamaged = 'Item arrived damaged';
  static const reasonWrongItem = 'Wrong item delivered';
  static const reasonNotAsDescribed = 'Not as described';
  static const reasonQuality = 'Quality not as expected';
  static const reasonOther = 'Other';
  static const returnComment = 'Tell us more (optional)';
  static const addPhotos = 'Add photos (up to 3)';
  static const addPhoto = 'Add photo';
  static const submitReturn = 'Submit return request';
  static const returnSubmitted = 'Return requested. We\'ll review it within 48 hours.';
  static const errReturnReason = 'Choose a reason';
  static const returnWindowNote = 'Returns are accepted within 7 days of delivery.';

  // ---------- Reviews ----------
  static const writeReview = 'Rate this product';
  static const yourRating = 'Your rating';
  static const reviewCommentHint = 'What did you like or dislike? (optional)';
  static const submitReview = 'Submit review';
  static const reviewThanks = 'Thanks for your review!';
  static const errRatingRequired = 'Tap a star to rate';

  // ---------- Invoice ----------
  static const taxInvoice = 'TAX INVOICE';
  static const invoiceNo = 'Invoice no.';
  static const invoiceDate = 'Invoice date';
  static const orderNo = 'Order no.';
  static const soldBy = 'Sold by';
  static const billTo = 'Bill / ship to';
  static const gstin = 'GSTIN';
  static const placeOfSupply = 'Place of supply';
  static const invItem = 'Item';
  static const invQty = 'Qty';
  static const invTaxable = 'Taxable value';
  static const invGstRate = 'GST %';
  static const invCgst = 'CGST';
  static const invSgst = 'SGST';
  static const invIgst = 'IGST';
  static const invTotal = 'Total';
  static const invDeliveryCharges = 'Delivery charges';
  static const invCouponNote = 'Item values are after coupon discount';
  static const amountInWords = 'Amount in words';
  static const invFooter = 'This is a computer-generated invoice and does not need a signature.';
  static const sellerNotConfigured = 'Seller details are not set up yet. Ask the admin to fill in Settings > Business details.';
  static const preparingInvoice = 'Preparing invoice…';

  // ---------- Notifications ----------
  static const notifications = 'Notifications';
  static const noNotificationsTitle = 'No notifications';
  static const noNotificationsBody = 'Order updates and offers will appear here.';
  static const markAllRead = 'Mark all read';
  static const notificationSettings = 'Notification settings';
  static const notifOrderUpdates = 'Order updates';
  static const notifOrderUpdatesBody = 'Placed, shipped, delivered and refunds';
  static const notifOffers = 'Offers and deals';
  static const notifOffersBody = 'Discounts, group buys and new arrivals';
  static const notifSettingsNote = 'You can still see every update in the Notifications list.';

  // ---------- Phase 4: admin shared ----------
  static const save = 'Save';
  static const saved = 'Saved';
  static const search = 'Search';
  static const refresh = 'Refresh';
  static const all = 'All';
  static const active = 'Active';
  static const inactive = 'Inactive';
  static const status = 'Status';
  static const actions = 'Actions';
  static const none = 'None';
  static const loadMore = 'Load more';
  static const noResults = 'Nothing found';
  static const adminOnlyTitle = 'Admins only';
  static const adminOnlyBody = 'This area is for store administrators.';
  static const confirmDelete = 'Delete this permanently?';
  static const deleted = 'Deleted';
  static const required_ = 'Required';
  static const optional = 'Optional';
  static const unsavedChanges = 'Discard unsaved changes?';
  static const discard = 'Discard';
  static const keepEditing = 'Keep editing';

  // Dashboard
  static const todayRevenue = "Today's revenue";
  static const totalOrders = 'Total orders';
  static const pendingOrders = 'Pending orders';
  static const newUsers = 'New users (7 days)';
  static const salesChart = 'Sales';
  static const last7Days = '7 days';
  static const last30Days = '30 days';
  static const topProducts = 'Top products';
  static const lowStock = 'Low stock';
  static const lowStockBody = 'Items with 5 or fewer left';
  static const noLowStock = 'All items are well stocked.';
  static const dropSavings = 'Neighbour Drop savings';
  static const tripsSaved = 'delivery trips saved';
  static const activeLendings = 'Active lendings';
  static const noSalesYet = 'No sales in this period yet.';
  static const sold = 'sold';

  // Admin products
  static const newProduct = 'New product';
  static const editProduct = 'Edit product';
  static const productName = 'Product name';
  static const productBrand = 'Brand';
  static const productCategory = 'Category';
  static const productDescription = 'Description';
  static const sellingPrice = 'Selling price';
  static const mrpLabel = 'MRP';
  static const stockLabel = 'Stock';
  static const gstRate = 'GST rate (%)';
  static const images = 'Images';
  static const addImage = 'Add image';
  static const productActive = 'Visible in the store';
  static const markDealOfDay = 'Show in Deals of the day';
  static const variantsLabel = 'Variants';
  static const variantGroupLabel = 'Variant label (e.g. Size, Pack)';
  static const addVariant = 'Add variant';
  static const variantName = 'Option (e.g. 1kg)';
  static const noProductsAdmin = 'No products yet. Add your first one.';
  static const errPriceAboveMrp = 'Selling price cannot be above MRP';
  static const errNumber = 'Enter a valid number';
  static const errCategoryRequired = 'Choose a category';
  static const errImageRequired = 'Add at least one image';
  static const productSaved = 'Product saved';
  static const deleteProduct = 'Delete product';
  static const deleteProductBody = 'Past orders keep their own copy of this item, so they are unaffected.';
  static const searchProducts = 'Search products';
  static const filterCategory = 'Category';
  static const filterStock = 'Stock';
  static const inStockOnly = 'In stock';
  static const outOfStockOnly = 'Out of stock';
  static const lowStockOnly = 'Low stock';

  // Categories & banners
  static const newCategory = 'New category';
  static const editCategory = 'Edit category';
  static const categoryName = 'Category name';
  static const sortOrder = 'Sort order';
  static const image = 'Image';
  static const noCategoriesAdmin = 'No categories yet.';
  static const newBanner = 'New banner';
  static const editBanner = 'Edit banner';
  static const bannerTitle = 'Title';
  static const bannerSubtitle = 'Subtitle';
  static const bannerTarget = 'Opens';
  static const targetNone = 'Nothing';
  static const targetCategory = 'A category';
  static const targetProduct = 'A product';
  static const noBanners = 'No banners yet.';
  static const banners = 'Banners';
  static const categories2 = 'Categories';
  static const productId = 'Product ID';

  // Admin orders
  static const allOrders = 'Orders';
  static const searchOrders = 'Search by order number, name or phone';
  static const updateStatus = 'Update status';
  static const markPacked = 'Mark packed';
  static const markShipped = 'Mark shipped';
  static const markOutForDelivery = 'Mark out for delivery';
  static const markDelivered = 'Mark delivered';
  static const statusUpdated = 'Status updated';
  static const customer = 'Customer';
  static const returnRequestLabel = 'Return request';
  static const approveReturn = 'Approve return & refund';
  static const rejectReturn = 'Reject return';
  static const returnResolved = 'Return updated';
  static const rejectReason = 'Reason shown to the customer';
  static const noOrdersAdmin = 'No orders match this filter.';
  static const retryRefund = 'Retry refund';
  static const refundIssued = 'Refund issued';

  // Users
  static const allUsers = 'Users';
  static const searchUsers = 'Search by name, email or phone';
  static const blockUser = 'Block';
  static const unblockUser = 'Unblock';
  static const blocked = 'Blocked';
  static const makeAdmin = 'Make admin';
  static const removeAdmin = 'Remove admin role';
  static const roleCustomer = 'Customer';
  static const roleAdmin = 'Admin';
  static const userOrders = 'Orders by this user';
  static const joined = 'Joined';
  static const userUpdated = 'User updated';
  static const cannotEditSelf = 'You cannot change your own role or access.';
  static const blockUserBody = 'They are signed out and cannot log in until unblocked.';

  // Societies
  static const allSocieties = 'Societies';
  static const newSociety = 'New society';
  static const editSociety = 'Edit society';
  static const societyName = 'Society name';
  static const societyCode = 'Society code';
  static const societyCodeHelp = 'Residents type this to join. Letters and numbers only.';
  static const address = 'Address';
  static const securityDeskReceiver = 'Security desk receives Neighbour Drop parcels';
  static const membershipRequests = 'Membership requests';
  static const noRequests = 'No pending requests.';
  static const approve = 'Approve';
  static const reject = 'Reject';
  static const membershipUpdated = 'Membership updated';
  static const noSocietiesAdmin = 'No societies yet. Add one so residents can join.';
  static const errCodeTaken = 'That society code is already in use.';
  static const errCodeFormat = 'Use 4-20 letters or numbers';
  static const members = 'members';

  // Coupons
  static const allCoupons = 'Coupons';
  static const newCoupon = 'New coupon';
  static const editCoupon = 'Edit coupon';
  static const couponCodeLabel = 'Code';
  static const couponType = 'Discount type';
  static const typePercent = 'Percentage';
  static const typeFlat = 'Flat amount';
  static const discountValue = 'Discount value';
  static const minOrderValue = 'Minimum order value';
  static const maxDiscountValue = 'Maximum discount (optional)';
  static const expiresOn = 'Expires on';
  static const usageLimitLabel = 'Usage limit (0 = unlimited)';
  static const usedLabel = 'Used';
  static const couponActive = 'Active';
  static const noCoupons = 'No coupons yet.';
  static const couponSaved = 'Coupon saved';
  static const errCouponCodeFormat = 'Use 3-20 letters or numbers';
  static const pickDate = 'Pick a date';
  static const noExpiry = 'No expiry';

  // Settings
  static const settingsDelivery = 'Delivery & payments';
  static const deliveryFeeLabel = 'Delivery fee';
  static const freeDeliveryAbove = 'Free delivery above';
  static const codMaxLabel = 'Maximum COD order value';
  static const settingsRewards = 'Rewards & fees';
  static const pointsPerParcel = 'Reward points per parcel received';
  static const pointsValue = 'Points needed for ₹1';
  static const lendingFeePercent = 'Lending app fee (%)';
  static const minOrdersPerSlot = 'Minimum orders to confirm a slot';
  static const settingsBusiness = 'Business details (GST invoices)';
  static const legalName = 'Legal business name';
  static const gstinLabel = 'GSTIN';
  static const settingsSaved = 'Settings saved';
  static const errGstin = 'Enter a valid 15-character GSTIN';
  static const businessHelp = 'These details are printed on every GST invoice.';

  // Reports
  static const reportsTitle = 'Reports';
  static const exportOrders = 'Export orders (CSV)';
  static const exportSales = 'Export product sales (CSV)';
  static const dateRange = 'Date range';
  static const from = 'From';
  static const to = 'To';
  static const exportReady = 'Export downloaded';
  static const noDataToExport = 'No orders in this range.';
  static const exporting = 'Preparing export…';
  static const subtotalLabel = 'Item total';
}
