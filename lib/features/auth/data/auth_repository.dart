import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/auth_redirect.dart';
import '../../../core/logging/app_logger.dart';
import '../../../core/providers/supabase_providers.dart';
import '../../../shared/models/account_deletion_status.dart';
import '../../../shared/models/user_profile.dart';

class AuthRepository {
  AuthRepository(this._client);

  final SupabaseClient _client;

  /// Signs in with either an email address or a username.
  Future<AuthResponse> signIn(String identifier, String password) async {
    AppLogger.instance.info('Sign in attempt: $identifier');
    try {
      final email = await _resolveEmail(identifier);
      final res =
          await _client.auth.signInWithPassword(email: email, password: password);
      AppLogger.instance.info('Sign in success: ${res.user?.id}');
      return res;
    } catch (e, s) {
      AppLogger.instance.error('Sign in failed', e, s);
      rethrow;
    }
  }

  /// Resolves a username to its account email. Emails pass through unchanged.
  Future<String> _resolveEmail(String identifier) async {
    final value = identifier.trim();
    if (value.contains('@')) return value;
    final email = await _client.rpc<dynamic>(
      'email_for_username',
      params: {'p_username': value},
    );
    if (email is! String || email.isEmpty) {
      throw const AuthException('No account found for that username.');
    }
    return email;
  }

  Future<AuthResponse> signUp(
    String email,
    String password,
    String displayName, {
    String? username,
  }) async {
    AppLogger.instance.info('Sign up attempt: $email');
    try {
      final res = await _client.auth.signUp(
        email: email,
        password: password,
        data: {
          'display_name': displayName,
          if (username != null && username.trim().isNotEmpty)
            'username': username.trim(),
        },
        emailRedirectTo: AuthRedirect.url,
      );
      AppLogger.instance.info(
          'Sign up success: user=${res.user?.id} session=${res.session != null}');
      return res;
    } catch (e, s) {
      AppLogger.instance.error('Sign up failed', e, s);
      rethrow;
    }
  }

  Future<void> signOut() => _client.auth.signOut();

  Future<UserProfile?> fetchProfile() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return null;

    final finalized =
        await _client.rpc<bool>('finalize_expired_account_deletion');
    if (finalized == true) {
      await _client.auth.signOut();
      return null;
    }

    final data = await _client
        .from('profiles')
        .select()
        .eq('id', userId)
        .maybeSingle();
    if (data == null) return null;
    return UserProfile.fromJson(data);
  }

  Future<void> updateDisplayName(String displayName) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;
    final trimmed = displayName.trim();
    await _client.from('profiles').update({
      'display_name': trimmed,
    }).eq('id', userId);

    final profile = await fetchProfile();
    final householdId = profile?.activeHouseholdId;
    if (householdId != null) {
      await _client.from('household_family_members').update({
        'display_name': trimmed,
      }).eq('household_id', householdId).eq('user_id', userId);
    }
  }

  /// Sends a password-reset OTP (6-digit code) to the account email. The
  /// recovery email template renders `{{ .Token }}` so no link is included.
  Future<void> sendPasswordResetOtp(String email) async {
    await _client.auth.resetPasswordForEmail(email.trim());
  }

  /// Verifies the emailed recovery code. On success Supabase establishes a
  /// short-lived recovery session that authorizes [updatePassword].
  Future<void> verifyPasswordResetOtp({
    required String email,
    required String token,
  }) async {
    await _client.auth.verifyOTP(
      email: email.trim(),
      token: token.trim(),
      type: OtpType.recovery,
    );
  }

  /// Sets a new password for the currently authenticated (recovery) session.
  Future<void> updatePassword(String newPassword) async {
    await _client.auth.updateUser(UserAttributes(password: newPassword));
  }

  /// After sign-in, check grace-period deletion state.
  Future<UserProfile?> fetchProfileAfterAuth() async {
    final profile = await fetchProfile();
    if (profile == null) {
      throw const AccountDeletionExpiredException();
    }
    return profile;
  }

  /// Schedules account deletion. User can sign in within 30 days to restore.
  Future<DateTime> requestAccountDeletion() async {
    AppLogger.instance.info('Account deletion requested');
    try {
      final deletedAt = await _client.rpc<String>('request_account_deletion');
      await _client.auth.signOut();
      AppLogger.instance.info('Account scheduled for deletion');
      return DateTime.parse(deletedAt);
    } catch (e, s) {
      AppLogger.instance.error('Account deletion request failed', e, s);
      rethrow;
    }
  }

  Future<void> restoreAccount() async {
    AppLogger.instance.info('Account restore requested');
    try {
      await _client.rpc('restore_own_account');
      AppLogger.instance.info('Account restored');
    } catch (e, s) {
      AppLogger.instance.error('Account restore failed', e, s);
      rethrow;
    }
  }
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(ref.watch(supabaseClientProvider));
});

/// True while a password reset is being completed (recovery OTP verified and
/// the new password is being saved). The router reads this to avoid bouncing the
/// user off the reset screen when the recovery session momentarily signs them
/// in mid-flow.
final passwordResetInProgressProvider = StateProvider<bool>((ref) => false);

final userProfileProvider = FutureProvider<UserProfile?>((ref) async {
  ref.watch(authStateProvider);
  return ref.watch(authRepositoryProvider).fetchProfile();
});
