import 'dart:async';
import 'dart:collection';

import 'scraping_logger.dart';

/// A task queue for web scraping with concurrency control
class ScrapingTaskQueue {
  /// The maximum number of concurrent tasks
  final int maxConcurrentTasks;

  /// The queue of pending tasks
  final Queue<_ScrapingTask> _pendingTasks = Queue<_ScrapingTask>();

  /// The number of currently running tasks
  int _runningTasks = 0;

  /// The logger for scraping operations
  final ScrapingLogger _logger;

  /// Creates a new [ScrapingTaskQueue] with the given parameters
  ///
  /// [maxConcurrentTasks] is the maximum number of concurrent tasks
  /// [logger] is the logger for scraping operations
  ScrapingTaskQueue({this.maxConcurrentTasks = 5, ScrapingLogger? logger})
    : _logger = logger ?? ScrapingLogger();

  /// Adds a task to the queue
  ///
  /// [task] is the function to execute
  /// [priority] is the priority of the task (higher values = higher priority)
  /// [taskName] is an optional name for the task (for logging)
  /// [onStart] is an optional callback for when the task starts
  /// [onComplete] is an optional callback for when the task completes
  /// [onError] is an optional callback for when the task fails
  Future<T> addTask<T>({
    required Future<T> Function() task,
    int priority = 0,
    String? taskName,
    void Function()? onStart,
    void Function(T result)? onComplete,
    void Function(dynamic error, StackTrace stackTrace)? onError,
  }) {
    final completer = Completer<T>();
    final name = taskName ?? 'Task-${DateTime.now().millisecondsSinceEpoch}';

    _logger.info('Adding task to queue: $name (priority: $priority)');

    final scrapingTask = _ScrapingTask<T>(
      task: task,
      completer: completer,
      priority: priority,
      name: name,
      onStart: onStart,
      onComplete: onComplete,
      onError: onError,
    );

    _pendingTasks.add(scrapingTask);
    _sortQueue();
    _processQueue();

    return completer.future;
  }

  /// Sorts the queue by priority (higher values = higher priority)
  void _sortQueue() {
    final sortedList =
        _pendingTasks.toList()..sort((a, b) {
          // First sort by priority (higher first)
          final priorityDiff = b.priority - a.priority;
          if (priorityDiff != 0) return priorityDiff;

          // Then sort by creation time (earlier first)
          return a.createdAt.compareTo(b.createdAt);
        });

    _pendingTasks.clear();
    _pendingTasks.addAll(sortedList);
  }

  /// Processes the queue
  void _processQueue() {
    _logger.info(
      'Processing queue: $_runningTasks running, ${_pendingTasks.length} pending',
    );

    while (_runningTasks < maxConcurrentTasks && _pendingTasks.isNotEmpty) {
      final task = _pendingTasks.removeFirst();
      _runningTasks++;

      _logger.info('Starting task: ${task.name}');
      task.onStart?.call();

      task.execute().then(
        (result) {
          _logger.info('Task completed: ${task.name}');
          task.onComplete?.call(result);
          _runningTasks--;
          _processQueue();
        },
        onError: (error, stackTrace) {
          _logger.error('Task failed: ${task.name} - $error');
          task.onError?.call(error, stackTrace);
          _runningTasks--;
          _processQueue();
        },
      );
    }
  }

  /// Gets the number of pending tasks
  int get pendingTaskCount => _pendingTasks.length;

  /// Gets the number of running tasks
  int get runningTaskCount => _runningTasks;

  /// Gets the total number of tasks (pending + running)
  int get totalTaskCount => _pendingTasks.length + _runningTasks;

  /// Clears all pending tasks
  void clearPendingTasks() {
    final tasks = List<_ScrapingTask>.from(_pendingTasks);
    _pendingTasks.clear();

    for (final task in tasks) {
      task.completer.completeError(Exception('Task cancelled: queue cleared'));
    }

    _logger.info('Cleared ${tasks.length} pending tasks');
  }
}

/// A task in the scraping task queue
class _ScrapingTask<T> {
  /// The function to execute
  final Future<T> Function() task;

  /// The completer for the task
  final Completer<T> completer;

  /// The priority of the task (higher values = higher priority)
  final int priority;

  /// The name of the task (for logging)
  final String name;

  /// The time when the task was created
  final DateTime createdAt = DateTime.now();

  /// Callback for when the task starts
  final void Function()? onStart;

  /// Callback for when the task completes
  final void Function(T result)? onComplete;

  /// Callback for when the task fails
  final void Function(dynamic error, StackTrace stackTrace)? onError;

  /// Creates a new [_ScrapingTask] with the given parameters
  _ScrapingTask({
    required this.task,
    required this.completer,
    required this.priority,
    required this.name,
    this.onStart,
    this.onComplete,
    this.onError,
  });

  /// Executes the task
  Future<T> execute() async {
    try {
      final result = await task();
      completer.complete(result);
      return result;
    } catch (e, stackTrace) {
      completer.completeError(e, stackTrace);
      rethrow;
    }
  }
}
