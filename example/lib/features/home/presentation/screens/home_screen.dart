import 'package:flutter/material.dart';
import 'package:ionicons/ionicons.dart';
import 'package:pivox/pivox.dart';

import '../../../../core/design/design_tokens.dart';
import '../../../../core/services/proxy_service.dart';
import '../../../../core/services/service_locator.dart';
import '../../../../core/services/theme_manager.dart';
import '../../../../core/widgets/action_button.dart';
import '../../../../core/widgets/proxy_card.dart';
import '../../../../core/widgets/status_card.dart';

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

  // Get services from service locator
  final _proxyService = serviceLocator<ProxyService>();
  final _themeManager = serviceLocator<ThemeManager>();

  Future<void> _fetchProxies() async {
    setState(() {
      _isLoading = true;
      _responseText = '';
    });

    try {
      final proxies = await _proxyService.fetchProxies(
        count: 20,
        onlyHttps: true,
      );

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

  Future<void> _fetchWithHttp() async {
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

  Future<void> _fetchWithDio() async {
    setState(() {
      _isLoading = true;
      _responseText = '';
    });

    try {
      final response = await _proxyService.makeDioRequest(
        'https://api.ipify.org?format=json',
      );

      setState(() {
        _responseText = 'Dio Response: $response';
      });
    } catch (e) {
      setState(() {
        _responseText = 'Error with Dio request: $e';
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
        title: Text(widget.title),
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(
              _themeManager.themeMode == ThemeMode.light
                  ? Ionicons.sunny_outline
                  : _themeManager.themeMode == ThemeMode.dark
                  ? Ionicons.moon_outline
                  : Ionicons.contrast_outline,
            ),
            onPressed: () {
              _themeManager.toggleTheme();
              setState(() {});
            },
            tooltip: 'Toggle theme',
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(DesignTokens.spacingMedium),
            child: LayoutBuilder(
              builder: (context, constraints) {
                // Use a column layout on smaller screens
                if (constraints.maxWidth < 600) {
                  return Column(
                    children: [
                      ActionButton(
                        onPressed: _fetchProxies,
                        icon: Ionicons.refresh_outline,
                        text: 'Fetch Proxies',
                        isLoading: _isLoading,
                      ),
                      const SizedBox(height: DesignTokens.spacingMedium),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ActionButton(
                            onPressed: _fetchWithHttp,
                            icon: Ionicons.globe_outline,
                            text: 'Test HTTP',
                            isLoading: _isLoading,
                          ),
                          const SizedBox(width: DesignTokens.spacingMedium),
                          ActionButton(
                            onPressed: _fetchWithDio,
                            icon: Ionicons.rocket_outline,
                            text: 'Test Dio',
                            isLoading: _isLoading,
                          ),
                        ],
                      ),
                    ],
                  );
                } else {
                  // Use a row layout on larger screens
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Expanded(
                        child: ActionButton(
                          onPressed: _fetchProxies,
                          icon: Ionicons.refresh_outline,
                          text: 'Fetch Proxies',
                          isLoading: _isLoading,
                        ),
                      ),
                      const SizedBox(width: DesignTokens.spacingMedium),
                      Expanded(
                        child: ActionButton(
                          onPressed: _fetchWithHttp,
                          icon: Ionicons.globe_outline,
                          text: 'Test HTTP',
                          isLoading: _isLoading,
                        ),
                      ),
                      const SizedBox(width: DesignTokens.spacingMedium),
                      Expanded(
                        child: ActionButton(
                          onPressed: _fetchWithDio,
                          icon: Ionicons.rocket_outline,
                          text: 'Test Dio',
                          isLoading: _isLoading,
                        ),
                      ),
                    ],
                  );
                }
              },
            ),
          ),
          if (_responseText.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(DesignTokens.spacingMedium),
              child: StatusCard(message: _responseText),
            ),
          Expanded(
            child:
                _proxies.isEmpty
                    ? const Center(
                      child: Text(
                        'No proxies fetched yet. Tap "Fetch Proxies" to get started.',
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
