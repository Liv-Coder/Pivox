import 'package:flutter/material.dart';
import 'package:pivox/features/web_scraping/scraping_logger.dart';

/// A widget that displays scraping logs
class LogDisplay extends StatelessWidget {
  /// The logger to display logs from
  final ScrapingLogger logger;

  /// The maximum height of the log display
  final double maxHeight;

  /// Whether to auto-scroll to the bottom
  final bool autoScroll;

  /// Creates a new [LogDisplay]
  const LogDisplay({
    super.key,
    required this.logger,
    this.maxHeight = 200,
    this.autoScroll = true,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<ScrapingLogEntry>(
      stream: logger.onLog,
      builder: (context, snapshot) {
        return Container(
          constraints: BoxConstraints(maxHeight: maxHeight),
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(8),
          ),
          child: LogList(entries: logger.entries, autoScroll: autoScroll),
        );
      },
    );
  }
}

/// A widget that displays a list of log entries
class LogList extends StatefulWidget {
  /// The log entries to display
  final List<ScrapingLogEntry> entries;

  /// Whether to auto-scroll to the bottom
  final bool autoScroll;

  /// Creates a new [LogList]
  const LogList({super.key, required this.entries, this.autoScroll = true});

  @override
  State<LogList> createState() => _LogListState();
}

class _LogListState extends State<LogList> {
  final ScrollController _scrollController = ScrollController();

  @override
  void didUpdateWidget(LogList oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.autoScroll &&
        widget.entries.isNotEmpty &&
        oldWidget.entries.length != widget.entries.length) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.entries.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text('No logs yet', style: TextStyle(color: Colors.white70)),
        ),
      );
    }

    return Scrollbar(
      controller: _scrollController,
      child: SingleChildScrollView(
        controller: _scrollController,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children:
              widget.entries
                  .map((entry) => LogEntryWidget(entry: entry))
                  .toList(),
        ),
      ),
    );
  }
}

/// A widget that displays a single log entry
class LogEntryWidget extends StatelessWidget {
  /// The log entry to display
  final ScrapingLogEntry entry;

  /// Creates a new [LogEntryWidget]
  const LogEntryWidget({super.key, required this.entry});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 2.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTimestamp(),
          const SizedBox(width: 8),
          _buildTypeIndicator(),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              entry.message,
              style: const TextStyle(
                color: Colors.white,
                fontFamily: 'monospace',
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimestamp() {
    final time = entry.timestamp;
    final formattedTime =
        '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}:${time.second.toString().padLeft(2, '0')}';

    return Text(
      formattedTime,
      style: const TextStyle(
        color: Colors.grey,
        fontFamily: 'monospace',
        fontSize: 12,
      ),
    );
  }

  Widget _buildTypeIndicator() {
    Color color;
    String label;

    switch (entry.type) {
      case LogType.info:
        color = Colors.blue;
        label = 'INFO';
        break;
      case LogType.warning:
        color = Colors.orange;
        label = 'WARN';
        break;
      case LogType.error:
        color = Colors.red;
        label = 'ERR!';
        break;
      case LogType.success:
        color = Colors.green;
        label = 'DONE';
        break;
      case LogType.proxy:
        color = Colors.purple;
        label = 'PRXY';
        break;
      case LogType.connection:
        color = Colors.cyan;
        label = 'CONN';
        break;
      case LogType.request:
        color = Colors.amber;
        label = 'REQ>';
        break;
      case LogType.response:
        color = Colors.teal;
        label = '<RES';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
      decoration: BoxDecoration(
        color: color.withAlpha(50),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontFamily: 'monospace',
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
