abstract final class AppStrings {
  static const appName = 'MyPlanr';

  // Nav
  static const navHome = 'Home';
  static const navPantry = 'Pantry';
  static const navInventory = 'Pantry';
  static const navPlans = 'Plans';
  static const navExpenses = 'Expenses';
  static const navShop = 'Shop';
  static const navMore = 'More';
  static const moreSubtitle = 'Family, settings, and more features';
  static const moreFeatureOverflowHint = 'Open feature';
  static const moreSectionFeatures = 'Features';
  static const moreSectionMoney = 'Money';
  static const moreSectionHousehold = 'Home & family';
  static const moreSectionApp = 'App';
  static const moreInventoryHint = 'Pantry stock and home items';
  static const morePlansHint = 'Tasks, meals, and reminders';
  static const moreExpensesHint = 'Track household spending';
  static const moreShopHint = 'Shared shopping list';
  static const moreSubscriptionsHint = 'Recurring bills and services';
  static const moreFamilyHint = 'Family roster and feature settings';
  static const moreSettingsHint = 'Account, appearance, and app preferences';
  static const settingsTitle = 'Settings';
  static const settingsSubtitle = 'Account, appearance, and app preferences';
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
  static const settingsRequestNotificationPermission =
      'Allow reminders on this device';
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
  static const deviceAlertsDisabled = 'Device alerts are off';
  static const deviceAlertsNotificationsHint =
      'Turn on notifications so plan, bill, and medicine reminders reach this phone.';
  static const deviceAlertsExactAlarmHint =
      'Allow alarms & reminders in system settings for on-time alerts.';
  static const deviceAlertsFix = 'Fix';
  static const settingsTestNotification = 'Send test alert';
  static const settingsTestNotificationHint =
      'Check that reminders appear on this device';
  static const settingsTestNotificationSent =
      'Test alert sent — check your notification shade';
  static const notificationSoundsTitle = 'Alert sounds';
  static const notificationSoundsHint =
      'Choose a different device notification tone for each alert type. '
      'A short preview plays after you pick a sound.';
  static const notificationSoundsEntry = 'Alert sounds';
  static const notificationSoundsEntryHint =
      'Pick device notification tones per alert type (Android)';
  static const notificationSoundDeviceDefault = 'Device default';
  static const notificationSoundSaved = 'Alert sound updated';
  static const notificationSoundReset = 'Reset to device default';
  static const notificationSoundsSystemSettings =
      'Android notification settings';
  static const notificationSoundsSystemSettingsHint =
      'Fine-tune sounds and importance per channel in system settings';
  static const settingsDiagnosticLogs = 'Diagnostic logs';
  static const settingsDiagnosticLogsHint =
      'Recent app events for troubleshooting';
  static const appVersion = 'Version 1.0.0';
  static const builtAndMaintainedBy = 'Built and maintained by alnlabs.com';
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
  static const viewGrid = 'Grid view';
  static const viewList = 'List view';
  static const pantryViewGrid = viewGrid;
  static const pantryViewList = viewList;
  static const inventoryTitle = 'Pantry';
  static const inventorySubtitle = 'Food stock and home assets';
  static const segmentAll = 'All';
  static const segmentFood = 'Kitchen';
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
  static const allCategories = 'All';
  static const expiryDate = 'Expiry date';
  static const useItem = 'Use';
  static const restockItem = 'Restock';
  static const available = 'Available';
  static const remaining = 'Remaining';
  static const useAll = 'Use all';
  static const nothingToUse = 'Nothing left to use';
  static const stepsOf = 'Adjusts in steps of';
  static const restockHowMuch = 'How much did you restock?';
  static const restockAddToPantry = 'Add to pantry';
  static const restockSkip = 'Just mark bought';
  static const restockedFromShop = 'Bought';
  static const stockHistory = 'History';
  static const emptyStockHistory = 'No history yet';
  static const emptyPantry = 'No items yet';
  static const emptyPantryHint =
      'Add groceries and home essentials to track stock';
  static const outOfStock = 'Out of stock';
  static const lowStock = 'Low stock';
  static const availabilitySection = 'How much is left?';
  static const availabilityFine = 'Fine';
  static const availabilityAuto = 'Track by amount';
  static const availabilityWarning = 'Running low';
  static const availabilityRequired = 'Need soon';
  static const availabilityEmergency = 'Empty';
  static const availabilityHint =
      'Update when an item is running low — no need to count every time.';
  static const availabilityChange = 'Change';
  static const lowStockAlertOptionalHint =
      'Optional — only if you track exact amounts';
  static const pantryTrackingRequired =
      'Add a quantity or choose how much is left';
  static const availabilityUpdated = 'Availability updated';
  static const clearAvailabilityOnRestock = 'Mark as fine after restock';
  static const statusSufficient = 'Enough in pantry';
  static const statusInsufficient = 'Not enough';
  static const statusMissing = 'Not in pantry';
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
  static const emptyAlertsHint = 'Items below your alert level will show here';
  static const addToShopList = 'Add to shop list';

