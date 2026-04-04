enum LogLevel {
  debug,
  info,
  warning,
  error,
  network,
  navigation,
  bloc,
}

class LogEntry {
  final DateTime timestamp;
  final LogLevel level;
  final String tag;
  final String message;
  final Object? error;
  final StackTrace? stackTrace;

  const LogEntry({
    required this.timestamp,
    required this.level,
    required this.tag,
    required this.message,
    this.error,
    this.stackTrace,
  });

  String get emoji {
    switch (level) {
      case LogLevel.debug:
        return '🔍';
      case LogLevel.info:
        return '💡';
      case LogLevel.warning:
        return '⚠️';
      case LogLevel.error:
        return '❌';
      case LogLevel.network:
        return '🌐';
      case LogLevel.navigation:
        return '🧭';
      case LogLevel.bloc:
        return '🧊';
    }
  }

  String get levelName {
    switch (level) {
      case LogLevel.debug:
        return 'DEBUG';
      case LogLevel.info:
        return 'INFO';
      case LogLevel.warning:
        return 'WARN';
      case LogLevel.error:
        return 'ERROR';
      case LogLevel.network:
        return 'HTTP';
      case LogLevel.navigation:
        return 'NAV';
      case LogLevel.bloc:
        return 'BLOC';
    }
  }

  String get formatted {
    final ts = '${timestamp.hour.toString().padLeft(2, '0')}:'
        '${timestamp.minute.toString().padLeft(2, '0')}:'
        '${timestamp.second.toString().padLeft(2, '0')}.'
        '${timestamp.millisecond.toString().padLeft(3, '0')}';
    final buf = StringBuffer('$emoji [$ts] [$levelName] [$tag] $message');
    if (error != null) {
      buf.write('\n    ⤷ Error: $error');
    }
    if (stackTrace != null) {
      final lines = stackTrace.toString().split('\n').take(5);
      for (final line in lines) {
        buf.write('\n    $line');
      }
    }
    return buf.toString();
  }
}
