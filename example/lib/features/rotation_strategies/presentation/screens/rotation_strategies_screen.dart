import 'package:flutter/material.dart';
import 'package:ionicons/ionicons.dart';
import 'package:pivox/pivox.dart';

import '../../../../core/design/design_tokens.dart';
import '../../../../core/services/proxy_service.dart';
import '../../../../core/services/service_locator.dart';
import '../../../../core/widgets/action_button.dart';

import '../../../../core/widgets/status_card.dart';

/// Screen for demonstrating proxy rotation strategies
class RotationStrategiesScreen extends StatefulWidget {
  /// Creates a new [RotationStrategiesScreen]
  const RotationStrategiesScreen({super.key});

  @override
  State<RotationStrategiesScreen> createState() =>
      _RotationStrategiesScreenState();
}

class _RotationStrategiesScreenState extends State<RotationStrategiesScreen> {
  bool _isLoading = false;
  String _statusMessage = '';
  RotationStrategyType _selectedStrategy = RotationStrategyType.roundRobin;

  Proxy? _currentProxy;
  final List<Proxy> _selectedProxies = [];
  bool _useScoring = false;
  bool _useValidated = true;

  // Get services from service locator
  final _proxyService = serviceLocator<ProxyService>();

  @override
  void initState() {
    super.initState();
    _selectedStrategy = _proxyService.getRotationStrategyType();
    _loadProxies();
  }

