/// Logger levels
enum LogLevel {
  /// Trace level for very detailed information
  trace,

  /// Fine level for detailed information
  fine,

  /// Debug level for detailed information
  debug,

  /// Info level for general information
  info,

  /// Warning level for potential issues
  warning,

  /// Error level for errors that don't stop the application
  error,

  /// Fatal level for errors that stop the application
  fatal,
}

/// Simple logger class for logging messages
class Logger {
  /// The name of the logger
  final String name;

  /// The minimum log level to display
  final LogLevel minLevel;

  /// Whether to include timestamps in log messages
  final bool includeTimestamps;

  /// Whether to include the logger name in log messages
  final bool includeLoggerName;

  /// Creates a new [Logger] with the given parameters
  Logger(
    this.name, {
    this.minLevel = LogLevel.info,
    this.includeTimestamps = true,
    this.includeLoggerName = true,
  });

  /// Logs a trace message
  void trace(String message) {
    _log(LogLevel.trace, message);
  }

  /// Logs a fine message
  void fine(String message) {
    _log(LogLevel.fine, message);
  }

  /// Logs a debug message
  void debug(String message) {
    _log(LogLevel.debug, message);
  }

  /// Logs an info message
  void info(String message) {
    _log(LogLevel.info, message);
  }

  /// Logs a warning message
  void warning(String message) {
    _log(LogLevel.warning, message);
  }

  /// Logs an error message
  void error(String message) {
    _log(LogLevel.error, message);
  }

  /// Logs a fatal message
  void fatal(String message) {
    _log(LogLevel.fatal, message);
  }

  /// Logs a message with the given level
  void _log(LogLevel level, String message) {
    if (level.index < minLevel.index) {
      return;
    }

    final buffer = StringBuffer();

    if (includeTimestamps) {
      buffer.write('[${DateTime.now().toIso8601String()}] ');
    }

    buffer.write('${_getLevelPrefix(level)} ');

    if (includeLoggerName) {
      buffer.write('[$name] ');
    }

    buffer.write(message);

    // In a real implementation, you might want to use a proper logging framework
    // or write to a file, but for simplicity we'll just log to the console
    // ignore: avoid_print
    print(buffer.toString());
  }

  /// Gets the prefix for the given log level
  String _getLevelPrefix(LogLevel level) {
    switch (level) {
      case LogLevel.trace:
        return '[TRACE]';
      case LogLevel.fine:
        return '[FINE]';
      case LogLevel.debug:
        return '[DEBUG]';
      case LogLevel.info:
        return '[INFO]';
      case LogLevel.warning:
        return '[WARN]';
      case LogLevel.error:
        return '[ERROR]';
      case LogLevel.fatal:
        return '[FATAL]';
    }
  }
}
