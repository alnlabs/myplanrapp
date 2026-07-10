/// Household feature modules and onboarding interest mapping.
class HouseholdModules {
  HouseholdModules._();

  static const pantry = 'pantry';
  static const shopping = 'shopping';
  static const expenses = 'expenses';
  static const plans = 'plans';
  static const assets = 'assets';
  static const memberDetails = 'member_details';
  static const subscriptions = 'subscriptions';
  static const reminders = 'reminders';

  /// Deprecated module id kept only to strip from stored household settings.
  static const recipes = 'recipes';

  static const defaultEnabled = [
    pantry,
    shopping,
    expenses,
    plans,
    assets,
    memberDetails,
    reminders,
  ];

  static const activeModules = defaultEnabled;

  /// Drops deprecated module ids (e.g. removed [recipes]) from stored settings.
  static Set<String> sanitizeEnabled(Iterable<String> modules) {
    return modules.where(activeModules.contains).toSet();
  }
}

class HouseholdInterests {
  HouseholdInterests._();

  static const groceries = 'groceries';
  static const meals = 'meals_cooking';
  static const expenses = 'expenses';
  static const plans = 'plans_reminders';
  static const assets = 'home_assets';
  static const familyHealth = 'family_health';
  static const bills = 'bills_subscriptions';

  static const all = [
    (id: groceries, label: 'Groceries & pantry', icon: '🥫'),
    (id: meals, label: 'Meals & cooking', icon: '🍳'),
    (id: expenses, label: 'Household expenses', icon: '💰'),
    (id: plans, label: 'Plans & reminders', icon: '📅'),
    (id: assets, label: 'Home items & warranty', icon: '📺'),
    (id: familyHealth, label: 'Family health & details', icon: '❤️'),
    (id: bills, label: 'Bills & subscriptions', icon: '📱'),
  ];

  static Set<String> modulesFromInterests(Set<String> interestIds) {
    final modules = <String>{};
    for (final id in interestIds) {
      modules.addAll(_interestModules[id] ?? const []);
    }
    if (modules.isEmpty) {
      return HouseholdModules.defaultEnabled.toSet();
    }
    return modules;
  }

  static const _interestModules = <String, List<String>>{
    groceries: [HouseholdModules.pantry, HouseholdModules.shopping],
    meals: [HouseholdModules.plans, HouseholdModules.pantry],
    expenses: [HouseholdModules.expenses],
    plans: [HouseholdModules.plans, HouseholdModules.reminders],
    assets: [HouseholdModules.assets],
    familyHealth: [HouseholdModules.memberDetails, HouseholdModules.reminders],
    bills: [
      HouseholdModules.subscriptions,
      HouseholdModules.expenses,
      HouseholdModules.reminders,
    ],
  };
}
