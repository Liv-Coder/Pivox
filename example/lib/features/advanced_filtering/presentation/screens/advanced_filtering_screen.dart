import 'package:flutter/material.dart';
import 'package:ionicons/ionicons.dart';
import 'package:pivox/pivox.dart';

import '../../../../core/design/design_tokens.dart';
import '../../../../core/services/proxy_service.dart';
import '../../../../core/services/service_locator.dart';
import '../../../../core/widgets/action_button.dart';
import '../../../../core/widgets/proxy_card.dart';
import '../../../../core/widgets/status_card.dart';

/// Screen for demonstrating advanced proxy filtering
class AdvancedFilteringScreen extends StatefulWidget {
  /// Creates a new [AdvancedFilteringScreen]
  const AdvancedFilteringScreen({super.key});

  @override
  State<AdvancedFilteringScreen> createState() => _AdvancedFilteringScreenState();
}

class _AdvancedFilteringScreenState extends State<AdvancedFilteringScreen> {
  final List<ProxyModel> _proxies = [];
  bool _isLoading = false;
  String _responseText = '';

  // Get services from service locator
  final _proxyService = serviceLocator<ProxyService>();

  // Filter options
  final _countController = TextEditingController(text: '20');
  bool _onlyHttps = true;
  final _countriesController = TextEditingController();
  final _regionsController = TextEditingController();
  final _ispsController = TextEditingController();
  final _minSpeedController = TextEditingController();
  bool _requireWebsockets = false;
  bool _requireSocks = false;
  final _socksVersionController = TextEditingController();
  bool _requireAuthentication = false;
  bool _requireAnonymous = false;

  @override
  void dispose() {
    _countController.dispose();
    _countriesController.dispose();
    _regionsController.dispose();
    _ispsController.dispose();
    _minSpeedController.dispose();
    _socksVersionController.dispose();
    super.dispose();
  }

