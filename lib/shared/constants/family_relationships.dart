class FamilyRelationship {
  const FamilyRelationship({required this.value, required this.label});

  final String value;
  final String label;
}

class FamilyRelationships {
  FamilyRelationships._();

  static const self = FamilyRelationship(value: 'self', label: 'Me');
  static const spouse = FamilyRelationship(value: 'spouse', label: 'Spouse / Partner');
  static const parent = FamilyRelationship(value: 'parent', label: 'Parent');
  static const child = FamilyRelationship(value: 'child', label: 'Child');
  static const sibling = FamilyRelationship(value: 'sibling', label: 'Sibling');
  static const grandparent = FamilyRelationship(value: 'grandparent', label: 'Grandparent');
  static const grandchild = FamilyRelationship(value: 'grandchild', label: 'Grandchild');
  static const inLaw = FamilyRelationship(value: 'in_law', label: 'In-law');
  static const other = FamilyRelationship(value: 'other', label: 'Other');

  static const all = [
    spouse,
    parent,
    child,
    sibling,
    grandparent,
    grandchild,
    inLaw,
    other,
  ];

  static const inviteOptions = all;

  static String labelFor(String value) {
    if (value == self.value) return self.label;
    return all.firstWhere((r) => r.value == value, orElse: () => other).label;
  }
}
