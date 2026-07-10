/// Common medicine purpose labels for household schedules.
class MedicinePurposes {
  MedicinePurposes._();

  static const other = 'Other';

  static const all = <String>[
    'Blood pressure',
    'Diabetes',
    'Heart',
    'Thyroid',
    'Cholesterol',
    'Vitamin / supplement',
    'Pain or fever',
    'Allergy',
    'Digestion',
    'Asthma / breathing',
    'Skin',
    other,
  ];

  static bool isPredefined(String value) {
    return all.contains(value) && value != other;
  }
}
