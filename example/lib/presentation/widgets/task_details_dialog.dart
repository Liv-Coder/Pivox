import 'package:flutter/material.dart';
import 'package:pivox/features/web_scraping/parallel/scraping_task.dart';

/// A dialog that displays detailed information about a scraping task
class TaskDetailsDialog extends StatelessWidget {
  /// The task to display details for
  final ScrapingTask task;

  /// Creates a new [TaskDetailsDialog]
  const TaskDetailsDialog({
    super.key,
    required this.task,
  });

  /// Shows the dialog
  static Future<void> show(BuildContext context, ScrapingTask task) {
    return showDialog<void>(
      context: context,
      builder: (context) => TaskDetailsDialog(task: task),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          _buildStatusIcon(),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Task Details',
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView(
          shrinkWrap: true,
          children: [
            _buildInfoSection(
              'Basic Information',
              [
                _buildInfoRow('ID', task.id),
                _buildInfoRow('URL', task.url),
                _buildInfoRow('Domain', task.domain),
                _buildInfoRow('Priority', task.priority.toString().split('.').last),
                _buildInfoRow('Status', task.status.toString().split('.').last),
              ],
            ),
            const Divider(),
            _buildInfoSection(
              'Timing Information',
              [
                _buildInfoRow('Created', _formatDateTime(task.createdAt)),
                _buildInfoRow('Started', _formatDateTime(task.startedAt)),
                _buildInfoRow('Completed', _formatDateTime(task.completedAt)),
                if (task.startedAt != null && task.completedAt != null)
                  _buildInfoRow(
                    'Duration',
                    _formatDuration(task.completedAt!.difference(task.startedAt!)),
                  ),
              ],
            ),
            const Divider(),
            _buildInfoSection(
              'Retry Information',
              [
                _buildInfoRow('Retry Count', '${task.retryCount}/${task.maxRetries}'),
              ],
            ),
            if (task.error != null) ...[
              const Divider(),
              _buildInfoSection(
                'Error Information',
                [
                  _buildInfoRow('Error', task.error.toString()),
                  if (task.stackTrace != null)
                    _buildInfoRow('Stack Trace', task.stackTrace.toString()),
                ],
              ),
            ],
            if (task.result != null) ...[
              const Divider(),
              _buildInfoSection(
                'Result',
                [
                  _buildInfoRow('Result Type', task.result.runtimeType.toString()),
                  _buildInfoRow('Result', _formatResult(task.result)),
                ],
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }

  /// Builds the status icon
  Widget _buildStatusIcon() {
    Color color;
    IconData icon;

    switch (task.status) {
      case TaskStatus.created:
        color = Colors.grey;
        icon = Icons.hourglass_empty;
        break;
      case TaskStatus.queued:
        color = Colors.orange;
        icon = Icons.queue;
        break;
      case TaskStatus.executing:
        color = Colors.blue;
        icon = Icons.sync;
        break;
      case TaskStatus.completed:
        color = Colors.green;
        icon = Icons.check_circle;
        break;
      case TaskStatus.failed:
        color = Colors.red;
        icon = Icons.error;
        break;
      case TaskStatus.cancelled:
        color = Colors.grey;
        icon = Icons.cancel;
        break;
    }

    return Icon(icon, color: color);
  }

  /// Builds an information section
  Widget _buildInfoSection(String title, List<Widget> rows) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 8),
        ...rows,
      ],
    );
  }

  /// Builds an information row
  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  /// Formats a DateTime to a readable string
  String _formatDateTime(DateTime? dateTime) {
    if (dateTime == null) return 'N/A';
    return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')} '
        '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}:${dateTime.second.toString().padLeft(2, '0')}';
  }

  /// Formats a Duration to a readable string
  String _formatDuration(Duration duration) {
    final seconds = duration.inSeconds;
    if (seconds < 60) {
      return '$seconds seconds';
    } else if (seconds < 3600) {
      final minutes = duration.inMinutes;
      final remainingSeconds = seconds - minutes * 60;
      return '$minutes minutes $remainingSeconds seconds';
    } else {
      final hours = duration.inHours;
      final minutes = duration.inMinutes - hours * 60;
      final remainingSeconds = seconds - hours * 3600 - minutes * 60;
      return '$hours hours $minutes minutes $remainingSeconds seconds';
    }
  }

  /// Formats a result to a readable string
  String _formatResult(dynamic result) {
    if (result == null) return 'null';
    
    if (result is Map) {
      return result.entries.map((e) => '${e.key}: ${e.value}').join('\n');
    }
    
    if (result is List) {
      if (result.isEmpty) return '[]';
      if (result.length > 10) {
        return '[${result.take(10).join(', ')}, ... (${result.length - 10} more)]';
      }
      return '[${result.join(', ')}]';
    }
    
    return result.toString();
  }
}
