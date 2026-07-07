import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/connectivity_provider.dart';
import '../../core/strings/app_strings.dart';

class OfflineException implements Exception {
  const OfflineException([this.message = AppStrings.offlineWriteBlocked]);

  final String message;

  @override
  String toString() => message;
}

extension OfflineGuard on WidgetRef {
  /// Throws [OfflineException] when the device is offline.
  /// Call before performing a write so forms surface a clear message.
  void ensureOnline() {
    final online = read(connectivityProvider).valueOrNull ?? true;
    if (!online) throw const OfflineException();
  }
}

extension OfflineGuardRef on Ref {
  void ensureOnline() {
    final online = read(connectivityProvider).valueOrNull ?? true;
    if (!online) throw const OfflineException();
  }
}
