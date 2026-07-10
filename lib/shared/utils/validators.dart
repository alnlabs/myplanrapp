import '../../core/strings/app_strings.dart';

class Validators {
  Validators._();

  static String? required(String? value) {
    if (value == null || value.trim().isEmpty) {
      return AppStrings.requiredField;
    }
    return null;
  }

  static String? requiredSelection(String? value) {
    if (value == null || value.isEmpty) {
      return AppStrings.requiredField;
    }
    return null;
  }

  static String? category(String? value) {
    if (value == null || value.isEmpty) {
      return AppStrings.selectCategory;
    }
    return null;
  }

  static String? reminderDateTime({
    required bool enabled,
    DateTime? reminderAt,
  }) {
    if (enabled && reminderAt == null) {
      return AppStrings.pickReminderDateTime;
    }
    return null;
  }

  static String? email(String? value) {
    final requiredError = required(value);
    if (requiredError != null) return requiredError;
    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
    if (!emailRegex.hasMatch(value!.trim())) {
      return AppStrings.invalidEmail;
    }
    return null;
  }

  static String? username(String? value) {
    final requiredError = required(value);
    if (requiredError != null) return requiredError;
    final trimmed = value!.trim();
    if (trimmed.length < 3) {
      return AppStrings.usernameTooShort;
    }
    if (!RegExp(r'^[a-zA-Z0-9_.]+$').hasMatch(trimmed)) {
      return AppStrings.usernameInvalidChars;
    }
    return null;
  }

  static String? password(String? value) {
    final requiredError = required(value);
    if (requiredError != null) return requiredError;
    if (value!.length < 6) {
      return AppStrings.passwordTooShort;
    }
    return null;
  }

  static String? confirmPassword(String? value, String original) {
    final requiredError = required(value);
    if (requiredError != null) return requiredError;
    if (value != original) {
      return AppStrings.passwordsDoNotMatch;
    }
    return null;
  }

  static String? positiveNumber(String? value, {String? message}) {
    final requiredError = required(value);
    if (requiredError != null) return requiredError;
    final parsed = double.tryParse(value!.trim());
    if (parsed == null || parsed < 0) {
      return message ?? AppStrings.invalidQuantity;
    }
    return null;
  }

  static String? positiveAmount(String? value) {
    final requiredError = required(value);
    if (requiredError != null) return requiredError;
    final parsed = double.tryParse(value!.trim());
    if (parsed == null || parsed <= 0) {
      return AppStrings.invalidAmount;
    }
    return null;
  }
}
