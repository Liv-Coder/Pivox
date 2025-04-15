import 'dart:math';

import 'package:flutter/material.dart';
import 'package:ionicons/ionicons.dart';
import 'package:pivox/pivox.dart';

import '../../../../core/design/design_tokens.dart';
import '../../../../core/services/proxy_service.dart';
import '../../../../core/services/service_locator.dart';
import '../../../../core/widgets/proxy_card.dart';
import '../widgets/dashboard_card.dart';
import '../widgets/dashboard_metric.dart';
import '../widgets/dashboard_section.dart';

/// Home screen for the Pivox example app
class HomeScreen extends StatefulWidget {
  /// Creates a new [HomeScreen]
  const HomeScreen({super.key, required this.title});

  /// Title of the screen
  final String title;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final List<ProxyModel> _proxies = [];
  bool _isLoading = false;
  String _responseText = '';
  int _activeProxies = 0;
  int _totalProxies = 0;
  double _successRate = 0.0;
  double _avgResponseTime = 0.0;

  // Get services from service locator
  final _proxyService = serviceLocator<ProxyService>();

  @override
  void initState() {
    super.initState();
    _fetchProxies();
  }

  Future<void> _fetchProxies() async {
    setState(() {
      _isLoading = true;
      _responseText = '';
    });

    try {
      final proxies = await _proxyService.fetchProxies(
        options: ProxyFilterOptions(count: 20, onlyHttps: true),
      );

      // Calculate metrics
      _totalProxies = proxies.length;
      _activeProxies =
          proxies
              .where(
                (p) =>
                    p is ProxyModel &&
                    p.responseTime != null &&
                    p.responseTime! < 2000,
              )
              .length;

      // Calculate success rate and average response time
      int validProxies = 0;
      double totalResponseTime = 0.0;

      for (final proxy in proxies) {
        if (proxy is ProxyModel && proxy.responseTime != null) {
          validProxies++;
          totalResponseTime += proxy.responseTime!.toDouble();
        }
      }

      _successRate =
          validProxies > 0 ? (validProxies / _totalProxies) * 100 : 0.0;
      _avgResponseTime =
          validProxies > 0 ? totalResponseTime / validProxies : 0.0;

      setState(() {
        _proxies.clear();
        _proxies.addAll(
          proxies.map(
            (p) => ProxyModel(
              ip: p.ip,
              port: p.port,
              countryCode: p.countryCode,
              isHttps: p.isHttps,
              anonymityLevel: p.anonymityLevel,
              responseTime: p is ProxyModel ? p.responseTime : null,
            ),
          ),
        );
        _responseText = 'Successfully fetched ${proxies.length} proxies';
      });
    } catch (e) {
      setState(() {
        _responseText = 'Error fetching proxies: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _testProxy() async {
    setState(() {
      _isLoading = true;
      _responseText = '';
    });

    try {
      final response = await _proxyService.makeHttpRequest(
        'https://api.ipify.org?format=json',
      );

      setState(() {
        _responseText = 'HTTP Response: $response';
      });
    } catch (e) {
      setState(() {
        _responseText = 'Error with HTTP request: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _fetchProxies,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(DesignTokens.spacingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Overview metrics
            DashboardSection(
              title: 'Overview',
              child: LayoutBuilder(
                builder: (context, constraints) {
                  // Responsive layout
                  final isWide = constraints.maxWidth > 600;

                  if (isWide) {
                    return Row(
                      children: [
                        Expanded(child: _buildOverviewCard()),
                        const SizedBox(width: DesignTokens.spacingMedium),
                        Expanded(child: _buildStatusCard()),
                      ],
                    );
                  } else {
                    return Column(
                      children: [
                        _buildOverviewCard(),
                        const SizedBox(height: DesignTokens.spacingMedium),
                        _buildStatusCard(),
                      ],
                    );
                  }
                },
              ),
            ),

            const SizedBox(height: DesignTokens.spacingLarge),

            // Proxy list
            DashboardSection(
              title: 'Available Proxies',
              child: _buildProxyList(),
            ),

            const SizedBox(height: DesignTokens.spacingLarge),

            // Quick actions
            DashboardSection(
              title: 'Quick Actions',
              child: LayoutBuilder(
                builder: (context, constraints) {
                  // Responsive layout
                  final isWide = constraints.maxWidth > 600;

                  if (isWide) {
                    return Row(
                      children: [
                        Expanded(child: _buildActionsCard()),
                        const SizedBox(width: DesignTokens.spacingMedium),
                        Expanded(child: _buildTestCard()),
                      ],
                    );
                  } else {
                    return Column(
                      children: [
                        _buildActionsCard(),
                        const SizedBox(height: DesignTokens.spacingMedium),
                        _buildTestCard(),
                      ],
                    );
                  }
                },
              ),
            ),

            const SizedBox(height: DesignTokens.spacingMedium),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewCard() {
    return DashboardCard(
      title: 'Proxy Metrics',
      icon: Ionicons.stats_chart_outline,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: DashboardMetric(
                  title: 'Active Proxies',
                  value: '$_activeProxies/$_totalProxies',
                  changePercentage:
                      _totalProxies > 0
                          ? (_activeProxies / _totalProxies) * 100 - 50
                          : 0.0,
                ),
              ),
              Expanded(
                child: DashboardMetric(
                  title: 'Success Rate',
                  value: '${_successRate.toStringAsFixed(1)}%',
                  changePercentage: _successRate - 75.0,
                ),
              ),
            ],
          ),
          const SizedBox(height: DesignTokens.spacingLarge),
          Row(
            children: [
              Expanded(
                child: DashboardMetric(
                  title: 'Avg. Response Time',
                  value: '${_avgResponseTime.toStringAsFixed(0)}ms',
                  changePercentage:
                      _avgResponseTime > 0
                          ? (1000 - _avgResponseTime) / 10
                          : 0.0,
                ),
              ),
              Expanded(
                child: DashboardMetric(
                  title: 'Last Updated',
                  value: DateTime.now().toString().substring(11, 19),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard() {
    return DashboardCard(
      title: 'System Status',
      icon: Ionicons.pulse_outline,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStatusItem(
            'Proxy Service',
            _isLoading ? 'Loading' : 'Online',
            _isLoading ? Colors.orange : Colors.green,
          ),
          const SizedBox(height: DesignTokens.spacingMedium),
          _buildStatusItem('HTTP Client', 'Ready', Colors.green),
          const SizedBox(height: DesignTokens.spacingMedium),
          _buildStatusItem('Dio Client', 'Ready', Colors.green),
          const SizedBox(height: DesignTokens.spacingMedium),
          _buildStatusItem('Cache', 'Synced', Colors.green),
          if (_responseText.isNotEmpty) ...[
            const SizedBox(height: DesignTokens.spacingMedium),
            const Divider(),
            const SizedBox(height: DesignTokens.spacingSmall),
            Text(
              'Last Response:',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: DesignTokens.fontWeightMedium,
              ),
            ),
            const SizedBox(height: DesignTokens.spacingXSmall),
            Text(
              _responseText,
              style: Theme.of(context).textTheme.bodySmall,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusItem(String name, String status, Color color) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: DesignTokens.spacingSmall),
        Text(name, style: Theme.of(context).textTheme.bodyMedium),
        const Spacer(),
        Text(
          status,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: color,
            fontWeight: DesignTokens.fontWeightMedium,
          ),
        ),
      ],
    );
  }

  Widget _buildProxyList() {
    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(DesignTokens.spacingLarge),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_proxies.isEmpty) {
      return DashboardCard(
        title: 'No Proxies Available',
        icon: Ionicons.warning_outline,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(DesignTokens.spacingLarge),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Ionicons.cloud_offline_outline,
                  size: 48,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                const SizedBox(height: DesignTokens.spacingMedium),
                Text(
                  'No proxies available',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: DesignTokens.spacingSmall),
                Text(
                  'Tap the refresh button to fetch proxies',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: DesignTokens.spacingLarge),
                ElevatedButton.icon(
                  onPressed: _fetchProxies,
                  icon: const Icon(Ionicons.refresh_outline),
                  label: const Text('Refresh'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Column(
      children: [
        for (int i = 0; i < min(5, _proxies.length); i++)
          Padding(
            padding: EdgeInsets.only(
              bottom:
                  i < min(5, _proxies.length) - 1
                      ? DesignTokens.spacingMedium
                      : 0,
            ),
            child: ProxyCard(proxy: _proxies[i]),
          ),
        if (_proxies.length > 5) ...[
          const SizedBox(height: DesignTokens.spacingMedium),
          OutlinedButton(
            onPressed: () {
              // Show all proxies
            },
            child: Text('View All ${_proxies.length} Proxies'),
          ),
        ],
      ],
    );
  }

  Widget _buildActionsCard() {
    return DashboardCard(
      title: 'Actions',
      icon: Ionicons.options_outline,
      child: Column(
        children: [
          _buildActionButton(
            'Refresh Proxies',
            Ionicons.refresh_outline,
            _fetchProxies,
            isLoading: _isLoading,
          ),
          const SizedBox(height: DesignTokens.spacingMedium),
          _buildActionButton(
            'Validate Proxies',
            Ionicons.checkmark_circle_outline,
            () {},
          ),
          const SizedBox(height: DesignTokens.spacingMedium),
          _buildActionButton('Clear Cache', Ionicons.trash_outline, () {}),
        ],
      ),
    );
  }

  Widget _buildTestCard() {
    return DashboardCard(
      title: 'Test Proxy',
      icon: Ionicons.flask_outline,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Test your proxy connection with a real request',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: DesignTokens.spacingMedium),
          _buildActionButton(
            'Test HTTP Connection',
            Ionicons.globe_outline,
            _testProxy,
            isLoading: _isLoading,
            isPrimary: true,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    String text,
    IconData icon,
    VoidCallback onPressed, {
    bool isLoading = false,
    bool isPrimary = false,
  }) {
    if (isPrimary) {
      return ElevatedButton.icon(
        onPressed: isLoading ? null : onPressed,
        icon:
            isLoading
                ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
                : Icon(icon),
        label: Text(text),
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(double.infinity, 48),
        ),
      );
    }

    return OutlinedButton.icon(
      onPressed: isLoading ? null : onPressed,
      icon:
          isLoading
              ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
              : Icon(icon),
      label: Text(text),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(double.infinity, 48),
      ),
    );
  }
}
