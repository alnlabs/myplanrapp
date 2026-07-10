import 'package:flutter_test/flutter_test.dart';
import 'package:myplanr/shared/constants/family_relationships.dart';

void main() {
  group('FamilyRelationships.labelFor', () {
    test('returns self label', () {
      expect(
        FamilyRelationships.labelFor(FamilyRelationships.self.value),
        FamilyRelationships.self.label,
      );
    });

    test('returns known relationship labels', () {
      expect(
        FamilyRelationships.labelFor('parent'),
        FamilyRelationships.parent.label,
      );
      expect(
        FamilyRelationships.labelFor('child'),
        FamilyRelationships.child.label,
      );
    });

    test('falls back to other', () {
      expect(
        FamilyRelationships.labelFor('unknown'),
        FamilyRelationships.other.label,
      );
    });
  });
}
