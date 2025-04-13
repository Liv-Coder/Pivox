import 'package:flutter/material.dart';
import 'package:ionicons/ionicons.dart';
import 'package:pivox/features/proxy_management/domain/entities/proxy_analytics.dart';

import '../../../../core/design/design_tokens.dart';
import '../../../../core/services/proxy_service.dart';
import '../../../../core/services/service_locator.dart';
import '../../../../core/widgets/action_button.dart';
import '../../../../core/widgets/status_card.dart';

/// Screen for displaying proxy analytics
class AnalyticsScreen extends StatefulWidget {
  /// Creates a new [AnalyticsScreen]
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  bool _isLoading = false;
  ProxyAnalytics? _analytics;
  String _statusMessage = '';

  // Get services from service locator
  final _proxyService = serviceLocator<ProxyService>();

  @override
  void initState() {
    super.initState();
    _loadAnalytics();
  }

  Future<void> _loadAnalytics() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Loading analytics...';
    });

    try {
      final analytics = await _proxyService.getAnalytics();
      setState(() {
        _analytics = analytics;
        _statusMessage =
            analytics != null
                ? 'Analytics loaded successfully'
                : 'Analytics is not enabled';
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Error loading analytics: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _resetAnalytics() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Resetting analytics...';
    });

    try {
      await _proxyService.resetAnalytics();
      await _loadAnalytics();
      setState(() {
        _statusMessage = 'Analytics reset successfully';
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Error resetting analytics: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Proxy Analytics'), elevation: 0),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _analytics == null
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Ionicons.analytics_outline,
                      size: 64,
                      color: DesignTokens.textSecondaryColor,
                    ),
                    const SizedBox(height: DesignTokens.spacingMedium),
                    const Text(
                      'Analytics is not enabled',
                      style: TextStyle(
                        fontSize: DesignTokens.fontSizeLarge,
                        fontWeight: DesignTokens.fontWeightBold,
                      ),
                    ),
                    const SizedBox(height: DesignTokens.spacingSmall),
                    const Text(
                      'Enable analytics in the Pivox configuration to track proxy usage',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: DesignTokens.textSecondaryColor),
                    ),
                    const SizedBox(height: DesignTokens.spacingLarge),
                    StatusCard(message: _statusMessage),
                  ],
                ),
              )
              : SingleChildScrollView(
                padding: const EdgeInsets.all(DesignTokens.spacingMedium),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_statusMessage.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(
                          bottom: DesignTokens.spacingMedium,
                        ),
                        child: StatusCard(message: _statusMessage),
                      ),
                    _buildSummaryCard(),
                    const SizedBox(height: DesignTokens.spacingMedium),
                    _buildProxiesByCountryCard(),
                    const SizedBox(height: DesignTokens.spacingMedium),
                    _buildProxiesByAnonymityCard(),
                    const SizedBox(height: DesignTokens.spacingMedium),
                    _buildRequestsBySourceCard(),
                    const SizedBox(height: DesignTokens.spacingLarge),
                    SizedBox(
                      width: double.infinity,
                      child: ActionButton(
                        onPressed: _resetAnalytics,
                        icon: Ionicons.refresh_outline,
                        text: 'Reset Analytics',
                        isLoading: _isLoading,
                      ),
                    ),
                  ],
                ),
              ),
    );
  }

  Widget _buildSummaryCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(DesignTokens.spacingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Summary',
              style: TextStyle(
                fontSize: DesignTokens.fontSizeLarge,
                fontWeight: DesignTokens.fontWeightBold,
              ),
            ),
            const SizedBox(height: DesignTokens.spacingMedium),
            _buildSummaryItem(
              'Total Proxies Fetched',
              _analytics!.totalProxiesFetched.toString(),
              Ionicons.cloud_download_outline,
            ),
            _buildSummaryItem(
              'Total Proxies Validated',
              _analytics!.totalProxiesValidated.toString(),
              Ionicons.checkmark_circle_outline,
            ),
            _buildSummaryItem(
              'Validation Success Rate',
              '${(_analytics!.totalSuccessfulValidations / (_analytics!.totalProxiesValidated > 0 ? _analytics!.totalProxiesValidated : 1) * 100).toStringAsFixed(1)}%',
              Ionicons.trending_up_outline,
            ),
            _buildSummaryItem(
              'Total Requests',
              _analytics!.totalRequests.toString(),
              Ionicons.globe_outline,
            ),
            _buildSummaryItem(
              'Request Success Rate',
              '${(_analytics!.averageSuccessRate * 100).toStringAsFixed(1)}%',
              Ionicons.stats_chart_outline,
            ),
            _buildSummaryItem(
              'Average Response Time',
              '${_analytics!.averageResponseTime} ms',
              Ionicons.time_outline,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProxiesByCountryCard() {
    final countries =
        _analytics!.proxiesByCountry.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(DesignTokens.spacingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Proxies by Country',
              style: TextStyle(
                fontSize: DesignTokens.fontSizeLarge,
                fontWeight: DesignTokens.fontWeightBold,
              ),
            ),
            const SizedBox(height: DesignTokens.spacingMedium),
            if (countries.isEmpty)
              const Text(
                'No country data available',
                style: TextStyle(color: DesignTokens.textSecondaryColor),
              )
            else
              ...countries
                  .take(10)
                  .map(
                    (entry) => _buildSummaryItem(
                      entry.key,
                      entry.value.toString(),
                      Ionicons.location_outline,
                    ),
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildProxiesByAnonymityCard() {
    final anonymityLevels =
        _analytics!.proxiesByAnonymityLevel.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(DesignTokens.spacingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Proxies by Anonymity Level',
              style: TextStyle(
                fontSize: DesignTokens.fontSizeLarge,
                fontWeight: DesignTokens.fontWeightBold,
              ),
            ),
            const SizedBox(height: DesignTokens.spacingMedium),
            if (anonymityLevels.isEmpty)
              const Text(
                'No anonymity data available',
                style: TextStyle(color: DesignTokens.textSecondaryColor),
              )
            else
              ...anonymityLevels.map(
                (entry) => _buildSummaryItem(
                  entry.key,
                  entry.value.toString(),
                  Ionicons.shield_outline,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildRequestsBySourceCard() {
    final sources =
        _analytics!.requestsByProxySource.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(DesignTokens.spacingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Requests by Source',
              style: TextStyle(
                fontSize: DesignTokens.fontSizeLarge,
                fontWeight: DesignTokens.fontWeightBold,
              ),
            ),
            const SizedBox(height: DesignTokens.spacingMedium),
            if (sources.isEmpty)
              const Text(
                'No source data available',
                style: TextStyle(color: DesignTokens.textSecondaryColor),
              )
            else
              ...sources.map(
                (entry) => _buildSummaryItem(
                  entry.key,
                  entry.value.toString(),
                  Ionicons.code_outline,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: DesignTokens.spacingSmall),
      child: Row(
        children: [
          Icon(icon, size: 20, color: DesignTokens.textSecondaryColor),
          const SizedBox(width: DesignTokens.spacingSmall),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(color: DesignTokens.textSecondaryColor),
            ),
          ),
          Text(
            value,
            style: const TextStyle(fontWeight: DesignTokens.fontWeightSemiBold),
          ),
        ],
      ),
    );
  }
}
