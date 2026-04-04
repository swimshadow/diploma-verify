import 'dart:collection';
import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';

import 'log_entry.dart';

/// Central logging service for the entire application.
///
/// Features:
///   • Colored, emoji-prefixed console output
///   • In-memory circular buffer (last [maxEntries] entries)
///   • Sensitive data redaction (tokens, passwords)
///   • Singleton access via [AppLogger.instance]
///   • Listeners for live log viewer updates
class AppLogger {
  AppLogger._();
  static final AppLogger instance = AppLogger._();

  static const int maxEntries = 1000;

  final _entries = Queue<LogEntry>();
  final _listeners = <VoidCallback>[];

  /// All buffered log entries (newest last).
  List<LogEntry> get entries => _entries.toList();

  /// Register a listener for new log entries.
  void addListener(VoidCallback listener) => _listeners.add(listener);

  /// Remove a previously registered listener.
  void removeListener(VoidCallback listener) => _listeners.remove(listener);

  void clear() {
    _entries.clear();
    _notifyListeners();
  }

  // ─── Convenience methods ────────────────────────────────────

  void debug(String tag, String message) =>
      _log(LogLevel.debug, tag, message);

  void info(String tag, String message) =>
      _log(LogLevel.info, tag, message);

  void warning(String tag, String message, [Object? error]) =>
      _log(LogLevel.warning, tag, message, error: error);

  void error(String tag, String message,
          [Object? error, StackTrace? stackTrace]) =>
      _log(LogLevel.error, tag, message,
          error: error, stackTrace: stackTrace);

  void network(String tag, String message) =>
      _log(LogLevel.network, tag, message);

  void navigation(String tag, String message) =>
      _log(LogLevel.navigation, tag, message);

  void bloc(String tag, String message) =>
      _log(LogLevel.bloc, tag, message);

  // ─── Internal ───────────────────────────────────────────────

  static final _sensitivePattern = RegExp(
    r'(password|token|secret|authorization|cookie|_enc)'
    r'[\s]*[=:]\s*["\x27]?([^\s"\x27,}\]]{6})[^\s"\x27,}\]]*',
    caseSensitive: false,
  );

  static String redact(String input) {
    return input.replaceAllMapped(_sensitivePattern, (m) {
      final key = m.group(1)!;
      final prefix = m.group(2)!;
      return '$key: "$prefix***"';
    });
  }

  void _log(
    LogLevel level,
    String tag,
    String message, {
    Object? error,
    StackTrace? stackTrace,
  }) {
    final entry = LogEntry(
      timestamp: DateTime.now(),
      level: level,
      tag: tag,
      message: redact(message),
      error: error,
      stackTrace: stackTrace,
    );

    // Circular buffer: drop oldest if full
    if (_entries.length >= maxEntries) {
      _entries.removeFirst();
    }
    _entries.addLast(entry);

    // Console output (only in debug mode)
    if (kDebugMode) {
      final ansiColor = _ansiColor(level);
      const reset = '\x1B[0m';
      developer.log(
        '$ansiColor${entry.formatted}$reset',
        name: 'DiplomaVerify',
      );
    }

    _notifyListeners();
  }

  static String _ansiColor(LogLevel level) {
    switch (level) {
      case LogLevel.debug:
        return '\x1B[37m'; // white
      case LogLevel.info:
        return '\x1B[36m'; // cyan
      case LogLevel.warning:
        return '\x1B[33m'; // yellow
      case LogLevel.error:
        return '\x1B[31m'; // red
      case LogLevel.network:
        return '\x1B[35m'; // magenta
      case LogLevel.navigation:
        return '\x1B[34m'; // blue
      case LogLevel.bloc:
        return '\x1B[32m'; // green
    }
  }

  void _notifyListeners() {
    for (final listener in _listeners) {
      listener();
    }
  }
}
