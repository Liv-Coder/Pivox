import 'dart:async';

import '../../../core/utils/logger.dart';
import '../rate_limiting/rate_limiter.dart';
import 'resource_monitor.dart';
import 'scraping_task.dart';

/// Configuration for the task scheduler
class TaskSchedulerConfig {
  /// The maximum number of concurrent tasks
  final int maxConcurrentTasks;

  /// The maximum number of concurrent tasks per domain
  final int maxConcurrentTasksPerDomain;

  /// Whether to use adaptive concurrency based on system resources
  final bool useAdaptiveConcurrency;

  /// The minimum concurrency level when using adaptive concurrency
  final int minConcurrencyLevel;

  /// The maximum concurrency level when using adaptive concurrency
  final int maxConcurrencyLevel;

  /// The CPU usage threshold for reducing concurrency (0.0 to 1.0)
  final double cpuThreshold;

  /// The memory usage threshold for reducing concurrency (0.0 to 1.0)
  final double memoryThreshold;

  /// The interval for checking system resources in milliseconds
  final int resourceCheckIntervalMs;

  /// Creates a new [TaskSchedulerConfig]
  const TaskSchedulerConfig({
    this.maxConcurrentTasks = 10,
    this.maxConcurrentTasksPerDomain = 2,
    this.useAdaptiveConcurrency = true,
    this.minConcurrencyLevel = 1,
    this.maxConcurrencyLevel = 20,
    this.cpuThreshold = 0.8,
    this.memoryThreshold = 0.8,
    this.resourceCheckIntervalMs = 5000,
  });

  /// Creates a [TaskSchedulerConfig] for low resource usage
  factory TaskSchedulerConfig.conservative() {
    return const TaskSchedulerConfig(
      maxConcurrentTasks: 5,
      maxConcurrentTasksPerDomain: 1,
      useAdaptiveConcurrency: true,
      minConcurrencyLevel: 1,
      maxConcurrencyLevel: 10,
      cpuThreshold: 0.7,
      memoryThreshold: 0.7,
    );
  }

  /// Creates a [TaskSchedulerConfig] for high resource usage
  factory TaskSchedulerConfig.aggressive() {
    return const TaskSchedulerConfig(
      maxConcurrentTasks: 20,
      maxConcurrentTasksPerDomain: 4,
      useAdaptiveConcurrency: true,
      minConcurrencyLevel: 2,
      maxConcurrencyLevel: 30,
      cpuThreshold: 0.9,
      memoryThreshold: 0.9,
    );
  }
}

/// A scheduler for managing concurrent scraping tasks
class TaskScheduler {
  /// The configuration for the scheduler
  final TaskSchedulerConfig config;

  /// The rate limiter to use for domain-specific rate limiting
  final RateLimiter rateLimiter;

  /// The resource monitor to use for adaptive concurrency
  final ResourceMonitor resourceMonitor;

  /// Logger for logging operations
  final Logger? logger;

  /// The list of tasks, sorted by priority
  final List<ScrapingTask> _taskList = [];

  /// The currently executing tasks
  final Set<ScrapingTask> _executingTasks = {};

  /// The tasks by domain
  final Map<String, Set<ScrapingTask>> _tasksByDomain = {};

  /// The current concurrency level
  int _currentConcurrencyLevel;

  /// Whether the scheduler is running
  bool _isRunning = false;

  /// The timer for checking system resources
  Timer? _resourceCheckTimer;

  /// Creates a new [TaskScheduler]
  TaskScheduler({
    required this.rateLimiter,
    required this.resourceMonitor,
    this.config = const TaskSchedulerConfig(),
    this.logger,
  }) : _currentConcurrencyLevel = config.maxConcurrentTasks;

  /// Gets the number of queued tasks
  int get queuedTaskCount => _taskList.length;

  /// Gets the number of executing tasks
  int get executingTaskCount => _executingTasks.length;

  /// Gets the total number of tasks
  int get totalTaskCount => queuedTaskCount + executingTaskCount;