  // Expenses
  static const expensesTitle = 'Expenses';
  static const expensesSubtitle = 'Track household spending';
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
  static const addIncome = 'Add income';
  static const editIncome = 'Edit income';
  static const incomeMember = 'Family member';
  static const incomeMemberRequired = 'Select who received this income';
  static const incomeSource = 'Income source';
  static const incomeSourceHint = 'e.g. ACME Corp salary, Upwork, rental flat';
  static const incomeCategory = 'Income category';
  static const incomeDate = 'Date received';
  static const filterAllMoney = 'All';
  static const filterExpensesOnly = 'Expenses';
  static const filterIncomeOnly = 'Income';
  static const filterByMember = 'Member';
  static const moneySpent = 'Spent';
  static const moneyEarned = 'Earned';
  static const moneyNet = 'Net';
  static const earnedByMember = 'Earned by member';
  static const moneyPeriodLabel = 'Period';
  static const transactionsTitle = 'Transactions';
  static const filterList = 'Filter';
  static const clearFilters = 'Clear';
  static const doneLabel = 'Done';
  static const moreActions = 'More';
  static const exportReport = 'Export report';
  static const reportCopied = 'Report copied to clipboard';
  static const emptyIncome = 'No income logged yet';
  static const memberIncomeTitle = 'Income this month';
  static const memberIncomeSources = 'Income by source';
  static const logIncome = 'Log income';
  static const recurringIncome = 'Recurring income';
  static const addRecurringIncome = 'Add recurring income';
  static const nextDue = 'Next due';
  static const recurringIncomeDue = 'Recurring income due';
  static const logRecurringIncome = 'Log income now';
  static const frequencyMonthly = 'Monthly';
  static const frequencyWeekly = 'Weekly';
  static const frequencyYearly = 'Yearly';
  static const frequencyLabel = 'Frequency';
  static const dayOfMonthLabel = 'Day of month';
  static const recurringIncomeToggle = 'Repeat this income automatically';
  static const recurringIncomeToggleHint =
      'We\'ll set up a recurring income so you don\'t have to add it again';
  static const incomeForLabel = 'Income for';
  static const pauseRecurring = 'Pause';
  static const resumeRecurring = 'Resume';
  static const periodToday = 'Today';
  static const periodThisWeek = 'This week';
  static const periodThisMonth = 'This month';
  static const periodCustom = 'Custom';
  static const periodCustomRange = 'Custom range';
  static const periodCustomInvalid = 'Choose a valid date range (max 366 days)';
  static const emptyExport = 'Nothing to export in this period';
  static const shareReport = 'Share report';
  static const copyReport = 'Copy to clipboard';
  static const expenseGroupsTitle = 'Expense groups';
  static const addExpenseGroup = 'Add group';
  static const groupName = 'Group name';
  static const groupType = 'Group type';
  static const groupTypeOrganizational = 'Tracking only';
  static const groupTypeShared = 'Shared expenses';
  static const groupMembers = 'Members';
  static const addGuestMember = 'Add guest';
  static const guestName = 'Guest name';
  static const guestEmailOptional = 'Guest email (optional)';
  static const expenseGroup = 'Group';
  static const noGroup = 'Household (no group)';
  static const paidByMember = 'Paid by';
  static const splitType = 'Split type';
  static const splitEqual = 'Equal';
  static const splitExact = 'Exact amounts';
  static const splitPercent = 'Percent';
  static const participants = 'Participants';
  static const settlements = 'Settlements';
  static const recordSettlement = 'Record settlement';
  static const suggestedSettlements = 'Suggested transfers';
  static const netBalance = 'Net balance';
  static const owesYou = 'owes you';
  static const youOwe = 'you owe';
  static const emptyExpenseGroups = 'No expense groups yet';
  static const emptyExpenseGroupsHint =
      'Create groups to track shared trips, roommates, or categories';
  static const settlementFrom = 'From';
  static const settlementTo = 'To';
  static const sharedGroupMinMembers = 'Shared groups need at least 2 members';
  static const splitSumMismatch = 'Split amounts must equal the expense total';
  static const recurringExpenses = 'Recurring expenses';
  static const addRecurringExpense = 'Add recurring expense';
  static const recurringExpenseDue = 'Recurring expense due';
  static const logRecurringExpense = 'Log expense now';
  static const skipRecurring = 'Skip this time';
  static const snoozeRecurring = 'Snooze 1 week';
  static const autoLogExpense = 'Auto-log on due date';
  static const logPaymentAsExpense = 'Log payment as expense';
  static const linkedSubscription = 'Linked subscription';
  static const emptyRecurringExpenses = 'No recurring expenses yet';
  static const emptyRecurringExpensesHint =
      'Automate rent, groceries, or bills you log often';
  static const recurringLogged = 'Recurring expense logged';

