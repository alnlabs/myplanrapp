import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../expenses/data/expense_repository.dart';
import '../../household/data/family_repository.dart';
import '../../pantry/data/pantry_repository.dart';
import '../../plans/data/plan_repository.dart';

const _dismissedKey = 'dashboard_checklist_dismissed';

class SetupChecklist {
  const SetupChecklist({
    required this.pantryCount,
    required this.hasFamilyMember,
    required this.hasPlan,
    required this.hasExpense,
  });

  final int pantryCount;
  final bool hasFamilyMember;
  final bool hasPlan;
  final bool hasExpense;

  bool get pantryDone => pantryCount >= 3;
  bool get familyDone => hasFamilyMember;
  bool get planDone => hasPlan;
  bool get expenseDone => hasExpense;

  bool get isComplete => pantryDone && familyDone && planDone;
}

final setupChecklistDismissedProvider = FutureProvider<bool>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool(_dismissedKey) ?? false;
});

Future<void> dismissSetupChecklist() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool(_dismissedKey, true);
}

final setupChecklistProvider = FutureProvider<SetupChecklist?>((ref) async {
  final dismissed = await ref.watch(setupChecklistDismissedProvider.future);
  if (dismissed) return null;

  final pantryCount = await ref.watch(pantryItemCountProvider.future);
  final roster = await ref.watch(familyRosterProvider.future);
  final hasPlan = await ref.watch(hasAnyPlanProvider.future);
  final hasExpense = await ref.watch(hasAnyExpenseProvider.future);

  final checklist = SetupChecklist(
    pantryCount: pantryCount,
    hasFamilyMember: roster.length > 1,
    hasPlan: hasPlan,
    hasExpense: hasExpense,
  );

  if (checklist.isComplete) {
    await dismissSetupChecklist();
    return null;
  }

  return checklist;
});
