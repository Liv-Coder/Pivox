import 'package:flutter/material.dart';
import 'package:pivox/features/web_scraping/scraping_logger.dart';

/// Shows a detailed error dialog
Future<void> showScrapingErrorDialog({
  required BuildContext context,
  required String title,
  required String errorMessage,
  required ScrapingLogger logger,
}) async {
  return showDialog<void>(
    context: context,
    barrierDismissible: true,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text(title),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Error: $errorMessage',
                style: const TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Recent logs:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              _buildRecentLogs(logger),
              const SizedBox(height: 16),
              _buildTroubleshootingTips(),
            ],
          ),
        ),
        actions: <Widget>[
          TextButton(
            child: const Text('Close'),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ],
      );
    },
  );
}

Widget _buildRecentLogs(ScrapingLogger logger) {
  // Get the most recent logs, focusing on errors
  final allLogs = logger.entries;
  final errorLogs = allLogs.where((log) => log.type == LogType.error).toList();

  // Get the 5 most recent logs and 5 most recent error logs
  final recentLogs =
      allLogs.length > 10 ? allLogs.sublist(allLogs.length - 10) : allLogs;

  final recentErrorLogs =
      errorLogs.length > 5
          ? errorLogs.sublist(errorLogs.length - 5)
          : errorLogs;

  // Combine and sort by timestamp
  final logsToShow =
      {...recentLogs, ...recentErrorLogs}.toList()
        ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

  if (logsToShow.isEmpty) {
    return const Text('No logs available');
  }

  return Container(
    height: 200,
    decoration: BoxDecoration(
      color: Colors.black,
      borderRadius: BorderRadius.circular(8),
    ),
    child: SingleChildScrollView(
      controller: ScrollController(), // Add a dedicated ScrollController
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children:
            logsToShow
                .map(
                  (log) => Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8.0,
                      vertical: 2.0,
                    ),
                    child: Text(
                      log.toString(),
                      style: TextStyle(
                        color: _getColorForLogType(log.type),
                        fontFamily: 'monospace',
                        fontSize: 12,
                      ),
                    ),
                  ),
                )
                .toList(),
      ),
    ),
  );
}

Color _getColorForLogType(LogType type) {
  switch (type) {
    case LogType.info:
      return Colors.white;
    case LogType.warning:
      return Colors.orange;
    case LogType.error:
      return Colors.red;
    case LogType.success:
      return Colors.green;
    case LogType.proxy:
      return Colors.purple;
    case LogType.connection:
      return Colors.cyan;
    case LogType.request:
      return Colors.amber;
    case LogType.response:
      return Colors.teal;
  }
}

Widget _buildTroubleshootingTips() {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        'Troubleshooting tips:',
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      const SizedBox(height: 8),
      const Text('• Check if the website has anti-scraping measures'),
      const Text('• Try using a different proxy'),
      const Text('• Ensure the URL is correct and accessible'),
      const Text('• Check if the website requires JavaScript'),
      const Text('• Try increasing the timeout value'),
      const Text('• Some websites may block requests from certain regions'),
      const SizedBox(height: 12),
      _buildSiteSpecificTips(),
    ],
  );
}

Widget _buildSiteSpecificTips() {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: const [
      Text(
        'Site-specific tips:',
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      SizedBox(height: 8),
      Text(
        'For onlinekhabar.com:',
        style: TextStyle(fontStyle: FontStyle.italic),
      ),
      Text('• Try removing the port number (:443) from the URL'),
      Text('• Use a proxy from a different region'),
      Text('• Try with a different user agent string'),
      Text('• The site may have rate limiting - wait and try again'),
      SizedBox(height: 8),
      Text('For vegamovies:', style: TextStyle(fontStyle: FontStyle.italic)),
      Text('• Try with a different domain extension (.td, .nl, etc.)'),
      Text('• The site may require specific headers'),
      Text('• Try with a longer timeout (120+ seconds)'),
    ],
  );
}
