enum ReminderSourceType {
  standalone,
  plan,
  subscription,
  medicine,
}

class AppReminderItem {
  const AppReminderItem({
    required this.id,
    required this.sourceType,
    required this.sourceId,
    required this.title,
    this.subtitle,
    this.reminderAt,
    this.isRepeating = false,
    this.timeLabel,
    this.medicineTimeIndex,
  });

  /// Unique list key (e.g. `standalone_<id>`, `med_<id>_0`).
  final String id;
  final ReminderSourceType sourceType;
  final String sourceId;
  final String title;
  final String? subtitle;
  final DateTime? reminderAt;
  final bool isRepeating;
  final String? timeLabel;
  final int? medicineTimeIndex;

  bool get isStandalone => sourceType == ReminderSourceType.standalone;
}