  /// Gets whether the scheduler is running
  bool get isRunning => _isRunning;

  /// Gets the current concurrency level
  int get currentConcurrencyLevel => _currentConcurrencyLevel;

  /// Starts the scheduler
  void start() {
    if (_isRunning) return;

    _isRunning = true;
    logger?.info('Task scheduler started');

    // Start the resource check timer if adaptive concurrency is enabled
    if (config.useAdaptiveConcurrency) {
      _resourceCheckTimer = Timer.periodic(
        Duration(milliseconds: config.resourceCheckIntervalMs),
        (_) => _updateConcurrencyLevel(),
      );
    }

    // Start processing tasks
    _processNextTask();
  }

  /// Stops the scheduler
  void stop() {
    if (!_isRunning) return;

    _isRunning = false;
    logger?.info('Task scheduler stopped');

    // Cancel the resource check timer
    _resourceCheckTimer?.cancel();
    _resourceCheckTimer = null;
  }

  /// Enqueues a task
  Future<T> enqueue<T>(ScrapingTask<T> task) {
    // Add the task to the list
    _taskList.add(task);

    // Sort the list by priority and creation time
    _taskList.sort((a, b) {
      // First compare by priority (higher priority first)
      final priorityComparison = a.priority.index.compareTo(b.priority.index);
      if (priorityComparison != 0) {
        return priorityComparison;
      }

      // Then compare by creation time (older first)
      return a.createdAt.compareTo(b.createdAt);
    });

    // Add the task to the domain map
    _tasksByDomain.putIfAbsent(task.domain, () => {}).add(task);

    // Update the task status
    task.status = TaskStatus.queued;
    logger?.info('Task ${task.id} enqueued (priority: ${task.priority})');

    // Process the next task if the scheduler is running
    if (_isRunning) {
      _processNextTask();
    }

    return task.future;
  }

  /// Cancels a task
  void cancel(String taskId) {
    // Find the task in the list
    final taskIndex = _taskList.indexWhere((t) => t.id == taskId);
    ScrapingTask? task;

    if (taskIndex >= 0) {
      // Task is in the list
      task = _taskList[taskIndex];
    } else {
      // Task might be executing
      task = _executingTasks.firstWhere(
        (t) => t.id == taskId,
        orElse: () => throw Exception('Task not found: $taskId'),
      );
    }

    // Cancel the task
    task.cancel();

    // Remove the task from the list if it's still there
    if (taskIndex >= 0) {
      _taskList.removeAt(taskIndex);
    }

    // Remove the task from the executing tasks if it's there
    _executingTasks.remove(task);

    // Remove the task from the domain map
    _tasksByDomain[task.domain]?.remove(task);
    if (_tasksByDomain[task.domain]?.isEmpty ?? false) {
      _tasksByDomain.remove(task.domain);
    }

    logger?.info('Task $taskId cancelled');
  }

  /// Cancels all tasks
  void cancelAll() {
    // Cancel all tasks in the list
    for (final task in _taskList) {
      task.cancel();
    }

    // Cancel all executing tasks
    for (final task in _executingTasks) {
      task.cancel();
    }

    // Clear the list and executing tasks
    _taskList.clear();
    _executingTasks.clear();
    _tasksByDomain.clear();

    logger?.info('All tasks cancelled');
  }

