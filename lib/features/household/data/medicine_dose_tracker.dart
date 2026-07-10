import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Tracks medicine doses marked as taken for the current day (per device).
class MedicineDoseTracker {
  MedicineDoseTracker(this._prefs);

  final SharedPreferences _prefs;

  static String doseKey(String scheduleId, int timeIndex) {
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    return 'medicine_taken_${today}_${scheduleId}_$timeIndex';
  }

  Set<String> getTakenKeys() {
    final prefix =
        'medicine_taken_${DateFormat('yyyy-MM-dd').format(DateTime.now())}_';
    return _prefs
        .getKeys()
        .where((k) => k.startsWith(prefix) && (_prefs.getBool(k) ?? false))
        .toSet();
  }

  bool isTaken(String scheduleId, int timeIndex) {
    return _prefs.getBool(doseKey(scheduleId, timeIndex)) ?? false;
  }

  Future<void> setTaken(String scheduleId, int timeIndex, bool taken) async {
    final key = doseKey(scheduleId, timeIndex);
    if (taken) {
      await _prefs.setBool(key, true);
    } else {
      await _prefs.remove(key);
    }
  }
}

Future<MedicineDoseTracker> _loadTracker() async {
  final prefs = await SharedPreferences.getInstance();
  return MedicineDoseTracker(prefs);
}

final medicineDosesTakenTodayProvider = FutureProvider<Set<String>>((ref) async {
  final tracker = await _loadTracker();
  return tracker.getTakenKeys();
});

Future<void> markMedicineDoseTaken(
  WidgetRef ref, {
  required String scheduleId,
  required int timeIndex,
  required bool taken,
}) async {
  final tracker = await _loadTracker();
  await tracker.setTaken(scheduleId, timeIndex, taken);
  ref.invalidate(medicineDosesTakenTodayProvider);
}
