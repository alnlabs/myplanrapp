import 'package:flutter_test/flutter_test.dart';
import 'package:myplanr/features/household/data/medicine_dose_tracker.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('MedicineDoseTracker', () {
    late MedicineDoseTracker tracker;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      tracker = MedicineDoseTracker(prefs);
    });

    test('doseKey includes schedule, index, and date', () {
      final key = MedicineDoseTracker.doseKey('sched-1', 0);
      expect(key, startsWith('medicine_taken_'));
      expect(key, endsWith('sched-1_0'));
    });

    test('setTaken and isTaken round trip', () async {
      expect(tracker.isTaken('sched-1', 1), isFalse);
      await tracker.setTaken('sched-1', 1, true);
      expect(tracker.isTaken('sched-1', 1), isTrue);
      await tracker.setTaken('sched-1', 1, false);
      expect(tracker.isTaken('sched-1', 1), isFalse);
    });

    test('getTakenKeys returns only today taken doses', () async {
      await tracker.setTaken('sched-1', 0, true);
      await tracker.setTaken('sched-2', 1, true);
      final keys = tracker.getTakenKeys();
      expect(keys, hasLength(2));
      expect(keys.every((k) => k.contains('sched-')), isTrue);
    });
  });
}
