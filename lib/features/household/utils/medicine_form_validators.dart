import '../../../core/strings/app_strings.dart';
import '../../../shared/constants/medicine_constants.dart';
import '../../../shared/models/medicine_schedule.dart';

/// Resolves the stored medicine purpose from form selections.
String resolveMedicinePurpose({
  required String? selectedPurpose,
  required String customPurposeText,
}) {
  if (selectedPurpose == MedicinePurposes.other) {
    return customPurposeText.trim();
  }
  return selectedPurpose?.trim() ?? '';
}

String? validateMedicinePurpose({
  required String? selectedPurpose,
  required String customPurposeText,
}) {
  final medicineFor = resolveMedicinePurpose(
    selectedPurpose: selectedPurpose,
    customPurposeText: customPurposeText,
  );
  if (medicineFor.isEmpty) {
    return AppStrings.medicineForRequired;
  }
  return null;
}

String? validateMedicineTimes(int timesCount) {
  if (timesCount <= 0) {
    return AppStrings.timesPerDayHint;
  }
  return null;
}

/// Initial purpose dropdown value when editing an existing schedule.
String? initialMedicinePurposeSelection(MedicineSchedule? existing) {
  if (existing == null) return null;
  if (MedicinePurposes.isPredefined(existing.medicineFor)) {
    return existing.medicineFor;
  }
  return MedicinePurposes.other;
}

/// Custom purpose text when editing a schedule with a non-predefined purpose.
String initialMedicineCustomPurpose(MedicineSchedule? existing) {
  if (existing == null) return '';
  if (MedicinePurposes.isPredefined(existing.medicineFor)) return '';
  return existing.medicineFor;
}
