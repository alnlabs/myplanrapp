import '../../../core/strings/app_strings.dart';

String dashboardGreetingForHour(int hour) {
  if (hour < 12) return AppStrings.goodMorning;
  if (hour < 17) return AppStrings.goodAfternoon;
  return AppStrings.goodEvening;
}

String dashboardGreeting([DateTime? now]) {
  return dashboardGreetingForHour((now ?? DateTime.now()).hour);
}
