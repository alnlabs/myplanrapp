import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/providers/supabase_providers.dart';
import '../../../shared/models/medicine_schedule.dart';
import '../../../shared/utils/schedule_time_parser.dart';
import '../../alerts/services/notification_service.dart';
import '../../auth/data/auth_repository.dart';

class MedicineReminderToday {
  const MedicineReminderToday({
    required this.scheduleId,
    required this.timeIndex,
    required this.displayTitle,
    required this.memberName,
    required this.timeLabel,
    this.dosage,
  });

  final String scheduleId;
  final int timeIndex;
  final String displayTitle;
  final String memberName;
  final String timeLabel;
  final String? dosage;
}

class MedicineScheduleRepository {
  MedicineScheduleRepository(this._client);

  final SupabaseClient _client;

  static const _select = '''
    *,
    household_family_members(display_name)
  ''';

  Future<List<MedicineSchedule>> fetchSchedules(String familyMemberId) async {
    final data = await _client.rpc(
      'get_medicine_schedules_for_viewer',
      params: {'p_family_member_id': familyMemberId},
    );
    if (data == null) return [];
    return (data as List)
        .map((e) => MedicineSchedule.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<MedicineSchedule>> fetchSchedulesForReminders(
    String householdId,
  ) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return [];

    final data = await _client
        .from('member_medicine_schedules')
        .select(_select)
        .eq('household_id', householdId)
        .eq('is_active', true)
        .or('reminder_notify_user_id.eq.$userId,reminder_notify_user_id.is.null');
    return (data as List)
        .map((e) => MedicineSchedule.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<MedicineReminderToday>> fetchTodayReminders(
    String householdId,
  ) async {
    final schedules = await fetchSchedulesForReminders(householdId);
    final items = <MedicineReminderToday>[];

    for (final schedule in schedules) {
      final memberName = schedule.memberDisplayName ?? 'Family member';
      for (var i = 0; i < schedule.timesPerDay.length; i++) {
        final rawTime = schedule.timesPerDay[i];
        final parsed = parseScheduleTime(rawTime);
        if (parsed == null) continue;
        items.add(
          MedicineReminderToday(
            scheduleId: schedule.id,
            timeIndex: i,
            displayTitle: schedule.displayTitle,
            memberName: memberName,
            timeLabel: formatScheduleTime(parsed),
            dosage: schedule.dosage,
          ),
        );
      }
    }

    items.sort((a, b) => a.timeLabel.compareTo(b.timeLabel));
    return items;
  }

  Future<MedicineSchedule> createSchedule(MedicineSchedule schedule) async {
    final userId = _client.auth.currentUser?.id;
    final data = await _client
        .from('member_medicine_schedules')
        .insert({
          ...schedule.toInsertJson(),
          'created_by': userId,
          'reminder_notify_user_id': userId,
        })
        .select(_select)
        .single();
    final created = MedicineSchedule.fromJson(data);
    if (userId != null) await _syncReminders(created, userId);
    return created;
  }

  Future<void> updateSchedule(MedicineSchedule schedule) async {
    final userId = _client.auth.currentUser?.id;
    final data = await _client
        .from('member_medicine_schedules')
        .update(schedule.toUpdateJson())
        .eq('id', schedule.id)
        .select(_select)
        .single();
    if (userId != null) {
      await _syncReminders(MedicineSchedule.fromJson(data), userId);
    }
  }

  Future<void> deleteSchedule(String id) async {
    await NotificationService.instance.cancelMedicineReminders(id);
    await _client.from('member_medicine_schedules').delete().eq('id', id);
  }

  Future<void> rescheduleAllReminders(String householdId) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;

    final schedules = await fetchSchedulesForReminders(householdId);
    for (final schedule in schedules) {
      await _syncReminders(schedule, userId);
    }
  }

  Future<void> _syncReminders(MedicineSchedule schedule, String userId) async {
    await NotificationService.instance.cancelMedicineReminders(schedule.id);

    final notifyId = schedule.reminderNotifyUserId;
    if (notifyId != null && notifyId != userId) return;
    if (!schedule.isActive || schedule.timesPerDay.isEmpty) return;

    final memberName = schedule.memberDisplayName;
    final subtitleParts = <String>[
      if (schedule.dosage != null && schedule.dosage!.isNotEmpty) schedule.dosage!,
      if (memberName != null && memberName.isNotEmpty) 'for $memberName',
    ];

    for (var i = 0; i < schedule.timesPerDay.length; i++) {
      final parsed = parseScheduleTime(schedule.timesPerDay[i]);
      if (parsed == null) continue;

      await NotificationService.instance.scheduleMedicineReminder(
        scheduleId: schedule.id,
        timeIndex: i,
        title: schedule.displayTitle,
        body: subtitleParts.isEmpty ? 'Time to take your medicine' : subtitleParts.join(' · '),
        hour: parsed.hour,
        minute: parsed.minute,
      );
    }
  }
}

final medicineScheduleRepositoryProvider =
    Provider<MedicineScheduleRepository>((ref) {
  return MedicineScheduleRepository(ref.watch(supabaseClientProvider));
});

final medicineSchedulesProvider =
    FutureProvider.family<List<MedicineSchedule>, String>((ref, memberId) async {
  return ref.watch(medicineScheduleRepositoryProvider).fetchSchedules(memberId);
});

final medicineRemindersTodayProvider =
    FutureProvider<List<MedicineReminderToday>>((ref) async {
  final profile = await ref.watch(userProfileProvider.future);
  final householdId = profile?.activeHouseholdId;
  if (householdId == null) return [];
  return ref
      .watch(medicineScheduleRepositoryProvider)
      .fetchTodayReminders(householdId);
});
