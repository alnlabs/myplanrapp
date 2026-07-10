/// Local notification categories that can have distinct alert sounds on Android.
enum NotificationAlertType {
  lowStock(
    id: 'low_stock',
    channelName: 'Low stock alerts',
    channelDescription: 'When pantry items run low',
    settingsLabel: 'Low stock',
    previewTitle: 'Low stock preview',
    previewBody: 'Rice is running low',
  ),
  planReminders(
    id: 'plan_reminders',
    channelName: 'Plan reminders',
    channelDescription: 'Reminders for plans and tasks',
    settingsLabel: 'Plans & tasks',
    previewTitle: 'Plan reminder preview',
    previewBody: 'Prep lunch boxes',
  ),
  subscriptionReminders(
    id: 'subscription_reminders',
    channelName: 'Subscription reminders',
    channelDescription: 'Reminders for recurring bills and subscriptions',
    settingsLabel: 'Bills & subscriptions',
    previewTitle: 'Bill reminder preview',
    previewBody: 'Netflix is due soon',
  ),
  medicineReminders(
    id: 'medicine_reminders',
    channelName: 'Medicine reminders',
    channelDescription: 'Daily medicine schedule reminders',
    settingsLabel: 'Medicine',
    previewTitle: 'Medicine reminder preview',
    previewBody: 'Take morning dose',
  ),
  standaloneReminders(
    id: 'standalone_reminders',
    channelName: 'Reminders',
    channelDescription: 'General reminders you create in MyPlanr',
    settingsLabel: 'General reminders',
    previewTitle: 'Reminder preview',
    previewBody: 'Call the plumber',
  ),
  testAlerts(
    id: 'test_alerts',
    channelName: 'Test alerts',
    channelDescription: 'Test notifications to verify device alerts',
    settingsLabel: 'Test alert',
    previewTitle: 'MyPlanr test alert',
    previewBody: 'If you hear this tone, the sound is set.',
  );

  const NotificationAlertType({
    required this.id,
    required this.channelName,
    required this.channelDescription,
    required this.settingsLabel,
    required this.previewTitle,
    required this.previewBody,
  });

  final String id;
  final String channelName;
  final String channelDescription;
  final String settingsLabel;
  final String previewTitle;
  final String previewBody;

  /// Types shown in Settings. Test alert uses the same picker but is grouped last.
  static const settingsTypes = [
    lowStock,
    planReminders,
    subscriptionReminders,
    medicineReminders,
    standaloneReminders,
    testAlerts,
  ];
}