  // Categories
  static const categoryGroceries = 'Groceries';
  static const categoryUtilities = 'Utilities';
  static const categoryRent = 'Rent';
  static const categoryTransport = 'Transport';
  static const categoryMedical = 'Medical';
  static const categoryEntertainment = 'Entertainment';
  static const categoryOther = 'Other';

  // Shopping
  static const shopTitle = 'Shop list';
  static const shopSubtitle = 'Shared shopping list';
  static const addToShop = 'Add to list';
  static const markBought = 'Mark as bought';
  static const emptyShop = 'Shop list is empty';
  static const emptyShopHint =
      'Low-stock pantry items are added here automatically';
  static const sourceLowStock = 'Low stock';
  static const sourceMealPlan = 'Meal plan';
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
  static const householdSubtitle = 'Family roster and feature settings';
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
  static const inviteToAppHint =
      'They will get an email invite to join on their phone.';
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
  static const inviteToAppEmailHint =
      'Enter their email to send an app invite.';
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
  static const me = 'Me';
  static const emptyFamilyRoster = 'No family members yet.';
  static const emptyFamilyRosterHint =
      'Add people you manage or invite them to use the app.';
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
  static const medicineFor = 'What is it for?';
  static const medicineForHint = 'e.g. Blood pressure, Diabetes, Vitamin D';
  static const medicineForOther = 'Specify condition';
  static const medicineBrandOptional = 'Brand or formula name (optional)';
  static const medicineBrandHint = 'e.g. Telmisartan, Crocin';
  static const medicineForRequired =
      'Choose or enter what this medicine is for';
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
  static const rememberMe = 'Remember me on this device';
  static const signUp = 'Create account';
  static const signOut = 'Sign out';
  static const signOutConfirmTitle = 'Sign out?';
  static const signOutConfirmBody =
      'You will need to sign in again to access your household.';
  static const email = 'Email';
  static const password = 'Password';
  static const confirmPassword = 'Confirm password';
  static const passwordsDoNotMatch = 'Passwords do not match';
  static const showPassword = 'Show password';
  static const hidePassword = 'Hide password';
  static const displayName = 'Display name';
  static const username = 'Username';
  static const usernameHint =
      'Used to sign in. Letters, numbers, dot or underscore.';
  static const emailOrUsername = 'Email or username';
  static const signUpVerifyEmail =
      'Account created. Check your email to confirm, then sign in.';
  static const profileTitle = 'Profile';
  static const accountInfo = 'Account';
  static const editProfile = 'Edit profile';
  static const editDetails = 'Edit details';
  static const sectionContact = 'Contact';
  static const sectionWorkSchool = 'Work & school';
  static const profileEmptyHint =
      'No details added yet. Tap Edit to add contact, health and emergency info.';
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
  static const onboardingSlide1Body =
      'Run your home together — one app for your whole family.';
  static const onboardingSlide2Title = 'Track what you have';
  static const onboardingSlide2Body =
      'Pantry stock, home assets, and warranty dates — know what is at home.';
  static const onboardingSlide3Title = 'Plan and remind';
  static const onboardingSlide3Body =
      'Tasks, meals, medicine, and shopping — for you and family members.';
  static const onboardingSlide4Title = 'Ready?';
  static const onboardingSlide4Body =
      'Create an account or sign in to get started.';
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
  static const interestsHint =
      'Pick at least one. You can change this later in Family settings.';
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
  static const plansSubtitle = 'Tasks, meals, and reminders';
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
  static const reminderNotesHint = 'Extra details shown with this reminder';
  static const emptyReminders = 'No reminders yet';
  static const emptyRemindersHint =
      'Create a reminder or enable them on plans, bills, and medicine schedules.';
  static const reminderSourcePlan = 'Plan';
  static const reminderSourceSubscription = 'Subscription';
  static const reminderSourceMedicine = 'Medicine';
  static const reminderSourceStandalone = 'Custom';
  static const reminderRepeatingDaily = 'Repeats daily';
  static const reminderRepeatLabel = 'Repeat';
  static const reminderRepeatHint = 'How often this reminder should repeat';
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
  static const filterTodos = 'To-do';
  static const filterReminders = 'Reminders';
  static const filterMedicine = 'Medicine';
  static const filterSubscriptions = 'Subscriptions';
  static const filterCustomReminders = 'Custom';
  static const otherRemindersSection = 'Other reminders';
  static const emptyTodoRemindersAll =
      'Nothing here yet. Add a to-do item or reminder.';
  static const emptyFilteredTodos = 'No to-do items match this filter.';
  static const emptyFilteredReminders = 'No reminders match this filter.';