  Future<void> _fetchProxies() async {
    setState(() {
      _isLoading = true;
      _responseText = '';
    });

    try {
      // Parse filter values
      final count = int.tryParse(_countController.text) ?? 20;
      final countries = _countriesController.text.isEmpty
          ? null
          : _countriesController.text.split(',').map((e) => e.trim()).toList();
      final regions = _regionsController.text.isEmpty
          ? null
          : _regionsController.text.split(',').map((e) => e.trim()).toList();
      final isps = _ispsController.text.isEmpty
          ? null
          : _ispsController.text.split(',').map((e) => e.trim()).toList();
      final minSpeed = _minSpeedController.text.isEmpty
          ? null
          : double.tryParse(_minSpeedController.text);
      final socksVersion = _socksVersionController.text.isEmpty
          ? null
          : int.tryParse(_socksVersionController.text);

      // Create filter options
      final options = ProxyFilterOptions(
        count: count,
        onlyHttps: _onlyHttps,
        countries: countries,
        regions: regions,
        isps: isps,
        minSpeed: minSpeed,
        requireWebsockets: _requireWebsockets,
        requireSocks: _requireSocks,
        socksVersion: socksVersion,
        requireAuthentication: _requireAuthentication,
        requireAnonymous: _requireAnonymous,
      );

      // Fetch proxies with the filter options
      final proxies = await _proxyService.fetchProxies(options: options);

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
              region: p.region,
              isp: p.isp,
              speed: p.speed,
              supportsWebsockets: p.supportsWebsockets,
              supportsSocks: p.supportsSocks,
              socksVersion: p.socksVersion,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Advanced Proxy Filtering'),
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            flex: 2,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(DesignTokens.spacingMedium),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Filter Options',
                    style: TextStyle(
                      fontSize: DesignTokens.fontSizeLarge,
                      fontWeight: DesignTokens.fontWeightBold,
                    ),
                  ),
                  const SizedBox(height: DesignTokens.spacingMedium),
                  
                  // Basic filters
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _countController,
                          decoration: const InputDecoration(
                            labelText: 'Count',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: DesignTokens.spacingMedium),
                      Expanded(
                        child: CheckboxListTile(
                          title: const Text('HTTPS Only'),
                          value: _onlyHttps,
                          onChanged: (value) {
                            setState(() {
                              _onlyHttps = value ?? false;
                            });
                          },
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: DesignTokens.spacingMedium),
                  
                  // Location filters
                  TextField(
                    controller: _countriesController,
                    decoration: const InputDecoration(
                      labelText: 'Countries (comma-separated)',
                      border: OutlineInputBorder(),
                      hintText: 'US, CA, UK',
                    ),
                  ),
                  const SizedBox(height: DesignTokens.spacingMedium),
                  
                  TextField(
                    controller: _regionsController,
                    decoration: const InputDecoration(
                      labelText: 'Regions (comma-separated)',
                      border: OutlineInputBorder(),
                      hintText: 'California, Ontario',
                    ),
                  ),
                  const SizedBox(height: DesignTokens.spacingMedium),
                  
                  // Provider filters
                  TextField(
                    controller: _ispsController,
                    decoration: const InputDecoration(
                      labelText: 'ISPs (comma-separated)',
                      border: OutlineInputBorder(),
                      hintText: 'Comcast, AT&T',
                    ),
                  ),
                  const SizedBox(height: DesignTokens.spacingMedium),
                  
                  // Performance filters
                  TextField(
                    controller: _minSpeedController,
                    decoration: const InputDecoration(
                      labelText: 'Minimum Speed (Mbps)',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: DesignTokens.spacingMedium),
                  
                  // Protocol filters
                  Row(
                    children: [
                      Expanded(
                        child: CheckboxListTile(
                          title: const Text('Websockets'),
                          value: _requireWebsockets,
                          onChanged: (value) {
                            setState(() {
                              _requireWebsockets = value ?? false;
                            });
                          },
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                      const SizedBox(width: DesignTokens.spacingMedium),
                      Expanded(
                        child: CheckboxListTile(
                          title: const Text('SOCKS'),
                          value: _requireSocks,
                          onChanged: (value) {
                            setState(() {
                              _requireSocks = value ?? false;
                            });
                          },
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: DesignTokens.spacingMedium),
                  
                  TextField(
                    controller: _socksVersionController,
                    decoration: const InputDecoration(
                      labelText: 'SOCKS Version',
                      border: OutlineInputBorder(),
                      hintText: '4 or 5',
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: DesignTokens.spacingMedium),
                  
                  // Authentication and anonymity filters
                  Row(
                    children: [
                      Expanded(
                        child: CheckboxListTile(
                          title: const Text('Authenticated'),
                          value: _requireAuthentication,
                          onChanged: (value) {
                            setState(() {
                              _requireAuthentication = value ?? false;
                            });
                          },
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                      const SizedBox(width: DesignTokens.spacingMedium),
                      Expanded(
                        child: CheckboxListTile(
                          title: const Text('Anonymous'),
                          value: _requireAnonymous,
                          onChanged: (value) {
                            setState(() {
                              _requireAnonymous = value ?? false;
                            });
                          },
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: DesignTokens.spacingMedium),
                  
                  // Apply filters button
                  SizedBox(
                    width: double.infinity,
                    child: ActionButton(
                      onPressed: _fetchProxies,
                      icon: Ionicons.filter_outline,
                      text: 'Apply Filters',
                      isLoading: _isLoading,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          if (_responseText.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(DesignTokens.spacingMedium),
              child: StatusCard(message: _responseText),
            ),
          
          Expanded(
            flex: 3,
            child: _proxies.isEmpty
                ? const Center(
                    child: Text(
                      'No proxies fetched yet. Apply filters to get started.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: DesignTokens.fontSizeMedium,
                        color: DesignTokens.textSecondaryColor,
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(DesignTokens.spacingMedium),
                    itemCount: _proxies.length,
                    itemBuilder: (context, index) {
                      final proxy = _proxies[index];
                      return Padding(
                        padding: const EdgeInsets.only(
                          bottom: DesignTokens.spacingMedium,
                        ),
                        child: ProxyCard(proxy: proxy),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
