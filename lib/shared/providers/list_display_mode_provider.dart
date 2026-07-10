import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _prefsPrefix = 'list_display_mode_';

enum ListDisplayMode { grid, list }

/// Persisted grid/list preference keyed per screen.
final listDisplayModeProvider = StateNotifierProvider.family<
    ListDisplayModeNotifier, ListDisplayMode, String>((ref, screenKey) {
  return ListDisplayModeNotifier(screenKey);
});

class ListDisplayModeKeys {
  ListDisplayModeKeys._();

  static const pantry = 'pantry';
  static const assets = 'assets';
  static const plans = 'plans';
  static const expenses = 'expenses';
  static const subscriptions = 'subscriptions';
  static const reminders = 'reminders';
}

class ListDisplayModeNotifier extends StateNotifier<ListDisplayMode> {
  ListDisplayModeNotifier(this._screenKey) : super(ListDisplayMode.grid) {
    _load();
  }

  final String _screenKey;

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      var stored = prefs.getString('$_prefsPrefix$_screenKey');
      if (stored == null && _screenKey == ListDisplayModeKeys.pantry) {
        stored = prefs.getString('pantry_view_mode');
      }
      if (stored == null) return;
      state = ListDisplayMode.values.firstWhere(
        (mode) => mode.name == stored,
        orElse: () => ListDisplayMode.grid,
      );
    } catch (_) {}
  }

  Future<void> setMode(ListDisplayMode mode) async {
    state = mode;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('$_prefsPrefix$_screenKey', mode.name);
    } catch (_) {}
  }

  Future<void> toggle() async {
    await setMode(
      state == ListDisplayMode.grid
          ? ListDisplayMode.list
          : ListDisplayMode.grid,
    );
  }
}
