import 'package:flutter/foundation.dart';

/// Deep-link target for Supabase auth emails (confirm signup, reset password).
///
/// Must match Android/iOS URL scheme config and be listed in Supabase
/// Dashboard → Authentication → URL Configuration → Redirect URLs.
abstract final class AuthRedirect {
  static const scheme = 'com.alnlabs.myplanr';
  static const host = 'login-callback';

  /// Mobile / desktop custom-scheme callback.
  static const mobile = '$scheme://$host';

  /// Redirect used in sign-up and password-reset emails.
  static String get url {
    if (kIsWeb) {
      // Flutter web: return to the page that served the app.
      return Uri.base.origin;
    }
    return mobile;
  }
}
