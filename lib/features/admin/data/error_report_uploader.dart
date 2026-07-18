import 'dart:async';
import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/logging/app_logger.dart';
import '../../../core/strings/app_strings.dart';

/// Uploads error-level diagnostic entries to Supabase so admins can review
/// crashes remotely. Best-effort: silently no-ops when offline or signed out,
/// dedupes recent messages, and never throws back into the logger.
class ErrorReportUploader {
  ErrorReportUploader._();

  static SupabaseClient? _client;

  // Avoid flooding: skip messages already seen recently in this session.
  static final Queue<String> _recent = Queue<String>();
  static const _recentCap = 30;

  /// Enables uploads by hooking into [AppLogger.errorSink].
  static void enable(SupabaseClient client) {
    _client = client;
    AppLogger.instance.errorSink = _handle;
  }

  static void _handle(LogEntry entry) {
    // Fire-and-forget; never block or throw into the logger.
    unawaited(_upload(entry));
  }

  static Future<void> _upload(LogEntry entry) async {
    final client = _client;
    if (client == null) return;

    // RLS requires an authenticated author; skip pre-login errors.
    final userId = client.auth.currentSession?.user.id;
    if (userId == null) return;

    final key = '${entry.message}|${entry.error ?? ''}';
    if (_recent.contains(key)) return;
    _recent.addLast(key);
    if (_recent.length > _recentCap) _recent.removeFirst();

    try {
      await client.from('error_reports').insert({
        'user_id': userId,
        'message': entry.message,
        'error': entry.error,
        'stack_trace': entry.stackTrace,
        'app_version': AppStrings.appVersion,
        'platform': defaultTargetPlatform.name,
      });
    } catch (_) {
      // Best-effort only; a failed upload must not surface anywhere.
    }
  }
}
