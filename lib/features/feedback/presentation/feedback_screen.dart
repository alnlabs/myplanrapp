import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/strings/app_strings.dart';
import '../../../shared/widgets/feature_screen_app_bar.dart';
import '../../../shared/utils/api_error_formatter.dart';
import '../../../shared/utils/validators.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../../../shared/widgets/loading_button.dart';
import '../data/feedback_repository.dart';

class FeedbackScreen extends ConsumerStatefulWidget {
  const FeedbackScreen({super.key});

  @override
  ConsumerState<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends ConsumerState<FeedbackScreen> {
  final _formKey = GlobalKey<FormState>();
  final _message = TextEditingController();
  final _contact = TextEditingController();
  FeedbackType _type = FeedbackType.feature;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _message.dispose();
    _contact.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await ref.read(feedbackRepositoryProvider).submit(
            type: _type,
            message: _message.text,
            contactEmail: _contact.text,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppStrings.feedbackSubmitted)),
      );
      Navigator.of(context).pop();
    } catch (e) {
      setState(() => _error = ApiErrorFormatter.format(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: const FeatureScreenAppBar(
        title: AppStrings.feedbackTitle,
        subtitle: AppStrings.feedbackSubtitle,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              AppStrings.feedbackHint,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 20),
            SegmentedButton<FeedbackType>(
              segments: const [
                ButtonSegment(
                  value: FeedbackType.feature,
                  label: Text(AppStrings.feedbackTypeFeature),
                  icon: Icon(Icons.lightbulb_outline),
                ),
                ButtonSegment(
                  value: FeedbackType.bug,
                  label: Text(AppStrings.feedbackTypeBug),
                  icon: Icon(Icons.bug_report_outlined),
                ),
              ],
              selected: {_type},
              onSelectionChanged: (value) =>
                  setState(() => _type = value.first),
            ),
            const SizedBox(height: 20),
            AppTextField(
              controller: _message,
              label: AppStrings.feedbackMessage,
              helperText: AppStrings.feedbackMessageHint,
              maxLines: 6,
              validator: Validators.required,
            ),
            const SizedBox(height: 16),
            AppTextField(
              controller: _contact,
              label: AppStrings.feedbackContact,
              helperText: AppStrings.feedbackContactHint,
              keyboardType: TextInputType.emailAddress,
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
              label: AppStrings.feedbackSubmit,
              isLoading: _loading,
              icon: Icons.send_outlined,
              onPressed: _submit,
            ),
          ],
        ),
      ),
    );
  }
}
