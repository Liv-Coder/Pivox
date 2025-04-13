import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:dio/dio.dart';
import 'package:pivox/pivox.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ionicons/ionicons.dart';

import 'core/design/app_theme.dart';
import 'core/design/design_tokens.dart';
import 'core/widgets/proxy_card.dart';
import 'core/widgets/status_card.dart';
import 'core/widgets/action_button.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  ThemeMode _themeMode = ThemeMode.system;

  @override
  void initState() {
    super.initState();
    _loadThemePreference();
  }

  Future<void> _loadThemePreference() async {
    final prefs = await SharedPreferences.getInstance();
    final themeString = prefs.getString('theme_mode') ?? 'system';
    setState(() {
      _themeMode = _themeStringToMode(themeString);
    });
  }

  Future<void> _saveThemePreference(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('theme_mode', _themeModeToString(mode));
  }

  String _themeModeToString(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.system:
        return 'system';
    }
  }

  ThemeMode _themeStringToMode(String themeString) {
    switch (themeString) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      case 'system':
      default:
        return ThemeMode.system;
    }
  }

  void _toggleTheme() {
    setState(() {
      if (_themeMode == ThemeMode.light) {
        _themeMode = ThemeMode.dark;
      } else if (_themeMode == ThemeMode.dark) {
        _themeMode = ThemeMode.system;
      } else {
        _themeMode = ThemeMode.light;
      }
      _saveThemePreference(_themeMode);
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pivox Demo',
      theme: AppTheme.lightTheme(),
      darkTheme: AppTheme.darkTheme(),
      themeMode: _themeMode,
      home: MyHomePage(
        title: 'Pivox - Free Proxy Rotator',
        toggleTheme: _toggleTheme,
        themeMode: _themeMode,
      ),
      debugShowCheckedModeBanner: false,
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({
    super.key,
    required this.title,
    this.toggleTheme,
    this.themeMode,
  });

  final String title;
  final VoidCallback? toggleTheme;
  final ThemeMode? themeMode;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final List<ProxyModel> _proxies = [];
  bool _isLoading = false;
  String _responseText = '';
  late ProxyManager _proxyManager;
  late ProxyHttpClient _httpClient;
  late Dio _dio;

  @override
  void initState() {
    super.initState();
    _initializeProxyManager();
  }

  Future<void> _initializeProxyManager() async {
    // This is a simplified example. In a real app, you would use dependency injection
    final sharedPreferences = await SharedPreferences.getInstance();

    final localDataSource = ProxyLocalDataSourceImpl(
      sharedPreferences: sharedPreferences,
    );

    final remoteDataSource = ProxyRemoteDataSourceImpl(client: http.Client());

    final repository = ProxyRepositoryImpl(
      remoteDataSource: remoteDataSource,
      localDataSource: localDataSource,
      client: http.Client(),
    );

    final getProxies = GetProxies(repository);
    final validateProxy = ValidateProxy(repository);
    final getValidatedProxies = GetValidatedProxies(repository);

    _proxyManager = ProxyManager(
      getProxies: getProxies,
      validateProxy: validateProxy,
      getValidatedProxies: getValidatedProxies,
    );

    _httpClient = ProxyHttpClient(
      proxyManager: _proxyManager,
      useValidatedProxies: true,
      rotateProxies: true,
    );

    _dio =
        Dio()
          ..interceptors.add(
            ProxyInterceptor(
              proxyManager: _proxyManager,
              useValidatedProxies: true,
              rotateProxies: true,
            ),
          );
  }

  Future<void> _fetchProxies() async {
    setState(() {
      _isLoading = true;
      _responseText = '';
    });

    try {
      final proxies = await _proxyManager.fetchProxies(
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
      final response = await _httpClient.get(
        Uri.parse('https://api.ipify.org?format=json'),
      );

      setState(() {
        _responseText = 'HTTP Response: ${response.body}';
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
      final response = await _dio.get('https://api.ipify.org?format=json');

      setState(() {
        _responseText = 'Dio Response: ${response.data}';
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
          if (widget.toggleTheme != null)
            IconButton(
              icon: Icon(
                widget.themeMode == ThemeMode.light
                    ? Ionicons.sunny_outline
                    : widget.themeMode == ThemeMode.dark
                    ? Ionicons.moon_outline
                    : Ionicons.contrast_outline,
              ),
              onPressed: widget.toggleTheme,
              tooltip: 'Toggle theme',
            ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(DesignTokens.spacingMedium),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Action buttons section
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(DesignTokens.spacingMedium),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Proxy Actions',
                        style: Theme.of(
                          context,
                        ).textTheme.titleMedium?.copyWith(
                          fontWeight: DesignTokens.fontWeightSemiBold,
                        ),
                      ),
                      const SizedBox(height: DesignTokens.spacingMedium),
                      Row(
                        children: [
                          Expanded(
                            child: ActionButton(
                              text: 'Fetch Proxies',
                              icon: Ionicons.refresh_outline,
                              onPressed: _isLoading ? null : _fetchProxies,
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
                              text: 'Test HTTP',
                              icon: Ionicons.code_working_outline,
                              onPressed:
                                  _isLoading || _proxies.isEmpty
                                      ? null
                                      : _fetchWithHttp,
                              isLoading: _isLoading,
                            ),
                          ),
                          const SizedBox(width: DesignTokens.spacingMedium),
                          Expanded(
                            child: ActionButton(
                              text: 'Test Dio',
                              icon: Ionicons.server_outline,
                              onPressed:
                                  _isLoading || _proxies.isEmpty
                                      ? null
                                      : _fetchWithDio,
                              isLoading: _isLoading,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: DesignTokens.spacingMedium),

              // Status message
              if (_responseText.isNotEmpty)
                StatusCard(
                  message: _responseText,
                  type:
                      _responseText.contains('Error')
                          ? StatusType.error
                          : StatusType.success,
                ),

              const SizedBox(height: DesignTokens.spacingMedium),

              // Proxies list header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Available Proxies',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: DesignTokens.fontWeightSemiBold,
                    ),
                  ),
                  if (_proxies.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: DesignTokens.spacingSmall,
                        vertical: DesignTokens.spacingXXSmall,
                      ),
                      decoration: BoxDecoration(
                        color: DesignTokens.primaryColor,
                        borderRadius: BorderRadius.circular(
                          DesignTokens.borderRadiusCircular,
                        ),
                      ),
                      child: Text(
                        '${_proxies.length}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.white,
                          fontWeight: DesignTokens.fontWeightSemiBold,
                        ),
                      ),
                    ),
                ],
              ),

              const SizedBox(height: DesignTokens.spacingSmall),

              // Proxies list
              Expanded(
                child:
                    _proxies.isEmpty
                        ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Ionicons.globe_outline,
                                size: 64,
                                color: DesignTokens.textTertiaryColor,
                              ),
                              const SizedBox(
                                height: DesignTokens.spacingMedium,
                              ),
                              Text(
                                'No proxies available',
                                style: Theme.of(
                                  context,
                                ).textTheme.titleMedium?.copyWith(
                                  color: DesignTokens.textSecondaryColor,
                                ),
                              ),
                              const SizedBox(height: DesignTokens.spacingSmall),
                              Text(
                                'Tap "Fetch Proxies" to get started',
                                style: Theme.of(
                                  context,
                                ).textTheme.bodyMedium?.copyWith(
                                  color: DesignTokens.textTertiaryColor,
                                ),
                              ),
                            ],
                          ),
                        )
                        : ListView.builder(
                          itemCount: _proxies.length,
                          itemBuilder: (context, index) {
                            final proxy = _proxies[index];
                            // Add a random response time for demonstration purposes
                            final responseTime =
                                index % 3 == 0
                                    ? 300
                                    : (index % 3 == 1 ? 800 : 1500);
                            final proxyWithResponseTime = ProxyModel(
                              ip: proxy.ip,
                              port: proxy.port,
                              countryCode: proxy.countryCode,
                              isHttps: proxy.isHttps,
                              anonymityLevel: proxy.anonymityLevel,
                              responseTime: responseTime,
                            );
                            return ProxyCard(proxy: proxyWithResponseTime);
                          },
                        ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
