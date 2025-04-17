import 'package:flutter/material.dart';
import 'package:pivox/features/web_scraping/parallel/scraping_task.dart';

/// A card widget that displays the progress of a scraping task
class ScrapingProgressCard extends StatelessWidget {
  /// The task to display progress for
  final ScrapingTask task;

  /// Callback when the cancel button is pressed
  final VoidCallback? onCancel;

  /// Callback when the retry button is pressed
  final VoidCallback? onRetry;

  /// Callback when the view details button is pressed
  final VoidCallback? onViewDetails;

  /// Creates a new [ScrapingProgressCard]
  const ScrapingProgressCard({
    super.key,
    required this.task,
    this.onCancel,
    this.onRetry,
    this.onViewDetails,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with task ID and status
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Task ${task.id.substring(0, 8)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                _buildStatusBadge(context),
              ],
            ),
            const SizedBox(height: 8),
            
            // URL
            Text(
              task.url,
              style: const TextStyle(
                color: Colors.blue,
                decoration: TextDecoration.underline,
              ),
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 16),
            
            // Progress indicator
            _buildProgressIndicator(context),
            const SizedBox(height: 16),
            
            // Action buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (task.status == TaskStatus.failed && onRetry != null)
                  TextButton.icon(
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                    onPressed: onRetry,
                  ),
                if (task.status != TaskStatus.completed && 
                    task.status != TaskStatus.cancelled && 
                    task.status != TaskStatus.failed && 
                    onCancel != null)
                  TextButton.icon(
                    icon: const Icon(Icons.cancel),
                    label: const Text('Cancel'),
                    onPressed: onCancel,
                  ),
                if (onViewDetails != null)
                  TextButton.icon(
                    icon: const Icon(Icons.info_outline),
                    label: const Text('Details'),
                    onPressed: onViewDetails,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Builds the status badge
  Widget _buildStatusBadge(BuildContext context) {
    Color color;
    IconData icon;
    String label;

    switch (task.status) {
      case TaskStatus.created:
        color = Colors.grey;
        icon = Icons.hourglass_empty;
        label = 'Created';
        break;
      case TaskStatus.queued:
        color = Colors.orange;
        icon = Icons.queue;
        label = 'Queued';
        break;
      case TaskStatus.executing:
        color = Colors.blue;
        icon = Icons.sync;
        label = 'Executing';
        break;
      case TaskStatus.completed:
        color = Colors.green;
        icon = Icons.check_circle;
        label = 'Completed';
        break;
      case TaskStatus.failed:
        color = Colors.red;
        icon = Icons.error;
        label = 'Failed (${task.retryCount}/${task.maxRetries})';
        break;
      case TaskStatus.cancelled:
        color = Colors.grey;
        icon = Icons.cancel;
        label = 'Cancelled';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(color: color, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  /// Builds the progress indicator
  Widget _buildProgressIndicator(BuildContext context) {
    // For executing tasks, show a linear progress indicator
    if (task.status == TaskStatus.executing) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const LinearProgressIndicator(),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Started: ${_formatTime(task.startedAt)}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              Text(
                'Priority: ${task.priority.toString().split('.').last}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ],
      );
    }

    // For completed tasks, show the execution time
    if (task.status == TaskStatus.completed && 
        task.startedAt != null && 
        task.completedAt != null) {
      final duration = task.completedAt!.difference(task.startedAt!);
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Completed in: ${_formatDuration(duration)}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          Text(
            'Finished: ${_formatTime(task.completedAt)}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      );
    }

    // For failed tasks, show the error message
    if (task.status == TaskStatus.failed) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Error: ${task.error.toString()}',
            style: const TextStyle(color: Colors.red),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            'Failed at: ${_formatTime(task.completedAt)}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      );
    }

    // For other statuses, show the creation time
    return Text(
      'Created: ${_formatTime(task.createdAt)}',
      style: Theme.of(context).textTheme.bodySmall,
    );
  }

  /// Formats a DateTime to a readable string
  String _formatTime(DateTime? dateTime) {
    if (dateTime == null) return 'N/A';
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}:${dateTime.second.toString().padLeft(2, '0')}';
  }

  /// Formats a Duration to a readable string
  String _formatDuration(Duration duration) {
    final seconds = duration.inSeconds;
    if (seconds < 60) {
      return '$seconds sec';
    } else if (seconds < 3600) {
      final minutes = duration.inMinutes;
      final remainingSeconds = seconds - minutes * 60;
      return '$minutes min $remainingSeconds sec';
    } else {
      final hours = duration.inHours;
      final minutes = duration.inMinutes - hours * 60;
      return '$hours hr $minutes min';
    }
  }
}
