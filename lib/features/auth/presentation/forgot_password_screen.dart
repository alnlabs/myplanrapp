import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/strings/app_strings.dart';
import '../../../shared/utils/api_error_formatter.dart';
import '../../../shared/utils/validators.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../../../shared/widgets/loading_button.dart';
import '../data/auth_repository.dart';

enum _ResetPhase { email, code }

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _emailFormKey = GlobalKey<FormState>();
  final _resetFormKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _code = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();

  _ResetPhase _phase = _ResetPhase.email;
  bool _loading = false;
  bool _sending = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _code.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  String get _emailValue => _email.text.trim();

  Future<void> _sendCode() async {
    if (!_emailFormKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await ref.read(authRepositoryProvider).sendPasswordResetOtp(_emailValue);
      if (!mounted) return;
      setState(() => _phase = _ResetPhase.code);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = ApiErrorFormatter.format(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _resend() async {
    setState(() {
      _sending = true;
      _error = null;
    });
    try {
      await ref.read(authRepositoryProvider).sendPasswordResetOtp(_emailValue);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppStrings.resetCodeResent)),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = ApiErrorFormatter.format(e));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _submit() async {
    if (!_resetFormKey.currentState!.validate()) return;
    if (_code.text.trim().length < 6) {
      setState(() => _error = AppStrings.resetOtpNeedsCode);
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });
    // Verifying the code creates a short-lived recovery session; keep the router
    // from redirecting us into the app until the new password is saved.
    ref.read(passwordResetInProgressProvider.notifier).state = true;

    final repo = ref.read(authRepositoryProvider);
    try {
      await repo.verifyPasswordResetOtp(
        email: _emailValue,
        token: _code.text.trim(),
      );
    } catch (_) {
      ref.read(passwordResetInProgressProvider.notifier).state = false;
      if (!mounted) return;
      setState(() {
        _error = AppStrings.resetInvalidCode;
        _loading = false;
      });
      return;
    }

    try {
      await repo.updatePassword(_password.text);
      // Don't leave the user signed in via the recovery session — send them to
      // the login screen to sign in with the new password.
      await repo.signOut();
      ref.read(passwordResetInProgressProvider.notifier).state = false;
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppStrings.resetPasswordUpdated)),
      );
      context.go('/login');
    } catch (e) {
      ref.read(passwordResetInProgressProvider.notifier).state = false;
      if (!mounted) return;
      setState(() {
        _error = ApiErrorFormatter.format(e);
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.resetPassword)),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: _phase == _ResetPhase.email ? _buildEmailStep() : _buildCodeStep(),
        ),
      ),
    );
  }

  Widget _buildEmailStep() {
    return Form(
      key: _emailFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            AppStrings.resetEmailHint,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 20),
          AppTextField(
            controller: _email,
            label: AppStrings.email,
            validator: Validators.email,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(
              _error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
          const SizedBox(height: 24),
          LoadingButton(
            label: AppStrings.resetSendCode,
            isLoading: _loading,
            onPressed: _sendCode,
          ),
        ],
      ),
    );
  }

  Widget _buildCodeStep() {
    final theme = Theme.of(context);
    return Form(
      key: _resetFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            AppStrings.resetOtpBody,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${AppStrings.resetOtpSentTo} $_emailValue',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 20),
          TextFormField(
            controller: _code,
            keyboardType: TextInputType.number,
            maxLength: 6,
            style: const TextStyle(letterSpacing: 8, fontSize: 22),
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(6),
            ],
            decoration: const InputDecoration(
              labelText: AppStrings.resetCodeLabel,
              counterText: '',
            ),
          ),
          const SizedBox(height: 16),
          AppPasswordField(
            controller: _password,
            label: AppStrings.newPassword,
            validator: Validators.password,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 16),
          AppPasswordField(
            controller: _confirm,
            label: AppStrings.confirmPassword,
            validator: (value) =>
                Validators.confirmPassword(value, _password.text),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(
              _error!,
              style: TextStyle(color: theme.colorScheme.error),
            ),
          ],
          const SizedBox(height: 24),
          LoadingButton(
            label: AppStrings.resetPasswordCta,
            isLoading: _loading,
            onPressed: _submit,
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: _sending ? null : _resend,
            icon: const Icon(Icons.refresh),
            label: Text(
              _sending ? AppStrings.resetResending : AppStrings.resetResendCode,
            ),
          ),
        ],
      ),
    );
  }
}
