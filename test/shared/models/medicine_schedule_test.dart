import 'package:flutter_test/flutter_test.dart';
import 'package:myplanr/shared/models/medicine_schedule.dart';

void main() {
  group('MedicineSchedule', () {
    test('displayTitle includes brand when present', () {
      const schedule = MedicineSchedule(
        id: 'm1',
        familyMemberId: 'f1',
        householdId: 'hh',
        medicineFor: 'Fever',
        medicineName: 'Crocin',
        timesPerDay: ['08:00', '20:00'],
      );
      expect(schedule.displayTitle, 'Fever · Crocin');
      expect(schedule.timesLabel, '08:00, 20:00');
    });

    test('displayTitle uses medicineFor only when brand missing', () {
      const schedule = MedicineSchedule(
        id: 'm1',
        familyMemberId: 'f1',
        householdId: 'hh',
        medicineFor: 'Vitamin D',
        timesPerDay: [],
      );
      expect(schedule.displayTitle, 'Vitamin D');
      expect(schedule.timesLabel, '');
    });

    test('fromJson falls back to legacy medicine_name', () {
      final schedule = MedicineSchedule.fromJson({
        'id': 'm1',
        'family_member_id': 'f1',
        'household_id': 'hh',
        'medicine_name': 'Legacy Name',
        'times_per_day': ['09:00'],
        'household_family_members': {'display_name': 'Alex'},
      });
      expect(schedule.medicineFor, 'Legacy Name');
      expect(schedule.memberDisplayName, 'Alex');
    });

    test('toInsertJson trims empty medicine name', () {
      const schedule = MedicineSchedule(
        id: 'm1',
        familyMemberId: 'f1',
        householdId: 'hh',
        medicineFor: 'Pain',
        medicineName: '   ',
        timesPerDay: ['08:00'],
      );
      final json = schedule.toInsertJson();
      expect(json['medicine_name'], isNull);
      expect(json['medicine_for'], 'Pain');
    });
  });
}
