import 'package:flutter/material.dart';
import 'package:ionicons/ionicons.dart';
import '../../../../core/design/app_spacing.dart';
import '../../../../core/utils/formatter_utils.dart';

/// Log entry type
enum LogType { info, warning, error, success }

/// Log entry
class LogEntry {
  final String message;
  final LogType type;
  final DateTime timestamp;

  LogEntry({required this.message, required this.type, DateTime? timestamp})
    : timestamp = timestamp ?? DateTime.now();

  /// Create an info log entry
  factory LogEntry.info(String message) {
    return LogEntry(message: message, type: LogType.info);
  }

  /// Create a warning log entry
  factory LogEntry.warning(String message) {
    return LogEntry(message: message, type: LogType.warning);
  }

  /// Create an error log entry
  factory LogEntry.error(String message) {
    return LogEntry(message: message, type: LogType.error);
  }

  /// Create a success log entry
  factory LogEntry.success(String message) {
    return LogEntry(message: message, type: LogType.success);
  }
}

/// Log display widget
class LogDisplay extends StatelessWidget {
  final List<LogEntry> logs;
  final VoidCallback? onClear;
  final ScrollController _scrollController = ScrollController();

  LogDisplay({super.key, required this.logs, this.onClear});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(context),
        const SizedBox(height: AppSpacing.sm),
        _buildLogList(context),
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        const Icon(Ionicons.terminal_outline, size: 18),
        const SizedBox(width: AppSpacing.xs),
        Text(
          'Logs',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const Spacer(),
        if (onClear != null)
          TextButton.icon(
            onPressed: logs.isEmpty ? null : onClear,
            icon: const Icon(Ionicons.trash_outline, size: 16),
            label: const Text('Clear'),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.xs,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildLogList(BuildContext context) {
    if (logs.isEmpty) {
      return Container(
        height: 200,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(AppSpacing.sm),
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withAlpha(128),
          ),
        ),
        child: Center(
          child: Text(
            'No logs yet',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withAlpha(128),
            ),
          ),
        ),
      );
    }

    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(AppSpacing.sm),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withAlpha(128),
        ),
      ),
      child: Scrollbar(
        controller: _scrollController,
        thumbVisibility: true,
        child: ListView.builder(
          controller: _scrollController,
          itemCount: logs.length,
          padding: const EdgeInsets.all(AppSpacing.sm),
          itemBuilder: (context, index) {
            final log = logs[index];
            return _buildLogEntry(context, log);
          },
        ),
      ),
    );
  }

  Widget _buildLogEntry(BuildContext context, LogEntry log) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            FormatterUtils.formatTime(log.timestamp),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withAlpha(128),
              fontFamily: 'monospace',
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          _buildLogIcon(context, log.type),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Text(
              log.message,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: _getLogColor(context, log.type),
                fontFamily: 'monospace',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogIcon(BuildContext context, LogType type) {
    IconData icon;
    switch (type) {
      case LogType.info:
        icon = Ionicons.information_circle_outline;
        break;
      case LogType.warning:
        icon = Ionicons.warning_outline;
        break;
      case LogType.error:
        icon = Ionicons.close_circle_outline;
        break;
      case LogType.success:
        icon = Ionicons.checkmark_circle_outline;
        break;
    }

    return Icon(icon, size: 14, color: _getLogColor(context, type));
  }

  Color _getLogColor(BuildContext context, LogType type) {
    switch (type) {
      case LogType.info:
        return Theme.of(context).colorScheme.primary;
      case LogType.warning:
        return const Color(0xFFF59E0B);
      case LogType.error:
        return Theme.of(context).colorScheme.error;
      case LogType.success:
        return const Color(0xFF10B981);
    }
  }
}