  Future<void> _loadProxies() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Loading proxies...';
    });

    try {
      await _proxyService.fetchValidatedProxies(
        options: const ProxyFilterOptions(count: 10, onlyHttps: true),
        onProgress: (completed, total) {
          setState(() {
            _statusMessage = 'Validated $completed of $total proxies';
          });
        },
      );

      setState(() {
        _statusMessage = 'Proxies loaded successfully';
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Error loading proxies: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _getNextProxy() {
    try {
      final proxy = _proxyService.getNextProxy(
        validated: _useValidated,
        useScoring: _useScoring,
      );

      setState(() {
        _currentProxy = proxy;
        _selectedProxies.add(proxy);
        if (_selectedProxies.length > 5) {
          _selectedProxies.removeAt(0);
        }
        _statusMessage =
            'Got next proxy using ${_selectedStrategy.name} strategy';
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Error getting proxy: $e';
      });
    }
  }

  void _getRandomProxy() {
    try {
      final proxy = _proxyService.getRandomProxy(
        validated: _useValidated,
        useScoring: _useScoring,
      );

      setState(() {
        _currentProxy = proxy;
        _selectedProxies.add(proxy);
        if (_selectedProxies.length > 5) {
          _selectedProxies.removeAt(0);
        }
        _statusMessage = 'Got random proxy';
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Error getting proxy: $e';
      });
    }
  }

  void _getLeastRecentlyUsedProxy() {
    try {
      final proxy = _proxyService.getLeastRecentlyUsedProxy(
        validated: _useValidated,
      );

      setState(() {
        _currentProxy = proxy;
        _selectedProxies.add(proxy);
        if (_selectedProxies.length > 5) {
          _selectedProxies.removeAt(0);
        }
        _statusMessage = 'Got least recently used proxy';
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Error getting proxy: $e';
      });
    }
  }

  void _setRotationStrategy(RotationStrategyType strategyType) {
    _proxyService.setRotationStrategy(strategyType);
    setState(() {
      _selectedStrategy = strategyType;
      _statusMessage = 'Set rotation strategy to ${strategyType.name}';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Rotation Strategies'), elevation: 0),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
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
                    _buildStrategySelector(),
                    const SizedBox(height: DesignTokens.spacingMedium),
                    _buildOptionsCard(),
                    const SizedBox(height: DesignTokens.spacingMedium),
                    _buildActionButtons(),
                    const SizedBox(height: DesignTokens.spacingMedium),
                    if (_currentProxy != null) ...[
                      const Text(
                        'Current Proxy',
                        style: TextStyle(
                          fontSize: DesignTokens.fontSizeLarge,
                          fontWeight: DesignTokens.fontWeightBold,
                        ),
                      ),
                      const SizedBox(height: DesignTokens.spacingSmall),
                      Text(
                        '${_currentProxy!.ip}:${_currentProxy!.port}',
                        style: const TextStyle(
                          fontSize: DesignTokens.fontSizeMedium,
                          fontWeight: DesignTokens.fontWeightSemiBold,
                        ),
                      ),
                      const SizedBox(height: DesignTokens.spacingMedium),
                    ],
                    if (_selectedProxies.isNotEmpty) ...[
                      const Text(
                        'Recently Selected Proxies',
                        style: TextStyle(
                          fontSize: DesignTokens.fontSizeLarge,
                          fontWeight: DesignTokens.fontWeightBold,
                        ),
                      ),
                      const SizedBox(height: DesignTokens.spacingSmall),
                      ..._selectedProxies.reversed.map(
                        (proxy) => Padding(
                          padding: const EdgeInsets.only(
                            bottom: DesignTokens.spacingSmall,
                          ),
                          child: Text(
                            '${proxy.ip}:${proxy.port}',
                            style: const TextStyle(
                              fontSize: DesignTokens.fontSizeSmall,
                              fontWeight: DesignTokens.fontWeightMedium,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
    );
  }

  Widget _buildStrategySelector() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(DesignTokens.spacingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Rotation Strategy',
              style: TextStyle(
                fontSize: DesignTokens.fontSizeLarge,
                fontWeight: DesignTokens.fontWeightBold,
              ),
            ),
            const SizedBox(height: DesignTokens.spacingMedium),
            Wrap(
              spacing: DesignTokens.spacingSmall,
              runSpacing: DesignTokens.spacingSmall,
              children: [
                _buildStrategyChip(
                  RotationStrategyType.roundRobin,
                  'Round Robin',
                  Ionicons.sync_outline,
                ),
                _buildStrategyChip(
                  RotationStrategyType.random,
                  'Random',
                  Ionicons.dice_outline,
                ),
                _buildStrategyChip(
                  RotationStrategyType.weighted,
                  'Weighted',
                  Ionicons.bar_chart_outline,
                ),
                _buildStrategyChip(
                  RotationStrategyType.advanced,
                  'Advanced',
                  Ionicons.time_outline,
                ),
                _buildStrategyChip(
                  RotationStrategyType.geoBased,
                  'Geo-Based',
                  Ionicons.globe_outline,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStrategyChip(
    RotationStrategyType strategyType,
    String label,
    IconData icon,
  ) {
    final isSelected = _selectedStrategy == strategyType;
    return FilterChip(
      selected: isSelected,
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color:
                isSelected
                    ? DesignTokens.chipSelectedTextColor
                    : DesignTokens.chipTextColor,
          ),
          const SizedBox(width: 4),
          Text(label),
        ],
      ),
      onSelected: (selected) {
        if (selected) {
          _setRotationStrategy(strategyType);
        }
      },
    );
  }

  Widget _buildOptionsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(DesignTokens.spacingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Options',
              style: TextStyle(
                fontSize: DesignTokens.fontSizeLarge,
                fontWeight: DesignTokens.fontWeightBold,
              ),
            ),
            const SizedBox(height: DesignTokens.spacingSmall),
            Text(
              _getStrategyDescription(_selectedStrategy),
              style: TextStyle(
                fontSize: DesignTokens.fontSizeSmall,
                fontStyle: FontStyle.italic,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: DesignTokens.spacingMedium),
            SwitchListTile(
              title: const Text('Use Validated Proxies'),
              subtitle: const Text('Only use proxies that have been validated'),
              value: _useValidated,
              onChanged: (value) {
                setState(() {
                  _useValidated = value;
                });
              },
            ),
            SwitchListTile(
              title: const Text('Use Scoring'),
              subtitle: const Text('Use proxy scores for selection'),
              value: _useScoring,
              onChanged: (value) {
                setState(() {
                  _useScoring = value;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(DesignTokens.spacingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Actions',
              style: TextStyle(
                fontSize: DesignTokens.fontSizeLarge,
                fontWeight: DesignTokens.fontWeightBold,
              ),
            ),
            const SizedBox(height: DesignTokens.spacingMedium),
            Row(
              children: [
                Expanded(
                  child: ActionButton(
                    onPressed: _getNextProxy,
                    icon: Ionicons.arrow_forward_outline,
                    text: 'Next Proxy',
                    isLoading: _isLoading,
                  ),
                ),
                const SizedBox(width: DesignTokens.spacingMedium),
                Expanded(
                  child: ActionButton(
                    onPressed: _getRandomProxy,
                    icon: Ionicons.shuffle_outline,
                    text: 'Random Proxy',
                    isLoading: _isLoading,
                  ),
                ),
              ],
            ),
            const SizedBox(height: DesignTokens.spacingMedium),
            Row(
              children: [
                Expanded(
                  child: ActionButton(
                    onPressed: _getLeastRecentlyUsedProxy,
                    icon: Ionicons.time_outline,
                    text: 'LRU Proxy',
                    isLoading: _isLoading,
                  ),
                ),
                const SizedBox(width: DesignTokens.spacingMedium),
                Expanded(
                  child: ActionButton(
                    onPressed: _loadProxies,
                    icon: Ionicons.refresh_outline,
                    text: 'Reload Proxies',
                    isLoading: _isLoading,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _getStrategyDescription(RotationStrategyType strategy) {
    switch (strategy) {
      case RotationStrategyType.roundRobin:
        return 'Cycles through proxies in sequence';
      case RotationStrategyType.random:
        return 'Selects a random proxy each time';
      case RotationStrategyType.weighted:
        return 'Selects proxies based on performance metrics';
      case RotationStrategyType.geoBased:
        return 'Rotates through proxies from different countries';
      case RotationStrategyType.advanced:
        return 'Uses multiple factors including failure tracking and usage frequency';
      case RotationStrategyType.adaptive:
        return 'Learns from proxy performance and adapts selection over time';
    }
  }
}
