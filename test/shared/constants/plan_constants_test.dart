import 'package:flutter_test/flutter_test.dart';
import 'package:myplanr/shared/constants/plan_constants.dart';

void main() {
  group('PlanTypes.labelFor', () {
    test('returns label for known types', () {
      expect(PlanTypes.labelFor(PlanTypes.meal), 'Meal');
      expect(PlanTypes.labelFor(PlanTypes.task), 'Task');
    });

    test('falls back to Other', () {
      expect(PlanTypes.labelFor('unknown'), 'Other');
    });
  });

  group('PlanScopes', () {
    test('defines personal and household scopes', () {
      expect(PlanScopes.personal, 'personal');
      expect(PlanScopes.household, 'household');
      expect(PlanScopes.all, hasLength(2));
    });
  });
}
