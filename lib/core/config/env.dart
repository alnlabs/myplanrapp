import 'package:flutter_dotenv/flutter_dotenv.dart';

class Env {
  static String get supabaseUrl => dotenv.env['SUPABASE_URL'] ?? '';
  static String get supabaseAnonKey => dotenv.env['SUPABASE_ANON_KEY'] ?? '';

  static bool get isConfigured =>
      supabaseUrl.isNotEmpty &&
      supabaseAnonKey.isNotEmpty &&
      !supabaseUrl.contains('your-project');

  /// PIN required to open in-app diagnostic logs (set in .env).
  static String get diagnosticLogsPin => dotenv.env['DIAGNOSTIC_LOGS_PIN'] ?? '';

  static bool get isLogsPinConfigured => diagnosticLogsPin.isNotEmpty;

  static bool matchesLogsPin(String input) =>
      isLogsPinConfigured && input == diagnosticLogsPin;
}