  // Assets (home items — TVs, furniture, appliances, etc.)
  static const assetsTitle = 'Home items';
  static const addAsset = 'Add home item';
  static const editAsset = 'Edit home item';
  static const assetName = 'Name';
  static const assetNameHint = 'e.g. Samsung TV, Dining table';
  static const assetCategory = 'Category';
  static const assetCategoryHint = 'Electronics, furniture, appliances…';
  static const assetKind = 'Ownership';
  static const assetKindHint = 'How long you expect to keep this item';
  static const assetLocation = 'Where is it?';
  static const assetLocationHint = 'e.g. Living room, Garage';
  static const purchaseInfo = 'Purchase details';
  static const whereBought = 'Store or seller';
  static const purchaseDate = 'Purchase date';
  static const purchaseAmount = 'Amount paid';
  static const warranty = 'Warranty';
  static const warrantyProvider = 'Brand or service company';
  static const warrantyStart = 'Coverage starts';
  static const warrantyEnd = 'Coverage ends';
  static const warrantyNotes = 'Warranty notes (optional)';
  static const warrantyValid = 'Warranty valid';
  static const warrantyExpiring = 'Warranty expiring';
  static const warrantyExpired = 'Warranty expired';
  static const warrantyExpiringTitle = 'Warranty expiring';
  static const emptyAssets = 'No home items yet';
  static const emptyAssetsHint =
      'Add TVs, appliances, furniture, and track warranty dates.';
  static String homeItemCount(int count) =>
      count == 1 ? '1 home item' : '$count home items';
  static const repairHistory = 'Repair history';
  static const noRepairHistory = 'No repairs logged yet';
  static const logRepair = 'Log repair';
  static const serviceType = 'Service type';
  static const serviceDate = 'Service date';
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
  static const subscriptionsSubtitle = 'Recurring bills and services';
  static const addSubscription = 'Add subscription';
  static const editSubscription = 'Edit subscription';
  static const deleteSubscription = 'Delete subscription?';
  static const subscriptionName = 'Name';
  static const subscriptionAmount = 'Amount';
  static const paymentMethod = 'Payment method';
  static const paymentMethodHint = 'How this bill is usually paid';
  static const paymentMethodNotSet = 'Not set';
  static const paymentDetail = 'Payment details';
  static const paymentInfo = 'Payment';
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
  static const feedbackSubtitle = 'Request features or report issues';
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

