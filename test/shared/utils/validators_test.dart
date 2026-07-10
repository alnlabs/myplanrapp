import 'package:flutter_test/flutter_test.dart';
import 'package:myplanr/core/strings/app_strings.dart';
import 'package:myplanr/shared/utils/validators.dart';

void main() {
  group('Validators.required', () {
    test('rejects null, empty, whitespace', () {
      expect(Validators.required(null), AppStrings.requiredField);
      expect(Validators.required(''), AppStrings.requiredField);
      expect(Validators.required('  '), AppStrings.requiredField);
    });

    test('accepts non-empty value', () {
      expect(Validators.required('hello'), isNull);
    });
  });

  group('Validators.email', () {
    test('rejects invalid emails', () {
      expect(Validators.email(null), AppStrings.requiredField);
      expect(Validators.email('bad'), AppStrings.invalidEmail);
      expect(Validators.email('a@b'), AppStrings.invalidEmail);
    });

    test('accepts valid email', () {
      expect(Validators.email('user@example.com'), isNull);
    });
  });

  group('Validators.username', () {
    test('rejects short and invalid chars', () {
      expect(Validators.username('ab'), AppStrings.usernameTooShort);
      expect(Validators.username('bad name'), AppStrings.usernameInvalidChars);
    });

    test('accepts valid username', () {
      expect(Validators.username('user_123'), isNull);
    });
  });

  group('Validators.password', () {
    test('rejects short password', () {
      expect(Validators.password('12345'), AppStrings.passwordTooShort);
    });

    test('accepts password with 6+ chars', () {
      expect(Validators.password('secret'), isNull);
    });
  });

  group('Validators.confirmPassword', () {
    test('rejects mismatch', () {
      expect(
        Validators.confirmPassword('other', 'original'),
        AppStrings.passwordsDoNotMatch,
      );
    });

    test('accepts match', () {
      expect(Validators.confirmPassword('same', 'same'), isNull);
    });
  });

  group('Validators.reminderDateTime', () {
    test('requires date when enabled', () {
      expect(
        Validators.reminderDateTime(enabled: true, reminderAt: null),
        AppStrings.pickReminderDateTime,
      );
    });

    test('allows null when disabled', () {
      expect(
        Validators.reminderDateTime(enabled: false, reminderAt: null),
        isNull,
      );
    });
  });

  group('Validators.requiredSelection', () {
    test('rejects null and empty', () {
      expect(Validators.requiredSelection(null), AppStrings.requiredField);
      expect(Validators.requiredSelection(''), AppStrings.requiredField);
    });

    test('accepts selection', () {
      expect(Validators.requiredSelection('id-1'), isNull);
    });
  });
}
