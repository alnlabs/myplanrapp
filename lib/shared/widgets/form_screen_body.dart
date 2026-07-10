import 'package:flutter/material.dart';

import 'form_error_banner.dart';
import 'loading_button.dart';

/// Standard spacing between fields on create/edit forms.
const double kFormFieldSpacing = 16;

/// Scrollable form shell used by create/edit screens.
class FormScreenBody extends StatelessWidget {
  const FormScreenBody({
    super.key,
    required this.formKey,
    required this.children,
    this.padding = const EdgeInsets.all(24),
    this.autovalidateMode = AutovalidateMode.onUserInteraction,
  });

  final GlobalKey<FormState> formKey;
  final List<Widget> children;
  final EdgeInsets padding;
  final AutovalidateMode autovalidateMode;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: padding,
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        child: Form(
          key: formKey,
          autovalidateMode: autovalidateMode,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: children,
          ),
        ),
      ),
    );
  }
}

/// Save row: optional error banner + primary action.
class FormSaveSection extends StatelessWidget {
  const FormSaveSection({
    super.key,
    this.error,
    required this.saveLabel,
    required this.isLoading,
    required this.onSave,
  });

  final String? error;
  final String saveLabel;
  final bool isLoading;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (error != null) ...[
          FormErrorBanner(message: error!),
          const SizedBox(height: kFormFieldSpacing),
        ],
        LoadingButton(
          label: saveLabel,
          isLoading: isLoading,
          onPressed: onSave,
        ),
      ],
    );
  }
}