  // Admin
  static const adminTitle = 'Admin';
  static const moreAdminHint = 'Review feedback and app issues';
  static const adminOtpTitle = 'Admin verification';
  static const adminOtpBody =
      'For security, admin access requires a one-time code. '
      'We sent a 6-digit code to your account email.';
  static const adminOtpSentTo = 'Code sent to';
  static const adminOtpCodeLabel = 'Enter 6-digit code';
  static const adminOtpVerify = 'Verify & continue';
  static const adminOtpResend = 'Resend code';
  static const adminOtpSending = 'Sending code…';
  static const adminOtpResent = 'A new code has been sent.';
  static const adminOtpInvalid = 'That code is invalid or expired.';
  static const adminOtpNeedsCode = 'Enter the 6-digit code.';
  static const adminSectionFeedback = 'Feedback';
  static const adminSectionErrors = 'Issues';
  static const adminNoFeedback = 'No feedback yet.';
  static const adminNoErrors = 'No issues reported.';
  static const adminUnknownReporter = 'Unknown user';
  static const adminAnonymous = 'Anonymous';
  static const adminClearAll = 'Clear all';
  static const adminGroupToday = 'Today';
  static const adminGroupYesterday = 'Yesterday';
  static const adminDeleteTitle = 'Delete?';
  static const adminDeleteItemConfirm =
      'Delete this entry? This cannot be undone.';
  static const adminDeleteGroupConfirm =
      "Delete all entries from this day? This can't be undone.";
  static const adminDeleteAllConfirm =
      "Delete every entry in this list? This can't be undone.";
  static const adminDeleted = 'Deleted';
  static const adminDeleteFailed = 'Could not delete. Please try again.';

