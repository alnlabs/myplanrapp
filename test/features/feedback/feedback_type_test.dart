import 'package:flutter_test/flutter_test.dart';
import 'package:myplanr/features/feedback/data/feedback_repository.dart';
import 'package:myplanr/shared/models/app_reminder_item.dart';

void main() {
  group('FeedbackTypeValue', () {
    test('maps enum to database values', () {
      expect(FeedbackType.feature.value, 'feature');
      expect(FeedbackType.bug.value, 'bug');
      expect(FeedbackType.other.value, 'other');
    });
  });

  group('AppReminderItem', () {
    test('isStandalone for standalone source', () {
      const item = AppReminderItem(
        id: 'standalone_1',
        sourceType: ReminderSourceType.standalone,
        sourceId: '1',
        title: 'Reminder',
      );
      expect(item.isStandalone, isTrue);
    });

    test('isStandalone false for other sources', () {
      const item = AppReminderItem(
        id: 'med_1',
        sourceType: ReminderSourceType.medicine,
        sourceId: '1',
        title: 'Medicine',
      );
      expect(item.isStandalone, isFalse);
    });
  });
}
