/// Supabase Storage configuration.
class StorageBuckets {
  StorageBuckets._();

  static const householdAttachments = 'household-attachments';
  static const householdAvatars = 'household-avatars';
}

class AttachmentTypes {
  AttachmentTypes._();

  static const warranty = 'warranty';
  static const receipt = 'receipt';
  static const other = 'other';

  static const all = [
    (value: warranty, label: 'Warranty card'),
    (value: receipt, label: 'Receipt'),
    (value: other, label: 'Other'),
  ];

  static String labelFor(String value) {
    for (final t in all) {
      if (t.value == value) return t.label;
    }
    return value;
  }
}