  // Common
  static const save = 'Save';
  static const cancel = 'Cancel';
  static const close = 'Close';
  static const add = 'Add';
  static const selectAll = 'Select all';
  static const deselectAll = 'Deselect all';
  static String selectedCount(int n) => '$n selected';
  static const deleteSelectedTitle = 'Delete selected?';
  static String deleteSelectedMessage(int n) =>
      n == 1 ? 'Delete this item? This cannot be undone.'
             : 'Delete these $n items? This cannot be undone.';
  static String itemsDeleted(int n) => n == 1 ? '1 deleted' : '$n deleted';
  static const edit = 'Edit';
  static const delete = 'Delete';
  static const retry = 'Try again';
  static const loading = 'Loading…';
  static const search = 'Search';
  static const filter = 'Filter';
  static const errorGeneric = 'Something went wrong. Please try again.';
  static const errorNetwork = 'No internet connection';
  static const errorTimeout = 'Request timed out. Please try again.';
  static const confirmDelete = 'Are you sure you want to delete this?';
  static const requiredField = 'This field is required';
  static const selectCategory = 'Please select a category';
  static const notSet = 'Not set';
  static const tapToSetDateTime = 'Tap to set date and time';
  static const pickReminderDateTime = 'Pick a reminder date and time';
  static const categoriesLoadError = 'Could not load categories';
  static const rosterLoadError = 'Could not load family members';
  static const invalidEmail = 'Enter a valid email address';
  static const usernameTooShort = 'Username must be at least 3 characters';
  static const usernameInvalidChars =
      'Use only letters, numbers, dot, or underscore';
  static const passwordTooShort = 'Password must be at least 6 characters';
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
  static const needsAttention = 'Needs your attention';
  static const medicineMarkTaken = 'Taken';
  static const medicineMarkedTaken = 'Marked as taken';
  static const shareShopList = 'Share shop list';
  static const shareViaWhatsApp = 'Share on WhatsApp';
  static const copyToClipboard = 'Copy to clipboard';
  static const shopListCopied = 'Shop list copied';
  static const shopListShareFailed = 'Could not open WhatsApp';
  static String shopListShareTitle(int count) =>
      'MyPlanr — Shop list ($count item${count == 1 ? '' : 's'})';
  static const todayOverview = 'Today';
  static const todayEatPlan = "Today's eat plan";
  static const mealSlotBreakfast = 'Breakfast';
  static const mealSlotLunch = 'Lunch';
  static const mealSlotDinner = 'Dinner';
  static const mealSlotSnack = 'Snack';
  static const mealSlot = 'Meal time';
  static const mealNotPlanned = 'Not planned';
  static const mealSlotRequired = 'Pick breakfast, lunch, or dinner';
  static const mealUnassigned = 'Unassigned meals today';
  static const viewAll = 'View all';
  static const allClear = 'All clear — nothing needs attention right now.';
  static const attentionAllSetTitle = 'All clear';
  static const attentionAllSetSubtitle =
      'Pantry, bills, and warranties look good.';
  static String attentionMore(int count) => '+ $count more';
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
  static const quickActionMeal = 'Meal';
  static const quickActionSubscription = 'Subscription';
  static const expiringSoon = 'Expiring soon';
  static const noExpiring = 'Nothing expiring soon';
  static const forgotPassword = 'Forgot password?';
  static const resetPassword = 'Reset password';
  static const resetPasswordSent = 'Check your email for a reset link';
  static const resetSendCode = 'Send code';
  static const resetEmailHint =
      "Enter your account email and we'll send a 6-digit reset code.";
  static const resetOtpTitle = 'Enter reset code';
  static const resetOtpBody =
      'Enter the 6-digit code we emailed you, then choose a new password.';
  static const resetOtpSentTo = 'Code sent to';
  static const resetCodeLabel = '6-digit code';
  static const newPassword = 'New password';
  static const resetOtpNeedsCode = 'Enter the 6-digit code.';
  static const resetResendCode = 'Resend code';
  static const resetResending = 'Sending…';
  static const resetCodeResent = 'A new code has been sent.';
  static const resetInvalidCode = 'That code is invalid or expired.';
  static const resetPasswordUpdated =
      'Password updated. Please sign in with your new password.';
  static const resetPasswordCta = 'Update password';
  static const restockOnBuy = 'Restock pantry when bought';
  static const itemDeleted = 'Item deleted';

