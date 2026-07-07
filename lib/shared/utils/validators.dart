import '../../core/strings/app_strings.dart';

class Validators {
  Validators._();

  static String? required(String? value) {
    if (value == null || value.trim().isEmpty) {
      return AppStrings.requiredField;
    }
    return null;
  }

  static String? email(String? value) {
    final requiredError = required(value);
    if (requiredError != null) return requiredError;
    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
    if (!emailRegex.hasMatch(value!.trim())) {
      return 'Enter a valid email address';
    }
    return null;
  }

  static String? username(String? value) {
    final requiredError = required(value);
    if (requiredError != null) return requiredError;
    final trimmed = value!.trim();
    if (trimmed.length < 3) {
      return 'Username must be at least 3 characters';
    }
    if (!RegExp(r'^[a-zA-Z0-9_.]+$').hasMatch(trimmed)) {
      return 'Use only letters, numbers, dot, or underscore';
    }
    return null;
  }

  static String? password(String? value) {
    final requiredError = required(value);
    if (requiredError != null) return requiredError;
    if (value!.length < 6) {
      return 'Password must be at least 6 characters';
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
