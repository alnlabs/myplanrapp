import '../../../core/strings/app_strings.dart';

String? validateIncomeMemberId(String? familyMemberId) {
  if (familyMemberId == null || familyMemberId.isEmpty) {
    return AppStrings.incomeMemberRequired;
  }
  return null;
}