  /// Processes the next task in the queue
  void _processNextTask() {
    if (!_isRunning) return;

    // Check if we can execute more tasks
    if (_executingTasks.length >= _currentConcurrencyLevel) {
      return;
    }

    // Find the next task that can be executed
    ScrapingTask? nextTask;

    for (final task in _taskList) {
      // Skip tasks that have already been processed
      if (task.processed) continue;

      // Skip tasks that can't be executed
      if (!task.canExecute) continue;

      // Skip tasks whose dependencies aren't complete
      if (!task.areDependenciesComplete) continue;

      // Check domain-specific concurrency limits
      final domainTasks = _tasksByDomain[task.domain] ?? {};
      final executingDomainTasks =
          domainTasks.where((t) => t.status == TaskStatus.executing).toList();

      if (executingDomainTasks.length >= config.maxConcurrentTasksPerDomain) {
        continue;
      }

      // Check rate limits for the domain
      if (!_canMakeRequest(task.domain)) {
        continue;
      }

      // We found a task that can be executed
      nextTask = task;
      break;
    }

    // If we found a task, execute it
    if (nextTask != null) {
      // Mark the task as processed so we don't try to execute it again
      nextTask.markAsProcessed();

      // Remove the task from the list
      _taskList.remove(nextTask);

      // Add the task to the executing tasks
      _executingTasks.add(nextTask);

      // Execute the task
      nextTask
          .run()
          .then((_) {
            // Task completed successfully
            _onTaskCompleted(nextTask!);
          })
          .catchError((error) {
            // Task failed
            _onTaskFailed(nextTask!, error);
          });

      // Process the next task
      _processNextTask();
    }
  }

  /// Called when a task completes successfully
  void _onTaskCompleted(ScrapingTask task) {
    // Remove the task from the executing tasks
    _executingTasks.remove(task);

    // Remove the task from the domain map
    _tasksByDomain[task.domain]?.remove(task);
    if (_tasksByDomain[task.domain]?.isEmpty ?? false) {
      _tasksByDomain.remove(task.domain);
    }

    // Process the next task
    _processNextTask();
  }

  /// Called when a task fails
  void _onTaskFailed(ScrapingTask task, dynamic error) {
    // Remove the task from the executing tasks
    _executingTasks.remove(task);

    // If the task can be retried, add it back to the list
    if (task.retryCount < task.maxRetries) {
      task.status = TaskStatus.queued;
      _taskList.add(task);
      logger?.info(
        'Task ${task.id} requeued for retry (attempt ${task.retryCount}/${task.maxRetries})',
      );
    } else {
      // Remove the task from the domain map
      _tasksByDomain[task.domain]?.remove(task);
      if (_tasksByDomain[task.domain]?.isEmpty ?? false) {
        _tasksByDomain.remove(task.domain);
      }

      logger?.error('Task ${task.id} failed permanently: $error');
    }

    // Process the next task
    _processNextTask();
  }

  /// Checks if a request can be made to a domain
  bool _canMakeRequest(String domain) {
    // Simple implementation - always allow requests
    // In a real implementation, this would check rate limits
    return true;
  }

  /// Updates the concurrency level based on system resources
  void _updateConcurrencyLevel() {
    if (!config.useAdaptiveConcurrency) return;

    // Get the current resource usage
    final cpuUsage = resourceMonitor.cpuUsage;
    final memoryUsage = resourceMonitor.memoryUsage;

    // Calculate the new concurrency level
    int newLevel = _currentConcurrencyLevel;

    // Reduce concurrency if CPU or memory usage is too high
    if (cpuUsage > config.cpuThreshold ||
        memoryUsage > config.memoryThreshold) {
      newLevel = (newLevel * 0.8).round();
    }
    // Increase concurrency if resource usage is low
    else if (cpuUsage < config.cpuThreshold * 0.7 &&
        memoryUsage < config.memoryThreshold * 0.7) {
      newLevel = (newLevel * 1.2).round();
    }

    // Ensure the concurrency level is within bounds
    newLevel = newLevel.clamp(
      config.minConcurrencyLevel,
      config.maxConcurrencyLevel,
    );

    // Update the concurrency level if it changed
    if (newLevel != _currentConcurrencyLevel) {
      logger?.info(
        'Adjusting concurrency level from $_currentConcurrencyLevel to $newLevel '
        '(CPU: ${(cpuUsage * 100).toStringAsFixed(1)}%, '
        'Memory: ${(memoryUsage * 100).toStringAsFixed(1)}%)',
      );

      _currentConcurrencyLevel = newLevel;

      // Process the next task in case we can now execute more tasks
      _processNextTask();
    }
  }
}
