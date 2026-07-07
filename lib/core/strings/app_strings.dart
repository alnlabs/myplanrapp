abstract final class AppStrings {
  static const appName = 'MyPlanr';

  // Nav
  static const navHome = 'Home';
  static const navPantry = 'Inventory';
  static const navInventory = 'Inventory';
  static const navRecipes = 'Recipes';
  static const navPlans = 'Plans';
  static const navExpenses = 'Expenses';
  static const navReminders = 'Reminders';
  static const navShop = 'Shop';
  static const navMore = 'More';
  static const moreSubtitle = 'Family, settings, and more features';
  static const moreFeatureOverflowHint = 'Open feature';
  static const moreSectionFeatures = 'Features';
  static const moreSectionMoney = 'Money';
  static const moreSectionHousehold = 'Home & family';
  static const moreSectionApp = 'App';
  static const moreInventoryHint = 'Pantry stock and home assets';
  static const morePlansHint = 'Tasks, meals, and reminders';
  static const moreRecipesHint = 'Saved recipes and cooking';
  static const moreExpensesHint = 'Track household spending';
  static const moreShopHint = 'Shared shopping list';
  static const moreSubscriptionsHint = 'Recurring bills and services';
  static const moreRemindersHint = 'All reminders in one place';
  static const moreFamilyHint = 'Family roster and feature settings';
  static const moreSettingsHint = 'Account, appearance, and app preferences';
  static const settingsTitle = 'Settings';
  static const settingsAccountSection = 'Account';
  static const settingsAppearanceSection = 'Appearance';
  static const settingsNotificationsSection = 'Notifications';
  static const settingsSupportSection = 'Support';
  static const settingsLegalSection = 'Legal';
  static const settingsAboutSection = 'About';
  static const settingsTheme = 'Theme';
  static const settingsThemeSystem = 'System default';
  static const settingsThemeLight = 'Light';
  static const settingsThemeDark = 'Dark';
  static const settingsNotifications = 'Reminders & alerts';
  static const settingsNotificationsHint =
      'Plan and subscription reminders on this device';
  static const settingsRequestNotificationPermission = 'Allow reminders on this device';
  static const settingsNotificationPermissionGranted =
      'Reminder permissions enabled';
  static const settingsNotificationPermissionDenied =
      'Reminder permissions were not fully granted';
  static const settingsExactAlarmHint =
      'On Android, also allow Alarms & reminders in system settings for on-time alerts';
  static const settingsPermissions = 'Device permissions';
  static const settingsPermissionsHint =
      'Check which device permissions are enabled and turn on the ones this app needs.';
  static const permissionEnabled = 'Enabled';
  static const permissionDisabled = 'Disabled';
  static const permissionBlocked = 'Blocked';
  static const permissionEnable = 'Tap to enable';
  static const permissionManage = 'Tap to manage in settings';
  static const permissionOpenSettings = 'Tap to open system settings';
  static const settingsDiagnosticLogs = 'Diagnostic logs';
  static const settingsDiagnosticLogsHint =
      'Recent app events for troubleshooting';
  static const appVersion = 'Version 1.0.0';
  static const rateApp = 'Rate MyPlanr';
  static const rateAppHint = 'Enjoying the app? Leave a rating';
  static const checkForUpdates = 'Check for updates';
  static const checkForUpdatesHint = 'See if a newer version is available';
  static const updateChecking = 'Checking for updates…';
  static const updateUpToDate = "You're on the latest version";
  static const updateStarted = 'Update started';
  static const updateDownloaded = 'Update downloaded. Restart to install.';
  static const updateRestart = 'Restart';
  static const updateNotSupported = 'Updates are managed by your app store';
  static const updateError = 'Could not check for updates right now';

  // Pantry
  static const pantryTitle = 'Pantry';
  static const inventoryTitle = 'Inventory';
  static const segmentFood = 'Food';
  static const segmentAssets = 'Assets';
  static const addItem = 'Add item';
  static const editItem = 'Edit item';
  static const itemName = 'Item name';
  static const brand = 'Brand';
  static const brandOptional = 'Brand (optional)';
  static const quantity = 'Quantity';
  static const unit = 'Unit';
  static const lowStockAlert = 'Low stock alert at';
  static const category = 'Category';
  static const expiryDate = 'Expiry date';
  static const useItem = 'Use';
  static const restockItem = 'Restock';
  static const stockHistory = 'History';
  static const emptyStockHistory = 'No history yet';
  static const emptyPantry = 'No items yet';
  static const emptyPantryHint =
      'Add groceries and home essentials to track stock';
  static const outOfStock = 'Out of stock';
  static const lowStock = 'Low stock';
  static const itemSaved = 'Item saved';
  static const stockUpdated = 'Stock updated';

  // Units
  static const unitG = 'grams (g)';
  static const unitKg = 'kilograms (kg)';
  static const unitMl = 'milliliters (ml)';
  static const unitL = 'liters (L)';
  static const unitPcs = 'pieces';
  static const unitPack = 'pack';

  // Alerts
  static const alertsTitle = 'Low stock';
  static const emptyAlerts = 'All stocked up';
  static const emptyAlertsHint =
      'Items below your alert level will show here';
  static const addToShopList = 'Add to shop list';

  // Expenses
  static const expensesTitle = 'Expenses';
  static const addExpense = 'Add expense';
  static const editExpense = 'Edit expense';
  static const amount = 'Amount';
  static const expenseTitle = 'Title';
  static const paidBy = 'Paid by';
  static const expenseDate = 'Date';
  static const monthlyTotal = 'This month';
  static const note = 'Note';
  static const linkToPantry = 'Restock pantry item';
  static const linkToPantryHint =
      'Log the expense and add stock to a pantry item.';
  static const pantryCreateNew = '+ New pantry item';
  static const pantryChooseItem = 'Choose pantry item';
  static const newItemName = 'New item name';
  static const emptyExpenses = 'No expenses yet';
  static const emptyExpensesHint = 'Track rent, groceries, bills and more';
  static const expenseAdded = 'Expense added';
  static const summaryTitle = 'Monthly summary';

  // Categories
  static const categoryGroceries = 'Groceries';
  static const categoryUtilities = 'Utilities';
  static const categoryRent = 'Rent';
  static const categoryTransport = 'Transport';
  static const categoryMedical = 'Medical';
  static const categoryEntertainment = 'Entertainment';
  static const categoryOther = 'Other';

  // Recipes
  static const recipesTitle = 'Recipes';
  static const addRecipe = 'Add recipe';
  static const recipeName = 'Recipe name';
  static const addIngredient = 'Add ingredient';
  static const editRecipe = 'Edit recipe';
  static const linkPantryItem = 'Link to pantry item';
  static const cookingFor = 'Cooking for';
  static const scaleServings = 'Adjust servings';
  static const servings = 'Servings';
  static const ingredients = 'Ingredients';
  static const instructions = 'Instructions';
  static const cookCheck = 'Can I cook this?';
  static const statusSufficient = 'Enough in pantry';
  static const statusInsufficient = 'Not enough';
  static const statusMissing = 'Not in pantry';
  static const addMissingToShop = 'Add missing to shop list';
  static const emptyRecipes = 'No recipes yet';
  static const emptyRecipesHint = 'Save family favourites like biryani or dal';
  static const ingredientName = 'Ingredient';
  static const recipeSaved = 'Recipe saved';
  static const recipeNotEnoughIngredients =
      'Not all ingredients are available';
  static const recipePantryUpdated = 'Pantry updated after cooking';
  static const recipeAddedMissingToShop = 'Added missing items to shop list';
  static String recipeUpdatePantryConfirm(String servings) =>
      'Update pantry for $servings servings?';
  static String recipeServingsLabel(int servings) => 'Recipe: $servings';
  static String recipeNeedHave(String need, String have) =>
      'Need $need · Have $have';

  // Shopping
  static const shopTitle = 'Shop list';
  static const addToShop = 'Add to list';
  static const markBought = 'Mark as bought';
  static const emptyShop = 'Shop list is empty';
  static const emptyShopHint = 'Add items manually or from recipes and alerts';
  static const sourceLowStock = 'Low stock';
  static const sourceRecipe = 'Recipe';
  static const sourceManual = 'Added manually';
  static const generateFromLowStock = 'Add low stock items';
  static const clearChecked = 'Clear bought';
  static const shopToBuy = 'To buy';
  static const shopBought = 'Bought';
  static const restockOnBuyHint =
      'When you check an item off, its pantry stock is refilled automatically.';
  static const removeItem = 'Remove item';
  static const itemAdded = 'Added to list';
  static const noBoughtItems = 'Nothing bought yet';

  // Household & auth
  static const householdTitle = 'Family';
  static const createHousehold = 'Create family';
  static const joinHousehold = 'Join family';
  static const householdName = 'Family name';
  static const editFamilyName = 'Edit family name';
  static const familyNameUpdated = 'Family name updated';
  static const inviteMember = 'Invite by email';
  static const members = 'Members';
  static const pendingInvites = 'Pending invites';
  static const leaveHousehold = 'Leave family';
  static const removeMember = 'Remove member';
  static const addFamilyMember = 'Add family member';
  static const addMember = 'Add member';
  static const inviteToApp = 'Invite to app';
  static const profileOnly = 'Profile only';
  static const inviteToAppHint = 'They will get an email invite to join on their phone.';
  static const profileOnlyHint =
      'Track plans, health, and reminders for them — notifications go to you.';
  static const relationship = 'Relationship';
  static const phoneOptional = 'Phone (optional)';
  static const inviteSent = 'Invite sent';
  static const memberAdded = 'Member added';
  static const appMember = 'App';
  static const pendingInvite = 'Pending invite';
  static const membersAndRoles = 'Members & roles';
  static const changeMemberType = 'Change type';
  static const makeProfileOnly = 'Make profile only';
  static const inviteToAppTitle = 'Invite to app';
  static const inviteToAppEmailHint = 'Enter their email to send an app invite.';
  static const makeProfileOnlyConfirm =
      'Remove their app access and keep them as a profile-only member? Their saved details are kept.';
  static const memberTypeChanged = 'Member type updated';
  static const roleOwner = 'Owner';
  static const roleCoOwner = 'Co-owner';
  static const roleMember = 'Member';
  static const makeCoOwner = 'Make co-owner';
  static const removeCoOwner = 'Remove co-owner';
  static const roleUpdated = 'Role updated';
  static const changeRole = 'Change role';
  static const membersAndRolesHint =
      'Co-owner can be assigned to app members — people who signed in with their own account.';
  static const noOtherAppMembers =
      'No other app members yet. Invite someone to the app, then you can make them co-owner.';
  static const coOwnerRequiresApp =
      'Profile-only members cannot be co-owners. Invite them to the app first.';
  static const appRole = 'App role';
  static const revokeInvite = 'Revoke invite';
  static const inviteRevoked = 'Invite revoked';
  static const noPendingInvites = 'No pending invites.';
  static const you = 'You';
  static const emptyFamilyRoster = 'No family members yet.';
  static const emptyFamilyRosterHint = 'Add people you manage or invite them to use the app.';
  static const familyMemberCount = 'family members';
  static const managedByYou = 'Managed by you';
  static const tabOverview = 'Overview';
  static const tabHealth = 'Health';
  static const tabEmergency = 'Emergency';
  static const memberType = 'Type';
  static const status = 'Status';
  static const phone = 'Phone';
  static const altPhone = 'Alternate phone';
  static const dateOfBirth = 'Date of birth';
  static const bloodGroup = 'Blood group';
  static const allergies = 'Allergies';
  static const medicines = 'Regular medicines';
  static const doctorName = 'Doctor name';
  static const doctorPhone = 'Doctor phone';
  static const diet = 'Diet';
  static const foodAllergies = 'Food allergies';
  static const workPlace = 'Work place';
  static const schoolName = 'School';
  static const emergencyContactName = 'Emergency contact name';
  static const emergencyContactPhone = 'Emergency contact phone';
  static const emergencyContactRelation = 'Emergency contact relation';
  static const notes = 'Notes';
  static const saved = 'Saved';
  static const avatar = 'Photo';
  static const changePhoto = 'Change photo';
  static const removePhoto = 'Remove photo';
  static const clothingSizes = 'Clothing sizes';
  static const shirtSize = 'Shirt / top';
  static const pantsSize = 'Pants / bottom';
  static const shoeSize = 'Shoe size';
  static const fieldVisibility = 'Sharing with family';
  static const visibilityPhone = 'Share phone number';
  static const visibilityHealth = 'Share health info';
  static const visibilityEmergency = 'Share emergency contacts';
  static const notShared = 'Not shared with household';
  static const sectionPrivate = 'This section is private to the member.';
  static const medicineSchedules = 'Medicine schedules';
  static const addMedicineSchedule = 'Add schedule';
  static const editMedicineSchedule = 'Edit schedule';
  static const medicineName = 'Medicine name';
  static const dosage = 'Dosage';
  static const timesPerDay = 'Times per day';
  static const timesPerDayHint = 'Add at least one reminder time';
  static const addReminderTime = 'Add time';
  static const noMedicineSchedules = 'No medicine schedules yet.';
  static const medicineToday = 'Medicine today';
  static const invalidScheduleTime = 'Use times like 08:00 or 8:00 PM';
  static const active = 'Active';
  static const inactive = 'Inactive';
  static const deleteAccount = 'Delete account';
  static const deleteAccountTitle = 'Delete your account?';
  static const deleteAccountBody =
      'Your account will be scheduled for deletion. You have 30 days to sign in again and keep it. After that, your account and personal data are permanently removed.';
  static const deleteAccountConfirm = 'Schedule deletion';
  static const accountDeletionScheduled =
      'Account scheduled for deletion. Sign in within 30 days to keep it.';
  static const accountDeletionExpired =
      'This account was permanently deleted after the 30-day grace period.';
  static const accountRestoreTitle = 'Restore your account?';
  static const accountRestoreBody =
      'Your account is scheduled for deletion. Sign in within 30 days to keep it.';
  static String accountRestoreBodyWithDate(String date) =>
      'Your account is scheduled for permanent deletion on $date. Tap below to keep it.';
  static const accountRestoreKeep = 'Keep my account';
  static const signIn = 'Sign in';
  static const signUp = 'Create account';
  static const signOut = 'Sign out';
  static const email = 'Email';
  static const password = 'Password';
  static const confirmPassword = 'Confirm password';
  static const passwordsDoNotMatch = 'Passwords do not match';
  static const showPassword = 'Show password';
  static const hidePassword = 'Hide password';
  static const displayName = 'Display name';
  static const username = 'Username';
  static const usernameHint = 'Used to sign in. Letters, numbers, dot or underscore.';
  static const emailOrUsername = 'Email or username';
  static const signUpVerifyEmail =
      'Account created. Check your email to confirm, then sign in.';
  static const profileTitle = 'Profile';
  static const accountInfo = 'Account';
  static const profileDetailsHint =
      'Add phone, health, and emergency details for your household.';
  static const noHousehold = 'Join or create a family to get started';
  static const noHouseholdFamilyHint =
      'Create your family first, then you can add members and invite others.';
  static const createFamilyToContinue = 'Create family to continue';

  // Onboarding
  static const onboardingTitle = 'Welcome to MyPlanr';
  static const onboardingSubtitle =
      'Track pantry stock, plan meals, manage expenses, and shop smarter — together as a family.';
  static const onboardingSlide1Title = 'Welcome to MyPlanr';
  static const onboardingSlide1Body = 'Run your home together — one app for your whole family.';
  static const onboardingSlide2Title = 'Track what you have';
  static const onboardingSlide2Body =
      'Pantry stock, home assets, and warranty dates — know what is at home.';
  static const onboardingSlide3Title = 'Plan and remind';
  static const onboardingSlide3Body =
      'Tasks, meals, medicine, and shopping — for you and family members.';
  static const onboardingSlide4Title = 'Ready?';
  static const onboardingSlide4Body = 'Create an account or sign in to get started.';
  static const skip = 'Skip';
  static const next = 'Next';
  static const getStarted = 'Get started';
  static const acceptTerms =
      'I agree to the Terms of Service and Privacy Policy';
  static const acceptTermsPrefix = 'I agree to the';
  static const termsOfService = 'Terms of Service';
  static const privacyPolicy = 'Privacy Policy';
  static const termsRequired = 'Please accept the terms to continue';

  // Setup wizard
  static const setupWizardTitle = 'Set up your family';
  static const interestsQuestion = 'What do you want to track?';
  static const interestsHint = 'Pick at least one. You can change this later in Family settings.';
  static const continueToHome = 'Continue to home';
  static const skipForNow = 'Skip for now';
  static const wizardStepOf = 'Step';
  static const wizardProfileTitle = 'Your profile';
  static const wizardProfileHint = 'How should your family see you?';
  static const wizardQuickStartTitle = 'Stock your pantry';
  static const wizardQuickStartHint =
      'Add a few items now so low-stock alerts work from day one.';
  static const wizardAddPantryItem = 'Add pantry item';
  static const wizardFamilyTitle = 'Add family members';
  static const wizardFamilyHint =
      'Optional — add a spouse, child, or parent. You can always do this later.';
  static const wizardAddMember = 'Add family member';
  static const wizardFinish = 'Finish setup';
  static const featureSettings = 'Features';
  static const featureSettingsHint = 'Choose what your family uses in the app';
  static const featuresSaved = 'Features updated';

  // Plans
  static const plansTitle = 'Plans';
  static const addPlan = 'Add plan';
  static const editPlan = 'Edit plan';
  static const planTitle = 'Title';
  static const planDescription = 'Description (optional)';
  static const descriptionOptional = 'Description (optional)';
  static const planType = 'Type';
  static const planScope = 'Who sees this';
  static const dueDate = 'Due date';
  static const reminder = 'Reminder';
  static const reminderAt = 'Remind me at';
  static const remindersTitle = 'Reminders';
  static const addReminder = 'Add reminder';
  static const editReminder = 'Edit reminder';
  static const reminderTitle = 'Title';
  static const reminderNotes = 'Notes (optional)';
  static const emptyReminders = 'No reminders yet';
  static const emptyRemindersHint =
      'Create a reminder or enable them on plans, bills, and medicine schedules.';
  static const reminderSourcePlan = 'Plan';
  static const reminderSourceSubscription = 'Subscription';
  static const reminderSourceMedicine = 'Medicine';
  static const reminderSourceStandalone = 'Custom';
  static const reminderRepeatingDaily = 'Repeats daily';
  static const reminderDeleteConfirm = 'Remove this reminder?';
  static const reminderDeleted = 'Reminder removed';
  static const reminderSaved = 'Reminder saved';
  static const reminderMedicineEditHint =
      'Medicine schedules are managed from Family member details.';
  static const remindersSectionOverdue = 'Overdue';
  static const remindersSectionToday = 'Today';
  static const remindersSectionUpcoming = 'Upcoming';
  static const remindersSectionDaily = 'Daily';
  static const forMember = 'For family member';
  static const assignedTo = 'Assigned to';
  static const none = 'None';
  static const completePlan = 'Mark complete';
  static const openPlans = 'Open plans';
  static const emptyPlans = 'No plans yet. Add a task, purchase, or reminder.';
  static const planCompleted = 'Plan completed';
  static const addedToShop = 'Added to shop list';
  static const tabAllPlans = 'All';
  static const tabPersonalPlans = 'Personal';
  static const tabFamilyPlans = 'Family';
  static const tabMealPlans = 'Meals';

  // Assets
  static const assetsTitle = 'Assets';
  static const addAsset = 'Add asset';
  static const editAsset = 'Edit asset';
  static const assetName = 'Item name';
  static const assetCategory = 'Category';
  static const assetKind = 'Kind';
  static const assetLocation = 'Location';
  static const purchaseInfo = 'Purchase';
  static const whereBought = 'Where bought';
  static const purchaseDate = 'Purchase date';
  static const purchaseAmount = 'Purchase amount';
  static const warranty = 'Warranty';
  static const warrantyProvider = 'Warranty provider';
  static const warrantyStart = 'Warranty start';
  static const warrantyEnd = 'Warranty end';
  static const warrantyNotes = 'Warranty notes';
  static const warrantyValid = 'Warranty valid';
  static const warrantyExpiring = 'Warranty expiring';
  static const warrantyExpired = 'Warranty expired';
  static const warrantyExpiringTitle = 'Warranty expiring';
  static const emptyAssets = 'No home assets yet';
  static const emptyAssetsHint = 'Track TVs, appliances, furniture, and warranty dates.';
  static const repairHistory = 'Repair history';
  static const noRepairHistory = 'No repairs logged yet';
  static const logRepair = 'Log repair';
  static const serviceType = 'Service type';
  static const shopName = 'Shop name';
  static const shopPhone = 'Shop phone';
  static const platformName = 'Platform';
  static const agentName = 'Agent name';
  static const bookingRef = 'Booking reference';
  static const serviceCost = 'Cost';
  static const photosAndReceipts = 'Photos & receipts';
  static const addPhoto = 'Add photo';
  static const uploading = 'Uploading…';
  static const noAttachments = 'No photos yet — add warranty cards or receipts';
  static const attachmentWarranty = 'Warranty card';
  static const attachmentReceipt = 'Receipt';
  static const attachmentOther = 'Other document';
  static const pickFromGallery = 'Choose from gallery';
  static const takePhoto = 'Take photo';
  static const deleteAttachment = 'Delete photo?';
  static const deleteAttachmentConfirm =
      'This photo will be removed from the asset.';
  static const photoUploadWarning =
      'Photos may contain personal or financial details. Only upload what you are comfortable sharing with your family.';

  // Subscriptions
  static const subscriptionsTitle = 'Subscriptions';
  static const addSubscription = 'Add subscription';
  static const editSubscription = 'Edit subscription';
  static const deleteSubscription = 'Delete subscription?';
  static const subscriptionName = 'Name';
  static const subscriptionAmount = 'Amount';
  static const billingCycle = 'Billing cycle';
  static const dueDay = 'Due day of month';
  static const dueMonth = 'Due month';
  static const autoRenew = 'Auto-renew';
  static const subscriptionReminderHint = 'Pick a custom date and time';
  static const remindBefore = 'Remind before';
  static const emptySubscriptions = 'No subscriptions yet';
  static const emptySubscriptionsHint =
      'Track Netflix, electricity, DTH, broadband, and other recurring bills.';
  static const subscriptionsDueSoon = 'Bills due soon';
  static const subsMonthlyTotal = 'Monthly';
  static const subsYearlyTotal = 'Yearly';
  static const subsActiveCount = 'Active';
  static const dueToday = 'Due today';
  static const dueTomorrow = 'Due tomorrow';
  static String dueInDays(int days) => 'Due in $days days';
  static String daysBefore(int days) =>
      days == 1 ? '1 day before' : '$days days before';

  // Feedback
  static const feedbackTitle = 'Feedback';
  static const feedbackHint = 'Request a feature or report a problem';
  static const feedbackTypeFeature = 'Feature request';
  static const feedbackTypeBug = 'Report a problem';
  static const feedbackTypeOther = 'Other';
  static const feedbackMessage = 'Tell us more';
  static const feedbackMessageHint =
      'Describe the feature you want or the issue you hit.';
  static const feedbackContact = 'Contact email (optional)';
  static const feedbackContactHint = 'Add it if you want a reply.';
  static const feedbackSubmit = 'Send feedback';
  static const feedbackSubmitted = 'Thanks! Your feedback was sent.';
  static const feedbackEmpty = 'Please enter a message';
  static const moreFeedbackHint = 'Request features or report issues';

  // Common
  static const save = 'Save';
  static const cancel = 'Cancel';
  static const add = 'Add';
  static const edit = 'Edit';
  static const delete = 'Delete';
  static const retry = 'Try again';
  static const loading = 'Loading…';
  static const search = 'Search';
  static const filter = 'Filter';
  static const errorGeneric = 'Something went wrong. Please try again.';
  static const errorNetwork = 'No internet connection';
  static const confirmDelete = 'Are you sure you want to delete this?';
  static const requiredField = 'This field is required';
  static const invalidAmount = 'Enter a valid amount';
  static const invalidQuantity = 'Enter a valid quantity';
  static const missingConfigTitle = 'Setup required';
  static const missingConfigBody =
      'Add your Supabase URL and anon key to the .env file, then restart the app.';
  static const offlineBanner = "You're offline";
  static const offlineWriteBlocked =
      "You're offline. Connect to the internet to save changes.";

  // Diagnostic logs
  static const logsTitle = 'Diagnostic logs';
  static const logsEmpty = 'No logs captured yet.';
  static const logsCopy = 'Copy all';
  static const logsClear = 'Clear logs';
  static const logsCopied = 'Logs copied to clipboard';
  static const logsClearTitle = 'Clear logs?';
  static const logsClearBody = 'This permanently removes all captured logs.';
  static const logsPinTitle = 'Enter PIN';
  static const logsPinBody =
      'Diagnostic logs are protected. Enter the PIN to continue.';
  static const logsPinLabel = 'PIN';
  static const logsPinUnlock = 'Unlock';
  static const logsPinWrong = 'Incorrect PIN.';
  static const logsPinNotConfigured = 'Diagnostic logs are not available.';
  static const logsAccessLocked =
      'Too many attempts. Try again in a few minutes.';

  // Dashboard
  static const dashboardTitle = 'Home';
  static const goodMorning = 'Good morning';
  static const goodAfternoon = 'Good afternoon';
  static const goodEvening = 'Good evening';
  static const needsAttention = 'Needs attention';
  static const todayOverview = 'Today';
  static const viewAll = 'View all';
  static const allClear = 'All clear — nothing needs attention right now.';
  static const noOpenPlans = 'No open plans';
  static const setupChecklistTitle = 'Get started';
  static const setupChecklistHint = 'Complete these to set up your home';
  static const hideChecklist = 'Hide checklist';
  static const checklistPantry = 'Add 3 pantry items';
  static const checklistFamily = 'Add a family member';
  static const checklistPlan = 'Create your first plan';
  static const checklistExpense = 'Log an expense';
  static const optional = 'Optional';
  static String addedBy(String name) => 'Added by $name';
  static const quickActions = 'Quick actions';
  static const quickActionPlan = 'Plan';
  static const quickActionPantry = 'Pantry';
  static const quickActionPantryHint = 'Track stock at home';
  static const quickActionShop = 'Shop';
  static const quickActionExpense = 'Expense';
  static const quickActionExpenseHint = 'Log money spent';
  static const quickActionRecipe = 'Recipe';
  static const quickActionSubscription = 'Subscription';
  static const expiringSoon = 'Expiring soon';
  static const noExpiring = 'Nothing expiring soon';
  static const cookAndDeduct = 'Cook & update pantry';
  static const cookCheckResults = 'Ingredient check';
  static const forgotPassword = 'Forgot password?';
  static const resetPassword = 'Reset password';
  static const resetPasswordSent = 'Check your email for a reset link';
  static const restockOnBuy = 'Restock pantry when bought';
  static const itemDeleted = 'Item deleted';
  static const recipeDeleted = 'Recipe deleted';
}
