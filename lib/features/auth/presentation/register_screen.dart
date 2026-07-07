import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/config/legal_urls.dart';
import '../../../core/strings/app_strings.dart';
import '../../../shared/utils/api_error_formatter.dart';
import '../../../shared/utils/validators.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../../../shared/widgets/loading_button.dart';
import '../../../shared/widgets/myplanr_logo.dart';
import '../data/auth_repository.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _loading = false;
  bool _acceptedTerms = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(AppStrings.errorGeneric)),
        );
      }
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_acceptedTerms) {
      setState(() => _error = AppStrings.termsRequired);
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await ref.read(authRepositoryProvider).signUp(
            _email.text.trim(),
            _password.text,
            _name.text.trim(),
          );
      await ref.read(authRepositoryProvider).updateDisplayName(_name.text.trim());
      ref.invalidate(userProfileProvider);
      if (mounted) context.go('/household-setup');
    } catch (e) {
      setState(() => _error = ApiErrorFormatter.format(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final linkStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: Theme.of(context).colorScheme.primary,
          decoration: TextDecoration.underline,
        );

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.signUp)),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Center(child: MyPlanrLogo(height: 72)),
                const SizedBox(height: 24),
                AppTextField(
                  controller: _name,
                  label: AppStrings.displayName,
                  validator: Validators.required,
                ),
                const SizedBox(height: 16),
                AppTextField(
                  controller: _email,
                  label: AppStrings.email,
                  validator: Validators.email,
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 16),
                AppTextField(
                  controller: _password,
                  label: AppStrings.password,
                  validator: Validators.password,
                  obscureText: true,
                ),
                const SizedBox(height: 8),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _acceptedTerms,
                  onChanged: (v) => setState(() => _acceptedTerms = v ?? false),
                  title: RichText(
                    text: TextSpan(
                      style: Theme.of(context).textTheme.bodyMedium,
                      children: [
                        TextSpan(text: '${AppStrings.acceptTermsPrefix} '),
                        TextSpan(
                          text: AppStrings.termsOfService,
                          style: linkStyle,
                          recognizer: TapGestureRecognizer()
                            ..onTap = () => _openUrl(LegalUrls.termsOfService),
                        ),
                        const TextSpan(text: ' and '),
                        TextSpan(
                          text: AppStrings.privacyPolicy,
                          style: linkStyle,
                          recognizer: TapGestureRecognizer()
                            ..onTap = () => _openUrl(LegalUrls.privacyPolicy),
                        ),
                      ],
                    ),
                  ),
                  controlAffinity: ListTileControlAffinity.leading,
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
                  label: AppStrings.signUp,
                  isLoading: _loading,
                  onPressed: _submit,
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => context.go('/login'),
                  child: const Text(AppStrings.signIn),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
