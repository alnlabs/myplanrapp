import 'package:flutter_test/flutter_test.dart';
import 'package:myplanr/features/home/data/setup_checklist_provider.dart';

void main() {
  group('SetupChecklist', () {
    test('pantryDone requires at least 3 items', () {
      const incomplete = SetupChecklist(
        pantryCount: 2,
        hasFamilyMember: true,
        hasPlan: true,
        hasExpense: true,
      );
      expect(incomplete.pantryDone, isFalse);

      const complete = SetupChecklist(
        pantryCount: 3,
        hasFamilyMember: true,
        hasPlan: true,
        hasExpense: false,
      );
      expect(complete.pantryDone, isTrue);
    });

    test('isComplete requires pantry, family, and plan', () {
      const checklist = SetupChecklist(
        pantryCount: 5,
        hasFamilyMember: true,
        hasPlan: true,
        hasExpense: false,
      );
      expect(checklist.isComplete, isTrue);
      expect(checklist.expenseDone, isFalse);
    });

    test('incomplete when family missing', () {
      const checklist = SetupChecklist(
        pantryCount: 5,
        hasFamilyMember: false,
        hasPlan: true,
        hasExpense: true,
      );
      expect(checklist.isComplete, isFalse);
    });
  });
}
