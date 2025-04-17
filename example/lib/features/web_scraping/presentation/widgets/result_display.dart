import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ionicons/ionicons.dart';
import '../../../../core/design/app_spacing.dart';
import '../../../../core/widgets/animated_card.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../domain/entities/scraping_result.dart';

/// Result display widget
class ResultDisplay extends StatelessWidget {
  final ScrapingResult result;
  final VoidCallback? onExport;
  final VoidCallback? onClear;

  const ResultDisplay({
    super.key,
    required this.result,
    this.onExport,
    this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildResultHeader(context),
        const SizedBox(height: AppSpacing.md),
        _buildResultStats(context),
        const SizedBox(height: AppSpacing.md),
        _buildResultData(context),
      ],
    );
  }

  Widget _buildResultHeader(BuildContext context) {
    return Row(
      children: [
        StatusBadge(
          type: result.success ? StatusType.success : StatusType.error,
          text: result.success ? 'Success' : 'Failed',
          icon:
              result.success
                  ? Ionicons.checkmark_circle
                  : Ionicons.close_circle,
        ),
        const Spacer(),
        IconButton(
          icon: const Icon(Ionicons.copy_outline),
          onPressed: () => _copyResultToClipboard(context),
          tooltip: 'Copy JSON',
        ),
        if (onExport != null)
          IconButton(
            icon: const Icon(Ionicons.download_outline),
            onPressed: onExport,
            tooltip: 'Export',
          ),
        if (onClear != null)
          IconButton(
            icon: const Icon(Ionicons.trash_outline),
            onPressed: onClear,
            tooltip: 'Clear',
          ),
      ],
    );
  }

  Widget _buildResultStats(BuildContext context) {
    return AnimatedCard(
      onTap: null,
      enableHover: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Scraping Statistics',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              _buildStatItem(
                context,
                label: 'Items',
                value: result.itemsScraped.toString(),
                icon: Ionicons.list_outline,
              ),
              _buildStatItem(
                context,
                label: 'Pages',
                value: result.pagesScraped.toString(),
                icon: Ionicons.document_outline,
              ),
              _buildStatItem(
                context,
                label: 'Duration',
                value: _formatDuration(result.duration),
                icon: Ionicons.time_outline,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              _buildStatItem(
                context,
                label: 'Status',
                value: result.statusCode.toString(),
                icon: Ionicons.information_circle_outline,
              ),
              _buildStatItem(
                context,
                label: 'Proxy',
                value: result.proxyUsed ?? 'None',
                icon: Ionicons.server_outline,
              ),
              _buildStatItem(
                context,
                label: 'Browser',
                value: result.usedHeadlessBrowser ? 'Yes' : 'No',
                icon: Ionicons.globe_outline,
              ),
            ],
          ),
          if (result.error != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Error:',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.error,
              ),
            ),
            Text(
              result.error!,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.error,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatItem(
    BuildContext context, {
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.xs),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 16, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 4),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withAlpha(153),
                    ),
                  ),
                  Text(
                    value,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultData(BuildContext context) {
    if (result.data.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Text(
            result.success ? 'No data found' : 'No data available due to error',
            style: Theme.of(context).textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Scraped Data (${result.data.length} items)',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: AppSpacing.sm),
          Expanded(
            child: ListView.builder(
              itemCount: result.data.length,
              itemBuilder: (context, index) {
                final item = result.data[index];
                return _buildDataItem(context, item, index);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDataItem(
    BuildContext context,
    Map<String, dynamic> item,
    int index,
  ) {
    return AnimatedCard(
      onTap: () => _showItemDetails(context, item),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.xs),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withAlpha(25),
                  borderRadius: BorderRadius.circular(AppSpacing.xs),
                ),
                child: Text(
                  '${index + 1}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'Item ${index + 1}',
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
              Text(
                '${item.length} fields',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withAlpha(153),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          _buildItemPreview(context, item),
        ],
      ),
    );
  }

  Widget _buildItemPreview(BuildContext context, Map<String, dynamic> item) {
    final entries = item.entries.take(3).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children:
          entries.map((entry) {
            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xs),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 80,
                    child: Text(
                      '${entry.key}:',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withAlpha(179),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      _formatValue(entry.value),
                      style: Theme.of(context).textTheme.bodySmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
    );
  }

  void _showItemDetails(BuildContext context, Map<String, dynamic> item) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Item Details'),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children:
                    item.entries.map((entry) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              entry.key,
                              style: Theme.of(context).textTheme.titleSmall
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              _formatValue(entry.value),
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            const Divider(),
                          ],
                        ),
                      );
                    }).toList(),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
              TextButton(
                onPressed: () {
                  final jsonString = _formatJsonString(item);
                  Clipboard.setData(ClipboardData(text: jsonString));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Copied to clipboard'),
                      duration: Duration(seconds: 1),
                    ),
                  );
                  Navigator.pop(context);
                },
                child: const Text('Copy JSON'),
              ),
            ],
          ),
    );
  }

  void _copyResultToClipboard(BuildContext context) {
    final jsonString = _formatJsonString(result.data);
    Clipboard.setData(ClipboardData(text: jsonString));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Copied to clipboard'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  String _formatJsonString(dynamic data) {
    const encoder = JsonEncoder.withIndent('  ');
    return encoder.convert(data);
  }

  String _formatValue(dynamic value) {
    if (value == null) return 'null';
    if (value is String) return value;
    if (value is List) return value.join(', ');
    return value.toString();
  }

  String _formatDuration(Duration duration) {
    if (duration.inMinutes > 0) {
      return '${duration.inMinutes}m ${duration.inSeconds % 60}s';
    } else {
      return '${duration.inSeconds}.${(duration.inMilliseconds % 1000) ~/ 100}s';
    }
  }
}
