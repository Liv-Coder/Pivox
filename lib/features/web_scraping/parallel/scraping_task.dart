import 'dart:async';

import '../../../core/utils/logger.dart';
import '../scraping_exception.dart';

/// Priority levels for scraping tasks
enum TaskPriority {
  /// Critical tasks that should be executed immediately
  critical,

  /// High priority tasks
  high,

  /// Normal priority tasks
  normal,

  /// Low priority tasks
  low,

  /// Background tasks that can be delayed
  background,
}

/// Status of a scraping task
enum TaskStatus {
  /// Task is created but not yet queued
  created,

  /// Task is queued for execution
  queued,

  /// Task is currently executing
  executing,

  /// Task completed successfully
  completed,

  /// Task failed with an error
  failed,

  /// Task was cancelled
  cancelled,
}

/// A task for scraping operations
class ScrapingTask<T> {
  /// Unique identifier for the task
  final String id;

  /// The domain this task is associated with
  final String domain;

  /// The URL to scrape
  final String url;

  /// The priority of the task
  final TaskPriority priority;

  /// The function to execute for this task
  final Future<T> Function() execute;

  /// The maximum number of retry attempts
  final int maxRetries;

  /// The current retry count
  int retryCount = 0;

  /// The current status of the task
  TaskStatus status = TaskStatus.created;

  /// The result of the task
  T? result;

  /// The error that occurred during execution, if any
  dynamic error;

  /// The stack trace of the error, if any
  StackTrace? stackTrace;

  /// The time when the task was created
  final DateTime createdAt;

  /// The time when the task was started
  DateTime? startedAt;

  /// The time when the task was completed
  DateTime? completedAt;

  /// The completer for this task
  final Completer<T> _completer = Completer<T>();

  /// The dependencies of this task
  final List<ScrapingTask> dependencies;

  /// Whether this task has been processed
  bool _processed = false;

  /// Logger for logging operations
  final Logger? logger;

  /// Creates a new [ScrapingTask]
  ScrapingTask({
    required this.id,
    required this.domain,
    required this.url,
    required this.execute,
    this.priority = TaskPriority.normal,
    this.maxRetries = 3,
    this.dependencies = const [],
    this.logger,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  /// Gets the future for this task
  Future<T> get future => _completer.future;

  /// Gets whether this task is complete
  bool get isComplete => status == TaskStatus.completed || 
                        status == TaskStatus.failed || 
                        status == TaskStatus.cancelled;

  /// Gets whether this task can be executed
  bool get canExecute => status == TaskStatus.created || 
                        status == TaskStatus.queued || 
                        (status == TaskStatus.failed && retryCount < maxRetries);

  /// Gets whether this task's dependencies are complete
  bool get areDependenciesComplete => 
      dependencies.every((dep) => dep.isComplete);

  /// Gets whether this task has been processed
  bool get processed => _processed;

  /// Sets the task as processed
  void markAsProcessed() {
    _processed = true;
  }

  /// Executes the task
  Future<T> run() async {
    if (!canExecute) {
      throw ScrapingException.validation(
        'Task cannot be executed (status: $status, retries: $retryCount/$maxRetries)',
        isRetryable: false,
      );
    }

    // Check dependencies
    if (!areDependenciesComplete) {
      throw ScrapingException.validation(
        'Task dependencies are not complete',
        isRetryable: false,
      );
    }

    // Update status and start time
    status = TaskStatus.executing;
    startedAt = DateTime.now();
    logger?.info('Starting task $id for $url (priority: $priority)');

    try {
      // Execute the task
      final result = await execute();
      
      // Update status and completion time
      status = TaskStatus.completed;
      completedAt = DateTime.now();
      this.result = result;
      
      // Calculate execution time
      final executionTime = completedAt!.difference(startedAt!).inMilliseconds;
      logger?.info('Completed task $id in ${executionTime}ms');
      
      // Complete the future
      if (!_completer.isCompleted) {
        _completer.complete(result);
      }
      
      return result;
    } catch (e, st) {
      // Update status and error information
      status = TaskStatus.failed;
      error = e;
      stackTrace = st;
      completedAt = DateTime.now();
      
      // Log the error
      logger?.error('Task $id failed: $e');
      
      // Check if we can retry
      if (retryCount < maxRetries) {
        retryCount++;
        logger?.info('Retrying task $id (attempt $retryCount/$maxRetries)');
        return run();
      }
      
      // Complete the future with an error
      if (!_completer.isCompleted) {
        _completer.completeError(e, st);
      }
      
      rethrow;
    }
  }

  /// Cancels the task
  void cancel() {
    if (isComplete) return;
    
    status = TaskStatus.cancelled;
    completedAt = DateTime.now();
    logger?.info('Task $id cancelled');
    
    if (!_completer.isCompleted) {
      _completer.completeError(
        ScrapingException.validation(
          'Task was cancelled',
          isRetryable: false,
        ),
      );
    }
  }

  @override
  String toString() {
    return 'ScrapingTask{id: $id, domain: $domain, url: $url, priority: $priority, status: $status, retryCount: $retryCount/$maxRetries}';
  }
}
