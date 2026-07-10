import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myplanr/core/strings/app_strings.dart';
import 'package:myplanr/features/plans/presentation/reminder_list_views.dart';
import 'package:myplanr/shared/models/app_reminder_item.dart';

import '../../helpers/pump_app.dart';

void main() {
  AppReminderItem item({
    required String id,
    DateTime? at,
    bool repeating = false,
  }) {
    return AppReminderItem(
      id: id,
      sourceType: ReminderSourceType.plan,
      sourceId: 'plan-$id',
      title: 'Task $id',
      reminderAt: at,
      isRepeating: repeating,
    );
  }

  group('ReminderListSections widget', () {
    testWidgets('renders grouped section headers', (tester) async {
      final today = DateTime.now();
      final todayAt = DateTime(today.year, today.month, today.day, 10);
      await pumpTestApp(
        tester,
        child: ReminderListSections(
          items: [
            item(id: '1', at: todayAt.subtract(const Duration(days: 1))),
            item(id: '2', at: todayAt),
          ],
          onEdit: (_) {},
          onDelete: (_) {},
        ),
      );

      expect(find.text(AppStrings.remindersSectionOverdue), findsOneWidget);
      expect(find.text(AppStrings.remindersSectionToday), findsOneWidget);
      expect(find.text('Task 1'), findsOneWidget);
      expect(find.text('Task 2'), findsOneWidget);
    });

    testWidgets('returns shrink when items list is empty', (tester) async {
      await pumpTestApp(
        tester,
        child: ReminderListSections(
          items: const [],
          onEdit: (_) {},
          onDelete: (_) {},
        ),
      );

      expect(find.byType(ReminderListSections), findsOneWidget);
      expect(find.text(AppStrings.remindersSectionOverdue), findsNothing);
    });
  });

  group('reminderSourceLabel', () {
    test('maps all source types', () {
      expect(
        reminderSourceLabel(ReminderSourceType.medicine),
        AppStrings.reminderSourceMedicine,
      );
      expect(
        reminderSourceLabel(ReminderSourceType.subscription),
        AppStrings.reminderSourceSubscription,
      );
    });
  });
}
