import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/strings/app_strings.dart';
import '../../../shared/utils/api_error_formatter.dart';
import '../../../shared/widgets/loading_button.dart';
import '../../auth/data/auth_repository.dart';
import '../data/admin_gate_provider.dart';
import '../data/admin_repository.dart';

/// Step-up OTP gate. Shown every time the admin area is opened: an email OTP is
/// sent once on entry and must be verified before the dashboard is revealed.
///
/// All send/verify state lives in [adminGateProvider] so that auth events (which
/// refresh the router) never remount this screen and re-send the code.
class AdminOtpScreen extends ConsumerStatefulWidget {
  const AdminOtpScreen({super.key});

  @override
  ConsumerState<AdminOtpScreen> createState() => _AdminOtpScreenState();
}

class _AdminOtpScreenState extends ConsumerState<AdminOtpScreen> {
  final _code = TextEditingController();
  bool _verifying = false;
  String? _formError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(adminGateProvider.notifier).ensureCodeSent();
    });
  }

  @override
  void dispose() {
    // Re-arm the gate if the admin backs out before verifying, so the next open
    // sends a fresh code. When verification succeeded we intentionally keep the
    // verified state so the dashboard route stays reachable.
    if (!ref.read(adminGateProvider).verified) {
      ref.read(adminGateProvider.notifier).reset();
    }
    _code.dispose();
    super.dispose();
  }

  Future<void> _resend() async {
    setState(() => _formError = null);
    await ref.read(adminGateProvider.notifier).resend();
    if (!mounted) return;
    final gate = ref.read(adminGateProvider);
    if (gate.error == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppStrings.adminOtpResent)),
      );
    }
  }

  Future<void> _verify() async {
    final code = _code.text.trim();
    if (code.length < 6) {
      setState(() => _formError = AppStrings.adminOtpNeedsCode);
      return;
    }
    setState(() {
      _verifying = true;
      _formError = null;
    });
    final ok = await ref.read(adminGateProvider.notifier).verify(code);
    if (!mounted) return;
    if (ok) {
      // The router redirect moves us to /admin/home once verified fires, but
      // navigate explicitly too in case this screen was pushed imperatively.
      context.go('/admin/home');
      return;
    }
    setState(() {
      _formError = AppStrings.adminOtpInvalid;
      _verifying = false;
    });
  }

  Future<void> _confirmSignOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text(AppStrings.signOutConfirmTitle),
        content: const Text(AppStrings.signOutConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text(AppStrings.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text(AppStrings.signOut),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    ref.read(adminGateProvider.notifier).reset();
    await ref.read(authRepositoryProvider).signOut();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final email = ref.read(adminRepositoryProvider).adminEmail;
    final gate = ref.watch(adminGateProvider);

    // Dedicated admin-only accounts (no household) reach this screen as a
    // top-level route and have no app to go back to, so offer sign-out.
    final profile = ref.watch(userProfileProvider).valueOrNull;
    final showSignOut = profile != null && !profile.hasHousehold;

    final error = _formError ??
        (gate.error != null ? ApiErrorFormatter.format(gate.error) : null);

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.adminOtpTitle),
        actions: [
          if (showSignOut)
            IconButton(
              onPressed: _confirmSignOut,
              icon: const Icon(Icons.logout),
              tooltip: AppStrings.signOut,
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Icon(
            Icons.shield_outlined,
            size: 48,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(height: 16),
          Text(
            AppStrings.adminOtpBody,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          if (email != null && email.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              '${AppStrings.adminOtpSentTo} $email',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          const SizedBox(height: 24),
          TextField(
            controller: _code,
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.done,
            maxLength: 6,
            style: const TextStyle(letterSpacing: 8, fontSize: 22),
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(6),
            ],
            decoration: const InputDecoration(
              labelText: AppStrings.adminOtpCodeLabel,
              counterText: '',
            ),
            onSubmitted: (_) => _verify(),
          ),
          if (error != null) ...[
            const SizedBox(height: 12),
            Text(
              error,
              style: TextStyle(color: theme.colorScheme.error),
            ),
          ],
          const SizedBox(height: 24),
          LoadingButton(
            label: AppStrings.adminOtpVerify,
            icon: Icons.lock_open_outlined,
            isLoading: _verifying,
            onPressed: _verify,
          ),
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: gate.sending ? null : _resend,
            icon: const Icon(Icons.refresh),
            label: Text(
              gate.sending ? AppStrings.adminOtpSending : AppStrings.adminOtpResend,
            ),
          ),
        ],
      ),
    );
  }
}
