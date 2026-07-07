import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum LogLevel { debug, info, warning, error }

extension LogLevelLabel on LogLevel {
  String get label {
    switch (this) {
      case LogLevel.debug:
        return 'DEBUG';
      case LogLevel.info:
        return 'INFO';
      case LogLevel.warning:
        return 'WARN';
      case LogLevel.error:
        return 'ERROR';
    }
  }
}

class LogEntry {
  LogEntry({
    required this.time,
    required this.level,
    required this.message,
    this.error,
    this.stackTrace,
  });

  final DateTime time;
  final LogLevel level;
  final String message;
  final String? error;
  final String? stackTrace;

  Map<String, dynamic> toJson() => {
        't': time.millisecondsSinceEpoch,
        'l': level.index,
        'm': message,
        if (error != null) 'e': error,
        if (stackTrace != null) 's': stackTrace,
      };

  factory LogEntry.fromJson(Map<String, dynamic> json) {
    return LogEntry(
      time: DateTime.fromMillisecondsSinceEpoch((json['t'] as num).toInt()),
      level: LogLevel.values[(json['l'] as num?)?.toInt() ?? 0],
      message: json['m'] as String? ?? '',
      error: json['e'] as String?,
      stackTrace: json['s'] as String?,
    );
  }

  String format() {
    final ts = time.toIso8601String();
    final buffer = StringBuffer('[$ts] ${level.label}  $message');
    if (error != null && error!.isNotEmpty) {
      buffer.write('\n    error: $error');
    }
    if (stackTrace != null && stackTrace!.isNotEmpty) {
      buffer.write('\n    $stackTrace');
    }
    return buffer.toString();
  }
}

/// In-app diagnostic logger. Captures logs in a capped ring buffer that is
/// persisted across restarts, so issues can be inspected on release builds
/// where the console is unavailable.
class AppLogger {
  AppLogger._();

  static final AppLogger instance = AppLogger._();

  static const _prefsKey = 'diagnostic_logs_v1';
  static const _maxEntries = 500;

  final ValueNotifier<List<LogEntry>> entries = ValueNotifier<List<LogEntry>>([]);

  SharedPreferences? _prefs;
  bool _initialized = false;
  Timer? _saveDebounce;
  bool _saving = false;
  bool _pendingSave = false;

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;
    try {
      _prefs = await SharedPreferences.getInstance();
      final raw = _prefs?.getString(_prefsKey);
      if (raw != null && raw.isNotEmpty) {
        final decoded = jsonDecode(raw) as List<dynamic>;
        entries.value = decoded
            .map((e) => LogEntry.fromJson(e as Map<String, dynamic>))
            .toList();
      }
    } catch (_) {
      // Never let logging break startup.
    }
  }

  void debug(String message) => _add(LogLevel.debug, message);

  void info(String message) => _add(LogLevel.info, message);

  void warning(String message, [Object? error, StackTrace? stack]) =>
      _add(LogLevel.warning, message, error, stack);

  void error(String message, [Object? error, StackTrace? stack]) =>
      _add(LogLevel.error, message, error, stack);

  void _add(LogLevel level, String message,
      [Object? error, StackTrace? stack]) {
    final entry = LogEntry(
      time: DateTime.now(),
      level: level,
      message: message,
      error: error?.toString(),
      stackTrace: stack?.toString(),
    );
    final next = [...entries.value, entry];
    if (next.length > _maxEntries) {
      next.removeRange(0, next.length - _maxEntries);
    }
    entries.value = next;
    _scheduleSave();
  }

  void _scheduleSave() {
    _saveDebounce?.cancel();
    _saveDebounce = Timer(const Duration(seconds: 2), _save);
  }

  Future<void> _save() async {
    if (_prefs == null) return;
    if (_saving) {
      _pendingSave = true;
      return;
    }
    _saving = true;
    try {
      final data = jsonEncode(entries.value.map((e) => e.toJson()).toList());
      await _prefs!.setString(_prefsKey, data);
    } catch (_) {
      // Ignore persistence failures.
    } finally {
      _saving = false;
      if (_pendingSave) {
        _pendingSave = false;
        await _save();
      }
    }
  }

  Future<void> clear() async {
    entries.value = [];
    _saveDebounce?.cancel();
    try {
      await _prefs?.remove(_prefsKey);
    } catch (_) {}
  }

  String exportText() {
    if (entries.value.isEmpty) return 'No logs captured.';
    return entries.value.map((e) => e.format()).join('\n');
  }
}
