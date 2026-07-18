import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/auth_redirect.dart';
import '../../../core/providers/supabase_providers.dart';
import '../../../shared/constants/list_pagination.dart';

String? _reporterName(Map<String, dynamic> json) {
  final profile = json['profiles'] as Map<String, dynamic>?;
  final name = profile?['display_name'] as String?;
  if (name != null && name.trim().isNotEmpty) return name.trim();
  final username = profile?['username'] as String?;
  if (username != null && username.trim().isNotEmpty) return '@$username';
  return null;
}

DateTime? _parseDate(dynamic value) =>
    value is String ? DateTime.tryParse(value) : null;

class FeedbackEntry {
  const FeedbackEntry({
    required this.id,
    required this.type,
    required this.message,
    this.contactEmail,
    this.appVersion,
    this.reporterName,
    this.createdAt,
  });

  final String id;
  final String type;
  final String message;
  final String? contactEmail;
  final String? appVersion;
  final String? reporterName;
  final DateTime? createdAt;

  factory FeedbackEntry.fromJson(Map<String, dynamic> json) {
    return FeedbackEntry(
      id: json['id'] as String,
      type: json['type'] as String? ?? 'other',
      message: json['message'] as String? ?? '',
      contactEmail: json['contact_email'] as String?,
      appVersion: json['app_version'] as String?,
      reporterName: _reporterName(json),
      createdAt: _parseDate(json['created_at']),
    );
  }
}

class ErrorReportEntry {
  const ErrorReportEntry({
    required this.id,
    required this.message,
    this.error,
    this.stackTrace,
    this.appVersion,
    this.platform,
    this.reporterName,
    this.createdAt,
  });

  final String id;
  final String message;
  final String? error;
  final String? stackTrace;
  final String? appVersion;
  final String? platform;
  final String? reporterName;
  final DateTime? createdAt;

  factory ErrorReportEntry.fromJson(Map<String, dynamic> json) {
    return ErrorReportEntry(
      id: json['id'] as String,
      message: json['message'] as String? ?? '',
      error: json['error'] as String?,
      stackTrace: json['stack_trace'] as String?,
      appVersion: json['app_version'] as String?,
      platform: json['platform'] as String?,
      reporterName: _reporterName(json),
      createdAt: _parseDate(json['created_at']),
    );
  }
}

class AdminRepository {
  AdminRepository(this._client);

  final SupabaseClient _client;

  String? get adminEmail => _client.auth.currentUser?.email;

  /// Sends a one-time passcode to the signed-in admin's email.
  Future<void> sendOtp() async {
    final email = adminEmail;
    if (email == null || email.isEmpty) {
      throw const AuthException('No email is associated with this account.');
    }
    // Pass the app deep link so the email's link isn't the default localhost
    // Site URL. The OTP flow only needs the numeric token, but this keeps any
    // link in the email pointing at the app.
    await _client.auth.signInWithOtp(
      email: email,
      shouldCreateUser: false,
      emailRedirectTo: AuthRedirect.url,
    );
  }

  /// Verifies the emailed OTP. Throws [AuthException] on an invalid code.
  Future<void> verifyOtp(String token) async {
    final email = adminEmail;
    if (email == null || email.isEmpty) {
      throw const AuthException('No email is associated with this account.');
    }
    await _client.auth.verifyOTP(
      email: email,
      token: token.trim(),
      type: OtpType.email,
    );
  }

  Future<List<FeedbackEntry>> fetchFeedback() async {
    final data = await _client
        .from('feedback')
        .select('*, profiles(display_name, username)')
        .order('created_at', ascending: false)
        .limit(kSafetyFetchCap);
    return (data as List)
        .map((e) => FeedbackEntry.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<ErrorReportEntry>> fetchErrorReports() async {
    final data = await _client
        .from('error_reports')
        .select('*, profiles(display_name, username)')
        .order('created_at', ascending: false)
        .limit(kSafetyFetchCap);
    return (data as List)
        .map((e) => ErrorReportEntry.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Deletes the given feedback rows. A single id, a day's worth, or all loaded
  /// ids can be passed. No-ops on an empty list.
  Future<void> deleteFeedback(List<String> ids) async {
    if (ids.isEmpty) return;
    await _client.from('feedback').delete().inFilter('id', ids);
  }

  /// Deletes the given error-report rows (see [deleteFeedback]).
  Future<void> deleteErrorReports(List<String> ids) async {
    if (ids.isEmpty) return;
    await _client.from('error_reports').delete().inFilter('id', ids);
  }
}

final adminRepositoryProvider = Provider<AdminRepository>((ref) {
  return AdminRepository(ref.watch(supabaseClientProvider));
});

final adminFeedbackProvider =
    FutureProvider.autoDispose<List<FeedbackEntry>>((ref) async {
  return ref.watch(adminRepositoryProvider).fetchFeedback();
});

final adminErrorReportsProvider =
    FutureProvider.autoDispose<List<ErrorReportEntry>>((ref) async {
  return ref.watch(adminRepositoryProvider).fetchErrorReports();
});