  // Receipt scanning assistant
  static const assistantTitle = 'Scan receipt';
  static const moreAssistantHint = 'Snap a receipt to add expenses and pantry';
  static const scanReceiptInstruction =
      'Take a photo or choose a receipt image. We will read it and suggest what to add.';
  static const scanReceiptTakePhoto = 'Take photo';
  static const scanReceiptFromGallery = 'Choose from gallery';
  static const scanReceiptAnalyzing = 'Reading your receipt…';
  static const receiptDuplicateTitle = 'Receipt already added';
  static const receiptDuplicateBody =
      'This receipt looks like one you already processed. Add it again anyway?';
  static const receiptProcessAnyway = 'Add anyway';
  static const receiptPreviewTitle = 'Review & apply';
  static const receiptExpenseSection = 'Expense';
  static const receiptItemsSection = 'Items';
  static const receiptNoItems = 'No items detected';
  static const receiptMerchant = 'Merchant';
  static const receiptAmount = 'Amount';
  static const receiptDate = 'Date';
  static const receiptStatusNew = 'New';
  static const receiptStatusRestock = 'Restock';
  static const receiptDestPantry = 'Pantry';
  static const receiptDestShopping = 'Shopping';
  static const receiptDestIgnore = 'Ignore';
  static const receiptApplyAll = 'Apply all';
  static const receiptActionCreate = 'Create';
  static const receiptActionRestock = 'Restock';
  static const receiptActionAddShop = 'Add to shop';
  static const receiptApplied = 'Applied';
  static const receiptExpenseCreate = 'Add expense';
  static const receiptExpenseAdded = 'Expense added';
  static const receiptApplyDone = 'Added from receipt';
  static const receiptApplyFailed = 'Could not apply. Please try again.';

  // Manual "bring your own AI" path: no server-side model call. The user runs
  // the prompt below in any AI app, then pastes the JSON result back in.
  static const receiptPasteTile = 'Paste from your own AI';
  static const receiptPasteHint =
      'Use ChatGPT, Gemini or any app — no scan limit';
  static const receiptPasteTitle = 'Paste receipt data';
  static const receiptPasteStep1 = '1. Copy this prompt';
  static const receiptPasteStep2 =
      '2. Paste it into any AI app with your receipt (text or photo)';
  static const receiptPasteStep3 = '3. Paste the AI\u2019s JSON reply below';
  static const receiptPasteCopyPrompt = 'Copy prompt';
  static const receiptPastePromptCopied = 'Prompt copied';
  static const receiptPasteInputLabel = 'AI reply (JSON)';
  static const receiptPasteInputHint = 'Paste the JSON here';
  static const receiptPasteReview = 'Review & apply';
  static const receiptPasteEmpty = 'Paste the AI reply first.';
  static const receiptPasteNoHousehold =
      'Join or create a household before adding a receipt.';

  // Saved / scanned receipts history.
  static const receiptsTitle = 'Scanned receipts';
  static const receiptsEmpty = 'No receipts yet. Scan or paste one to get started.';
  static const receiptsProcessed = 'Applied';
  static const receiptsPending = 'Draft';
  static const receiptsItemsCount = 'items';
  static const receiptsNoLines = 'No line items saved.';
  static const receiptsUnknownMerchant = 'Receipt';

  static const receiptPastePrompt =
      'You are a receipt parser. Read the receipt below (or the attached photo) '
      'and reply with ONLY a JSON object, no markdown, no explanation, in exactly '
      'this shape:\n'
      '{\n'
      '  "merchant": "store name or null",\n'
      '  "purchased_at": "YYYY-MM-DD or null",\n'
      '  "total": number or null,\n'
      '  "currency": "INR",\n'
      '  "items": [\n'
      '    {\n'
      '      "name": "short item name",\n'
      '      "qty": number or null,\n'
      '      "unit": "pcs | kg | g | l | ml | pack or null",\n'
      '      "unit_price": number or null,\n'
      '      "line_total": number or null,\n'
      '      "destination": "pantry | shopping | ignore"\n'
      '    }\n'
      '  ]\n'
      '}\n'
      'Rules: use "pantry" for groceries/consumables you keep at home, '
      '"shopping" for things still to buy, and "ignore" for taxes, discounts or '
      'totals. Numbers must be plain (no currency symbols). Reply with JSON only.\n\n'
      'Receipt:\n';
}
