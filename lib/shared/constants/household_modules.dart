/// Household feature modules and onboarding interest mapping.
class HouseholdModules {
  HouseholdModules._();

  static const pantry = 'pantry';
  static const shopping = 'shopping';
  static const expenses = 'expenses';
  static const plans = 'plans';
  static const recipes = 'recipes';
  static const assets = 'assets';
  static const memberDetails = 'member_details';
  static const subscriptions = 'subscriptions';

  static const defaultEnabled = [
    pantry,
    shopping,
    expenses,
    plans,
    recipes,
    assets,
    memberDetails,
  ];
}

class HouseholdInterests {
  HouseholdInterests._();

  static const groceries = 'groceries';
  static const recipes = 'recipes_cooking';
  static const expenses = 'expenses';
  static const plans = 'plans_reminders';
  static const assets = 'home_assets';
  static const familyHealth = 'family_health';
  static const bills = 'bills_subscriptions';

  static const all = [
    (id: groceries, label: 'Groceries & pantry', icon: '🥫'),
    (id: recipes, label: 'Recipes & cooking', icon: '🍳'),
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
    recipes: [HouseholdModules.recipes, HouseholdModules.pantry],
    expenses: [HouseholdModules.expenses],
    plans: [HouseholdModules.plans],
    assets: [HouseholdModules.assets],
    familyHealth: [HouseholdModules.memberDetails],
    bills: [HouseholdModules.subscriptions, HouseholdModules.expenses],
  };
}
