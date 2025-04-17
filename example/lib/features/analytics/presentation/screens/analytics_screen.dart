import 'package:flutter/material.dart';
import 'package:ionicons/ionicons.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../../core/widgets/base_screen.dart';
import '../../../../core/widgets/action_button.dart';
import '../../../../core/widgets/animated_card.dart';
import '../../../../core/design/app_spacing.dart';
import '../../../../core/design/app_colors.dart';
import '../../../../core/utils/app_animations.dart';
import '../widgets/analytics_card.dart';

/// Analytics screen
class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  final List<String> _timeRanges = [
    'Last 7 Days',
    'Last 30 Days',
    'Last 3 Months',
    'Last 6 Months',
    'Last Year',
    'All Time',
  ];

  final List<String> _metrics = [
    'Success Rate',
    'Response Time',
    'Proxy Usage',
    'Data Extracted',
    'Scraping Jobs',
  ];

  String _selectedTimeRange = 'Last 7 Days';
  String _selectedMetric = 'Success Rate';

  @override
  Widget build(BuildContext context) {
    return BaseScreen(
      title: 'Analytics',
      actions: [
        IconButton(
          icon: const Icon(Ionicons.filter_outline),
          onPressed: _showFilterOptions,
          tooltip: 'Filter',
        ),
        IconButton(
          icon: const Icon(Ionicons.download_outline),
          onPressed: _exportData,
          tooltip: 'Export',
        ),
      ],
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildFilterBar(),
            const SizedBox(height: AppSpacing.lg),
            _buildSummaryCards(),
            const SizedBox(height: AppSpacing.lg),
            _buildMainChart(),
            const SizedBox(height: AppSpacing.lg),
            _buildDetailedStats(),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterBar() {
    return AppAnimations.fadeSlideIn(
      child: Row(
        children: [
          Expanded(
            child: DropdownButtonFormField<String>(
              value: _selectedTimeRange,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Time Range',
                prefixIcon: Icon(Ionicons.calendar_outline),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
              ),
              items:
                  _timeRanges.map((range) {
                    return DropdownMenuItem<String>(
                      value: range,
                      child: Text(range, overflow: TextOverflow.ellipsis),
                    );
                  }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedTimeRange = value;
                  });
                }
              },
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: DropdownButtonFormField<String>(
              value: _selectedMetric,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Metric',
                prefixIcon: Icon(Ionicons.stats_chart_outline),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
              ),
              items:
                  _metrics.map((metric) {
                    return DropdownMenuItem<String>(
                      value: metric,
                      child: Text(metric, overflow: TextOverflow.ellipsis),
                    );
                  }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedMetric = value;
                  });
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCards() {
    return AppAnimations.fadeSlideIn(
      child: GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisSpacing: AppSpacing.md,
        mainAxisSpacing: AppSpacing.md,
        childAspectRatio: 1.5,
        children: [
          AnalyticsCard(
            title: 'Success Rate',
            value: '92%',
            trend: '+5%',
            icon: Ionicons.trending_up_outline,
            color: AppColors.success,
            isPositive: true,
          ),
          AnalyticsCard(
            title: 'Avg. Response Time',
            value: '245ms',
            trend: '-12ms',
            icon: Ionicons.speedometer_outline,
            color: AppColors.info,
            isPositive: true,
          ),
          AnalyticsCard(
            title: 'Scraping Jobs',
            value: '156',
            trend: '+23',
            icon: Ionicons.code_outline,
            color: AppColors.accent,
            isPositive: true,
          ),
          AnalyticsCard(
            title: 'Data Extracted',
            value: '4.2GB',
            trend: '+0.8GB',
            icon: Ionicons.document_text_outline,
            color: AppColors.secondary,
            isPositive: true,
          ),
        ],
      ),
    );
  }

  Widget _buildMainChart() {
    return AppAnimations.fadeSlideIn(
      child: AnimatedCard(
        onTap: null,
        enableHover: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  _selectedMetric,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Text(
                  _selectedTimeRange,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withAlpha(179),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            SizedBox(height: 200, child: LineChart(_mainChartData())),
          ],
        ),
      ),
    );
  }

  LineChartData _mainChartData() {
    // Mock data for the chart
    final List<FlSpot> spots = [
      const FlSpot(0, 0.85),
      const FlSpot(1, 0.82),
      const FlSpot(2, 0.88),
      const FlSpot(3, 0.90),
      const FlSpot(4, 0.87),
      const FlSpot(5, 0.92),
      const FlSpot(6, 0.94),
    ];

    return LineChartData(
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        horizontalInterval: 0.2,
        getDrawingHorizontalLine: (value) {
          return FlLine(
            color: Theme.of(context).colorScheme.outline.withAlpha(51),
            strokeWidth: 1,
          );
        },
      ),
      titlesData: FlTitlesData(
        show: true,
        rightTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 30,
            interval: 1,
            getTitlesWidget: (value, meta) {
              const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
              final index = value.toInt();
              if (index >= 0 && index < days.length) {
                return SideTitleWidget(
                  axisSide: meta.axisSide,
                  child: Text(
                    days[index],
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withAlpha(179),
                    ),
                  ),
                );
              }
              return const SizedBox();
            },
          ),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            interval: 0.2,
            reservedSize: 40,
            getTitlesWidget: (value, meta) {
              return SideTitleWidget(
                axisSide: meta.axisSide,
                child: Text(
                  '${(value * 100).toInt()}%',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withAlpha(179),
                  ),
                ),
              );
            },
          ),
        ),
      ),
      borderData: FlBorderData(show: false),
      minX: 0,
      maxX: 6,
      minY: 0.7,
      maxY: 1.0,
      lineBarsData: [
        LineChartBarData(
          spots: spots,
          isCurved: true,
          color: AppColors.primary,
          barWidth: 3,
          isStrokeCapRound: true,
          dotData: const FlDotData(show: false),
          belowBarData: BarAreaData(
            show: true,
            color: AppColors.primary.withAlpha(25),
          ),
        ),
      ],
    );
  }

  Widget _buildDetailedStats() {
    return AppAnimations.fadeSlideIn(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Detailed Statistics',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: AppSpacing.md),
          AnimatedCard(
            onTap: null,
            enableHover: false,
            child: Column(
              children: [
                _buildStatRow('Total Proxies Used', '245'),
                const Divider(),
                _buildStatRow('Successful Requests', '1,245'),
                const Divider(),
                _buildStatRow('Failed Requests', '98'),
                const Divider(),
                _buildStatRow('Average Response Time', '245ms'),
                const Divider(),
                _buildStatRow('Data Extracted', '4.2GB'),
                const Divider(),
                _buildStatRow('Most Used Proxy', '192.168.1.1:8080'),
                const Divider(),
                _buildStatRow('Most Scraped Domain', 'example.com'),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Center(
            child: ActionButton(
              text: 'Generate Full Report',
              icon: Ionicons.document_text_outline,
              onPressed: _generateReport,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  void _exportData() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Exporting analytics data...'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  void _showFilterOptions() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Filter Options'),
            content: const SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Additional filter options will be implemented soon.'),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          ),
    );
  }

  void _generateReport() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Generating analytics report...'),
        duration: Duration(seconds: 1),
      ),
    );
  }
}
