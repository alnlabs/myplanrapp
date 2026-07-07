abstract final class AppStrings {
  static const appName = 'MyPlanr';

  // Nav
  static const navHome = 'Home';
  static const navPantry = 'Pantry';
  static const navRecipes = 'Recipes';
  static const navExpenses = 'Expenses';
  static const navShop = 'Shop';
  static const navMore = 'More';

  // Pantry
  static const pantryTitle = 'Pantry';
  static const addItem = 'Add item';
  static const editItem = 'Edit item';
  static const itemName = 'Item name';
  static const quantity = 'Quantity';
  static const unit = 'Unit';
  static const lowStockAlert = 'Low stock alert at';
  static const category = 'Category';
  static const expiryDate = 'Expiry date';
  static const useItem = 'Use';
  static const restockItem = 'Restock';
  static const stockHistory = 'History';
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
  static const linkToPantry = 'Also add to pantry';
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

  // Household & auth
  static const householdTitle = 'Family';
  static const createHousehold = 'Create family';
  static const joinHousehold = 'Join family';
  static const householdName = 'Family name';
  static const inviteMember = 'Invite by email';
  static const members = 'Members';
  static const pendingInvites = 'Pending invites';
  static const leaveHousehold = 'Leave family';
  static const removeMember = 'Remove member';
  static const signIn = 'Sign in';
  static const signUp = 'Create account';
  static const signOut = 'Sign out';
  static const email = 'Email';
  static const password = 'Password';
  static const displayName = 'Display name';
  static const profileTitle = 'Profile';
  static const noHousehold = 'Join or create a family to get started';

  // Onboarding
  static const onboardingTitle = 'Welcome to MyPlanr';
  static const onboardingSubtitle =
      'Track pantry stock, plan meals, manage expenses, and shop smarter — together as a family.';
  static const getStarted = 'Get started';

  // Common
  static const save = 'Save';
  static const cancel = 'Cancel';
  static const delete = 'Delete';
  static const retry = 'Try again';
  static const loading = 'Loading…';
  static const search = 'Search';
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

  // Dashboard
  static const dashboardTitle = 'Home';
  static const quickActions = 'Quick actions';
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
