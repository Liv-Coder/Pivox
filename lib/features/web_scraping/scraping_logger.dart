import 'dart:async';

/// Represents a log entry in the scraping process
class ScrapingLogEntry {
  /// The timestamp of the log entry
  final DateTime timestamp;

  /// The message of the log entry
  final String message;

  /// The type of log entry
  final LogType type;

  /// Creates a new [ScrapingLogEntry]
  ScrapingLogEntry({
    required this.message,
    required this.type,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  /// Creates a new info log entry
  factory ScrapingLogEntry.info(String message) {
    return ScrapingLogEntry(message: message, type: LogType.info);
  }

  /// Creates a new warning log entry
  factory ScrapingLogEntry.warning(String message) {
    return ScrapingLogEntry(message: message, type: LogType.warning);
  }

  /// Creates a new error log entry
  factory ScrapingLogEntry.error(String message) {
    return ScrapingLogEntry(message: message, type: LogType.error);
  }

  /// Creates a new success log entry
  factory ScrapingLogEntry.success(String message) {
    return ScrapingLogEntry(message: message, type: LogType.success);
  }

  /// Creates a new proxy log entry
  factory ScrapingLogEntry.proxy(String message) {
    return ScrapingLogEntry(message: message, type: LogType.proxy);
  }

  /// Creates a new connection log entry
  factory ScrapingLogEntry.connection(String message) {
    return ScrapingLogEntry(message: message, type: LogType.connection);
  }

  /// Creates a new request log entry
  factory ScrapingLogEntry.request(String message) {
    return ScrapingLogEntry(message: message, type: LogType.request);
  }

  /// Creates a new response log entry
  factory ScrapingLogEntry.response(String message) {
    return ScrapingLogEntry(message: message, type: LogType.response);
  }

  @override
  String toString() {
    final formattedTime =
        '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}:${timestamp.second.toString().padLeft(2, '0')}';
    return '[$formattedTime] [${type.name.toUpperCase()}] $message';
  }
}

/// The type of log entry
enum LogType {
  /// Informational log entry
  info,

  /// Warning log entry
  warning,

  /// Error log entry
  error,

  /// Success log entry
  success,

  /// Proxy-related log entry
  proxy,

  /// Connection-related log entry
  connection,

  /// Request-related log entry
  request,

  /// Response-related log entry
  response,
}

/// A logger for scraping operations
class ScrapingLogger {
  /// The maximum number of log entries to keep
  final int _maxEntries;

  /// The log entries
  final List<ScrapingLogEntry> _entries = [];

  /// Stream controller for log entries
  final StreamController<ScrapingLogEntry> _controller =
      StreamController<ScrapingLogEntry>.broadcast();

  /// Creates a new [ScrapingLogger]
  ScrapingLogger({int maxEntries = 1000}) : _maxEntries = maxEntries;

  /// Gets the log entries
  List<ScrapingLogEntry> get entries => List.unmodifiable(_entries);

  /// Gets a stream of log entries
  Stream<ScrapingLogEntry> get onLog => _controller.stream;

  /// Logs an info message
  void info(String message) {
    _log(ScrapingLogEntry.info(message));
  }

  /// Logs a warning message
  void warning(String message) {
    _log(ScrapingLogEntry.warning(message));
  }

  /// Logs an error message
  void error(String message) {
    _log(ScrapingLogEntry.error(message));
  }

  /// Logs a success message
  void success(String message) {
    _log(ScrapingLogEntry.success(message));
  }

  /// Logs a proxy-related message
  void proxy(String message) {
    _log(ScrapingLogEntry.proxy(message));
  }

  /// Logs a connection-related message
  void connection(String message) {
    _log(ScrapingLogEntry.connection(message));
  }

  /// Logs a request-related message
  void request(String message) {
    _log(ScrapingLogEntry.request(message));
  }

  /// Logs a response-related message
  void response(String message) {
    _log(ScrapingLogEntry.response(message));
  }

  /// Logs an entry
  void _log(ScrapingLogEntry entry) {
    _entries.add(entry);
    _controller.add(entry);

    // Prune old entries if needed
    if (_entries.length > _maxEntries) {
      _entries.removeRange(0, _entries.length - _maxEntries);
    }
  }

  /// Clears all log entries
  void clear() {
    _entries.clear();
    _log(ScrapingLogEntry.info('Log cleared'));
  }

  /// Disposes the logger
  void dispose() {
    _controller.close();
  }
}
