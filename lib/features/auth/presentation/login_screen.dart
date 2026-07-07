import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/strings/app_strings.dart';
import '../../../shared/models/account_deletion_status.dart';
import '../../../shared/utils/api_error_formatter.dart';
import '../../../shared/utils/validators.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../../../shared/widgets/loading_button.dart';
import '../../../shared/widgets/myplanr_logo.dart';
import '../../../shared/widgets/secret_tap.dart';
import '../data/auth_repository.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await ref.read(authRepositoryProvider).signIn(
            _email.text.trim(),
            _password.text,
          );
      ref.invalidate(userProfileProvider);
      try {
        final profile =
            await ref.read(authRepositoryProvider).fetchProfileAfterAuth();
        if (!mounted) return;
        if (profile?.isPendingDeletion ?? false) {
          context.go('/account-restore');
          return;
        }
        if (profile?.hasHousehold ?? false) {
          context.go('/home');
        } else {
          context.go('/household-setup');
        }
      } on AccountDeletionExpiredException {
        if (!mounted) return;
        setState(() => _error = AppStrings.accountDeletionExpired);
      }
    } catch (e) {
      setState(() => _error = ApiErrorFormatter.format(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.signIn)),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Center(
                  child: SecretTap(child: MyPlanrLogo(height: 80)),
                ),
                const SizedBox(height: 32),
                AppTextField(
                  controller: _email,
                  label: AppStrings.emailOrUsername,
                  validator: Validators.required,
                ),
                const SizedBox(height: 16),
                AppPasswordField(
                  controller: _password,
                  label: AppStrings.password,
                  validator: Validators.password,
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
                  label: AppStrings.signIn,
                  isLoading: _loading,
                  onPressed: _submit,
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => context.go('/forgot-password'),
                  child: const Text(AppStrings.forgotPassword),
                ),
                TextButton(
                  onPressed: () => context.go('/register'),
                  child: const Text(AppStrings.signUp),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
