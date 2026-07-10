import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:myplanr/core/strings/app_strings.dart';
import 'package:myplanr/shared/utils/api_error_formatter.dart';
import 'package:myplanr/shared/utils/offline_guard.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  group('ApiErrorFormatter.format', () {
    test('returns fallback for null', () {
      expect(ApiErrorFormatter.format(null), AppStrings.errorGeneric);
      expect(
        ApiErrorFormatter.format(null, fallback: 'Custom'),
        'Custom',
      );
    });

    test('formats OfflineException', () {
      const error = OfflineException();
      expect(ApiErrorFormatter.format(error), error.message);
    });

    test('formats SocketException', () {
      expect(
        ApiErrorFormatter.format(const SocketException('fail')),
        AppStrings.errorNetwork,
      );
    });

    test('formats TimeoutException', () {
      expect(
        ApiErrorFormatter.format(TimeoutException('slow')),
        AppStrings.errorTimeout,
      );
    });

    test('detects wrapped network errors', () {
      expect(
        ApiErrorFormatter.format(Exception('ClientException: connection closed')),
        AppStrings.errorNetwork,
      );
    });

    test('formats AuthException message', () {
      expect(
        ApiErrorFormatter.format(const AuthException('Invalid login')),
        'Invalid login',
      );
    });

    test('formats Postgrest duplicate key', () {
      expect(
        ApiErrorFormatter.format(
          const PostgrestException(message: 'dup', code: '23505'),
        ),
        'That value is already in use.',
      );
    });

    test('formats Postgrest permission denied', () {
      expect(
        ApiErrorFormatter.format(
          const PostgrestException(message: 'denied', code: '42501'),
        ),
        'You do not have permission to do that.',
      );
    });

    test('formats Postgrest not found', () {
      expect(
        ApiErrorFormatter.format(
          const PostgrestException(message: 'missing', code: 'PGRST116'),
        ),
        'The requested item was not found.',
      );
    });

    test('formats session expired', () {
      expect(
        ApiErrorFormatter.format(
          const PostgrestException(message: 'jwt', code: 'PGRST301'),
        ),
        'Your session expired. Please sign in again.',
      );
    });

    test('hides technical generic errors', () {
      final long = 'x' * 200;
      expect(ApiErrorFormatter.format(Exception(long)), AppStrings.errorGeneric);
      expect(
        ApiErrorFormatter.format(Exception('package:flutter/foo.dart')),
        AppStrings.errorGeneric,
      );
    });

    test('cleans Exception prefix from readable messages', () {
      expect(
        ApiErrorFormatter.format(Exception('Something went wrong')),
        'Something went wrong',
      );
    });
  });

  group('toUserMessage extension', () {
    test('delegates to format', () {
      expect(
        const SocketException('x').toUserMessage(),
        AppStrings.errorNetwork,
      );
    });
  });
}
