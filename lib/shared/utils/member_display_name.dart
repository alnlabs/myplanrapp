/// Resolves how a family/household member should appear in lists.
///
/// Priority: full name → username → email → [fallback].
String memberListLabel({
  String? profileDisplayName,
  String? rosterDisplayName,
  String? username,
  String? email,
  String fallback = 'Member',
}) {
  final uname = _clean(username);

  final profileName = _clean(profileDisplayName);
  if (profileName != null && !_looksLikeUsername(profileName, uname)) {
    return profileName;
  }

  final rosterName = _clean(rosterDisplayName);
  if (rosterName != null && !_looksLikeUsername(rosterName, uname)) {
    return rosterName;
  }

  if (uname != null) return uname;

  final mail = _clean(email);
  if (mail != null) return mail;

  return fallback;
}

String? _clean(String? value) {
  final trimmed = value?.trim();
  if (trimmed == null || trimmed.isEmpty) return null;
  return trimmed;
}

bool _looksLikeUsername(String name, String? username) {
  if (username == null) return false;
  return name.toLowerCase() == username.toLowerCase();
}
