import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:myplanr/features/assets/data/asset_repository.dart';
import 'package:myplanr/features/expenses/data/expense_repository.dart';
import 'package:myplanr/features/home/data/setup_checklist_provider.dart';
import 'package:myplanr/features/household/data/household_repository.dart';
import 'package:myplanr/features/household/data/household_settings_repository.dart';
import 'package:myplanr/features/household/data/medicine_dose_tracker.dart';
import 'package:myplanr/features/household/data/medicine_schedule_repository.dart';
import 'package:myplanr/features/pantry/data/pantry_repository.dart';
import 'package:myplanr/features/plans/data/plan_repository.dart';
import 'package:myplanr/features/settings/data/device_permissions.dart';
import 'package:myplanr/features/subscriptions/data/subscription_repository.dart';
import 'package:myplanr/shared/constants/household_modules.dart';
import 'package:myplanr/shared/models/expense.dart';
import 'package:myplanr/shared/models/household.dart';

import 'provider_overrides.dart';
import 'test_fixtures.dart';

List<Override> dashboardTestOverrides() => [
      ...testAuthOverrides,
      enabledModulesProvider.overrideWithValue(
        HouseholdModules.sanitizeEnabled(HouseholdModules.defaultEnabled),
      ),
      activeHouseholdProvider.overrideWith((ref) async => testHousehold),
      setupChecklistDismissedProvider.overrideWith((ref) async => true),
      setupChecklistProvider.overrideWith((ref) async => null),
      deviceReminderBlockersProvider.overrideWith((ref) async => []),
      expenseSummaryProvider.overrideWith((ref) async => testExpenseSummaryRows),
      moneySummaryProvider.overrideWith((ref) async => testMoneySummary),
      lowStockItemsProvider.overrideWith((ref) async => []),
      expiringItemsProvider.overrideWith((ref) async => []),
      warrantyExpiringAssetsProvider.overrideWith((ref) async => []),
      subscriptionsDueSoonProvider.overrideWith((ref) async => []),
      openPlansOverviewProvider.overrideWith(
        (ref) async => OpenPlansOverview(totalCount: 0, preview: []),
      ),
      todayMealPlansProvider.overrideWith((ref) async => []),
      medicineRemindersTodayProvider.overrideWith((ref) async => []),
      medicineDosesTakenTodayProvider.overrideWith((ref) async => {}),
    ];
