import 'dart:async';

import 'package:flutter/material.dart';
import 'package:pivox/features/web_scraping/parallel/scraping_task.dart';
import 'package:pivox/features/web_scraping/parallel/task_scheduler.dart';

import 'scraping_progress_card.dart';
import 'scraping_summary_card.dart';

/// A dashboard widget that displays the progress of scraping tasks
class ScrapingDashboard extends StatefulWidget {
  /// The task scheduler to monitor
  final TaskScheduler scheduler;

  /// The refresh interval in milliseconds
  final int refreshIntervalMs;

  /// Callback when a task is cancelled
  final void Function(String taskId)? onCancelTask;

  /// Callback when a task is retried
  final void Function(String taskId)? onRetryTask;

  /// Callback when a task's details are viewed
  final void Function(ScrapingTask task)? onViewTaskDetails;

  /// Creates a new [ScrapingDashboard]
  const ScrapingDashboard({
    super.key,
    required this.scheduler,
    this.refreshIntervalMs = 1000,
    this.onCancelTask,
    this.onRetryTask,
    this.onViewTaskDetails,
  });

  @override
  State<ScrapingDashboard> createState() => _ScrapingDashboardState();
}

class _ScrapingDashboardState extends State<ScrapingDashboard> {
  List<ScrapingTask> _tasks = [];
  Timer? _refreshTimer;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _startRefreshTimer();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  void _startRefreshTimer() {
    _refreshTimer = Timer.periodic(
      Duration(milliseconds: widget.refreshIntervalMs),
      (_) => _refreshTasks(),
    );
    // Initial refresh
    _refreshTasks();
  }

  void _refreshTasks() {
    // This is a simplified approach - in a real app, you would
    // get the tasks from the scheduler through a proper API
    setState(() {
      // This is just a placeholder - the actual implementation would
      // depend on how the TaskScheduler exposes its tasks
      _tasks = []; // Replace with actual tasks from scheduler
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Summary card
        ScrapingSummaryCard(
          totalTasks: _tasks.length,
          queuedTasks: _tasks.where((t) => t.status == TaskStatus.queued).length,
          executingTasks: _tasks.where((t) => t.status == TaskStatus.executing).length,
          completedTasks: _tasks.where((t) => t.status == TaskStatus.completed).length,
          failedTasks: _tasks.where((t) => t.status == TaskStatus.failed).length,
          cancelledTasks: _tasks.where((t) => t.status == TaskStatus.cancelled).length,
        ),
        
        // Header with expand/collapse button
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Active Tasks',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              IconButton(
                icon: Icon(_isExpanded ? Icons.expand_less : Icons.expand_more),
                onPressed: () {
                  setState(() {
                    _isExpanded = !_isExpanded;
                  });
                },
                tooltip: _isExpanded ? 'Show less' : 'Show more',
              ),
            ],
          ),
        ),
        
        // Task list
        AnimatedCrossFade(
          duration: const Duration(milliseconds: 300),
          crossFadeState: _isExpanded 
              ? CrossFadeState.showSecond 
              : CrossFadeState.showFirst,
          firstChild: _buildCollapsedTaskList(),
          secondChild: _buildExpandedTaskList(),
        ),
      ],
    );
  }

  Widget _buildCollapsedTaskList() {
    // Show only executing tasks in collapsed view
    final executingTasks = _tasks
        .where((t) => t.status == TaskStatus.executing)
        .toList();
    
    if (executingTasks.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Text('No active tasks'),
      );
    }
    
    return Column(
      children: executingTasks
          .take(3) // Show at most 3 tasks
          .map((task) => ScrapingProgressCard(
                task: task,
                onCancel: widget.onCancelTask != null 
                    ? () => widget.onCancelTask!(task.id) 
                    : null,
                onViewDetails: widget.onViewTaskDetails != null 
                    ? () => widget.onViewTaskDetails!(task) 
                    : null,
              ))
          .toList(),
    );
  }

  Widget _buildExpandedTaskList() {
    if (_tasks.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Text('No tasks'),
      );
    }
    
    // Group tasks by status
    final groupedTasks = <TaskStatus, List<ScrapingTask>>{};
    for (final task in _tasks) {
      groupedTasks.putIfAbsent(task.status, () => []).add(task);
    }
    
    return ListView(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        // Executing tasks
        if (groupedTasks[TaskStatus.executing]?.isNotEmpty ?? false)
          _buildTaskGroup('Executing', groupedTasks[TaskStatus.executing]!),
        
        // Queued tasks
        if (groupedTasks[TaskStatus.queued]?.isNotEmpty ?? false)
          _buildTaskGroup('Queued', groupedTasks[TaskStatus.queued]!),
        
        // Failed tasks
        if (groupedTasks[TaskStatus.failed]?.isNotEmpty ?? false)
          _buildTaskGroup('Failed', groupedTasks[TaskStatus.failed]!),
        
        // Completed tasks
        if (groupedTasks[TaskStatus.completed]?.isNotEmpty ?? false)
          _buildTaskGroup('Completed', groupedTasks[TaskStatus.completed]!),
        
        // Cancelled tasks
        if (groupedTasks[TaskStatus.cancelled]?.isNotEmpty ?? false)
          _buildTaskGroup('Cancelled', groupedTasks[TaskStatus.cancelled]!),
      ],
    );
  }

  Widget _buildTaskGroup(String title, List<ScrapingTask> tasks) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            '$title (${tasks.length})',
            style: Theme.of(context).textTheme.titleSmall,
          ),
        ),
        ...tasks.map((task) => ScrapingProgressCard(
              task: task,
              onCancel: task.status != TaskStatus.completed && 
                        task.status != TaskStatus.cancelled && 
                        task.status != TaskStatus.failed && 
                        widget.onCancelTask != null 
                  ? () => widget.onCancelTask!(task.id) 
                  : null,
              onRetry: task.status == TaskStatus.failed && 
                       widget.onRetryTask != null 
                  ? () => widget.onRetryTask!(task.id) 
                  : null,
              onViewDetails: widget.onViewTaskDetails != null 
                  ? () => widget.onViewTaskDetails!(task) 
                  : null,
            )),
      ],
    );
  }
}
