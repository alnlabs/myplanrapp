import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/supabase_providers.dart';
import 'admin_repository.dart';

/// In-memory state for the admin OTP step-up gate.
///
/// Lives outside the widget tree so that transient auth events (which re-run the
/// router's redirect) never remount the gate and re-send the code. The code is
/// sent exactly once per gate lifecycle; [reset] re-arms it so the next time the
/// admin area is opened a fresh code is required.
class AdminGateState {
  const AdminGateState({
    this.sending = false,
    this.sent = false,
    this.verified = false,
    this.error,
  });

  final bool sending;
  final bool sent;
  final bool verified;
  final Object? error;

  AdminGateState copyWith({
    bool? sending,
    bool? sent,
    bool? verified,
    Object? error,
    bool clearError = false,
  }) {
    return AdminGateState(
      sending: sending ?? this.sending,
      sent: sent ?? this.sent,
      verified: verified ?? this.verified,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class AdminGateNotifier extends Notifier<AdminGateState> {
  @override
  AdminGateState build() {
    // OTP verification lasts until the admin signs out. Clear it whenever the
    // session ends (from anywhere in the app, not just the admin screen).
    ref.listen(authStateProvider, (_, next) {
      final signedOut = next.valueOrNull?.session == null;
      final hasState =
          state.verified || state.sent || state.sending || state.error != null;
      if (signedOut && hasState) {
        state = const AdminGateState();
      }
    });
    return const AdminGateState();
  }

  AdminRepository get _repo => ref.read(adminRepositoryProvider);

  /// Sends the OTP once. No-ops if a code is already in flight, was already
  /// delivered, or the session is already verified.
  Future<void> ensureCodeSent() async {
    if (state.sending || state.sent || state.verified) return;
    state = state.copyWith(sending: true, clearError: true);
    try {
      await _repo.sendOtp();
      state = state.copyWith(sending: false, sent: true);
    } catch (e) {
      state = state.copyWith(sending: false, error: e);
    }
  }

  /// Forces a new code to be sent (user tapped "Resend").
  Future<void> resend() async {
    if (state.sending) return;
    state = state.copyWith(sent: false, clearError: true);
    await ensureCodeSent();
  }

  /// Verifies the entered code. Returns true on success.
  Future<bool> verify(String code) async {
    state = state.copyWith(clearError: true);
    try {
      await _repo.verifyOtp(code);
      state = state.copyWith(verified: true);
      return true;
    } catch (e) {
      state = state.copyWith(error: e);
      return false;
    }
  }

  /// Re-arms the gate so the next entry requires a fresh OTP.
  void reset() => state = const AdminGateState();
}

final adminGateProvider =
    NotifierProvider<AdminGateNotifier, AdminGateState>(AdminGateNotifier.new);
