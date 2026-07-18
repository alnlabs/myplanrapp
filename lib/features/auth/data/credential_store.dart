import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../core/logging/app_logger.dart';

/// A login identifier + password pair remembered on the device.
class SavedCredentials {
  const SavedCredentials({required this.identifier, required this.password});

  final String identifier;
  final String password;
}

/// Persists login credentials in the platform keychain / keystore so the user
/// can opt in to being remembered between sessions.
///
/// All operations fail soft: any platform error (e.g. unavailable secure
/// storage or a missing plugin in tests) is swallowed so it never blocks login.
class CredentialStore {
  CredentialStore([FlutterSecureStorage? storage])
      : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(encryptedSharedPreferences: true),
            );

  final FlutterSecureStorage _storage;

  static const _identifierKey = 'saved_login_identifier';
  static const _passwordKey = 'saved_login_password';

  Future<SavedCredentials?> read() async {
    try {
      final identifier = await _storage.read(key: _identifierKey);
      final password = await _storage.read(key: _passwordKey);
      if (identifier == null ||
          identifier.isEmpty ||
          password == null ||
          password.isEmpty) {
        return null;
      }
      return SavedCredentials(identifier: identifier, password: password);
    } catch (e) {
      AppLogger.instance.error('Failed to read saved credentials', e);
      return null;
    }
  }

  Future<void> save({
    required String identifier,
    required String password,
  }) async {
    try {
      await _storage.write(key: _identifierKey, value: identifier);
      await _storage.write(key: _passwordKey, value: password);
    } catch (e) {
      AppLogger.instance.error('Failed to save credentials', e);
    }
  }

  Future<void> clear() async {
    try {
      await _storage.delete(key: _identifierKey);
      await _storage.delete(key: _passwordKey);
    } catch (e) {
      AppLogger.instance.error('Failed to clear saved credentials', e);
    }
  }
}

final credentialStoreProvider = Provider<CredentialStore>(
  (ref) => CredentialStore(),
);
