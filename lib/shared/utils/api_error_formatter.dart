import 'dart:async';
import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/strings/app_strings.dart';
import 'offline_guard.dart';

class ApiErrorFormatter {
  ApiErrorFormatter._();

  static const defaultMessage = AppStrings.errorGeneric;

  static String format(Object? error, {String fallback = defaultMessage}) {
    if (error == null) return fallback;

    if (error is OfflineException) {
      return error.message;
    }
    if (error is AuthException) {
      return _clean(error.message, fallback);
    }
    if (error is PostgrestException) {
      return _fromPostgrest(error, fallback);
    }
    if (error is SocketException) {
      return AppStrings.errorNetwork;
    }
    if (error is TimeoutException) {
      return 'Request timed out. Please try again.';
    }

    final text = error.toString();
    if (_looksTechnical(text)) return fallback;
    return _clean(text, fallback);
  }

  static String _fromPostgrest(PostgrestException error, String fallback) {
    switch (error.code) {
      case '23505':
        return 'That value is already in use.';
      case '42501':
        return 'You do not have permission to do that.';
      case 'PGRST116':
        return 'The requested item was not found.';
      case 'PGRST301':
        return 'Your session expired. Please sign in again.';
      default:
        final message = error.message.trim();
        if (message.isNotEmpty && !_looksTechnical(message)) {
          return _clean(message, fallback);
        }
        return fallback;
    }
  }

  static bool _looksTechnical(String text) {
    final lower = text.toLowerCase();
    return lower.contains('stack trace') ||
        lower.contains('package:') ||
        text.length > 160;
  }

  static String _clean(String? raw, String fallback) {
    if (raw == null || raw.trim().isEmpty) return fallback;
    var message = raw.trim();
    message = message.replaceFirst(RegExp(r'^Exception:\s*'), '');
    if (_looksTechnical(message)) return fallback;
    return message;
  }
}

extension UserFacingApiError on Object {
  String toUserMessage({String fallback = ApiErrorFormatter.defaultMessage}) {
    return ApiErrorFormatter.format(this, fallback: fallback);
  }
}
