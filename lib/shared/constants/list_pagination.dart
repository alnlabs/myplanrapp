const int kListPageSize = 50;

/// Larger single fetch for dropdown pickers (not infinite scroll).
const int kPickerPageSize = 100;

/// Defensive ceiling for reads that intentionally fetch a full set instead of
/// paginating (aggregations, reminders, alerts, and small flat lists that have
/// client-side derived views). Sits well above any realistic household size, so
/// it never affects normal usage but caps a pathological payload.
const int kSafetyFetchCap = 500;
