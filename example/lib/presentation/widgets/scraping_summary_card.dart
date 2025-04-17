import 'package:flutter/material.dart';

/// A card widget that displays a summary of scraping tasks
class ScrapingSummaryCard extends StatelessWidget {
  /// The total number of tasks
  final int totalTasks;

  /// The number of queued tasks
  final int queuedTasks;

  /// The number of executing tasks
  final int executingTasks;

  /// The number of completed tasks
  final int completedTasks;

  /// The number of failed tasks
  final int failedTasks;

  /// The number of cancelled tasks
  final int cancelledTasks;

  /// Creates a new [ScrapingSummaryCard]
  const ScrapingSummaryCard({
    super.key,
    required this.totalTasks,
    required this.queuedTasks,
    required this.executingTasks,
    required this.completedTasks,
    required this.failedTasks,
    required this.cancelledTasks,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Scraping Summary',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildSummaryItem(
                  context,
                  'Total',
                  totalTasks,
                  Colors.blue,
                  Icons.list,
                ),
                _buildSummaryItem(
                  context,
                  'Queued',
                  queuedTasks,
                  Colors.orange,
                  Icons.queue,
                ),
                _buildSummaryItem(
                  context,
                  'Executing',
                  executingTasks,
                  Colors.purple,
                  Icons.sync,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildSummaryItem(
                  context,
                  'Completed',
                  completedTasks,
                  Colors.green,
                  Icons.check_circle,
                ),
                _buildSummaryItem(
                  context,
                  'Failed',
                  failedTasks,
                  Colors.red,
                  Icons.error,
                ),
                _buildSummaryItem(
                  context,
                  'Cancelled',
                  cancelledTasks,
                  Colors.grey,
                  Icons.cancel,
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (totalTasks > 0) _buildProgressBar(context),
          ],
        ),
      ),
    );
  }

  /// Builds a summary item
  Widget _buildSummaryItem(
    BuildContext context,
    String label,
    int count,
    Color color,
    IconData icon,
  ) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 8),
        Text(
          count.toString(),
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  /// Builds a progress bar
  Widget _buildProgressBar(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Progress',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(
            height: 16,
            child: Stack(
              children: [
                // Background
                Container(
                  width: double.infinity,
                  color: Colors.grey.shade200,
                ),
                
                // Completed
                if (completedTasks > 0)
                  FractionallySizedBox(
                    widthFactor: completedTasks / totalTasks,
                    child: Container(
                      color: Colors.green,
                    ),
                  ),
                
                // Executing
                if (executingTasks > 0)
                  Positioned(
                    left: (completedTasks / totalTasks) * 100,
                    width: (executingTasks / totalTasks) * 100,
                    top: 0,
                    bottom: 0,
                    child: Container(
                      color: Colors.purple,
                    ),
                  ),
                
                // Failed
                if (failedTasks > 0)
                  Positioned(
                    left: ((completedTasks + executingTasks) / totalTasks) * 100,
                    width: (failedTasks / totalTasks) * 100,
                    top: 0,
                    bottom: 0,
                    child: Container(
                      color: Colors.red,
                    ),
                  ),
                
                // Cancelled
                if (cancelledTasks > 0)
                  Positioned(
                    left: ((completedTasks + executingTasks + failedTasks) / totalTasks) * 100,
                    width: (cancelledTasks / totalTasks) * 100,
                    top: 0,
                    bottom: 0,
                    child: Container(
                      color: Colors.grey,
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${((completedTasks / totalTasks) * 100).toStringAsFixed(1)}% Complete',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            Text(
              '${executingTasks + queuedTasks} Remaining',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ],
    );
  }
}
