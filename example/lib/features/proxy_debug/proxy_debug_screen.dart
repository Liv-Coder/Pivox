import 'package:flutter/material.dart';
import 'package:pivox/pivox.dart';
import 'package:pivox/features/proxy_management/debug/proxy_debugger.dart';

import '../../core/widgets/base_screen.dart';

class ProxyDebugScreen extends StatefulWidget {
  const ProxyDebugScreen({super.key});

  @override
  State<ProxyDebugScreen> createState() => _ProxyDebugScreenState();
}

class _ProxyDebugScreenState extends State<ProxyDebugScreen> {
  ProxyManager? _proxyManager;
  ProxyDebugger? _proxyDebugger;

  bool _isLoading = false;
  String _statusMessage = 'Initializing...';
  String _diagnosticResults = '';
  bool _showFixButton = false;
  bool _fixAttempted = false;
  String _fixResults = '';

  @override
  void initState() {
    super.initState();
    _initializeProxyManager();
  }

  Future<void> _initializeProxyManager() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Initializing proxy manager...';
    });

    try {
      // Initialize the proxy manager
      _proxyManager = await Pivox.createProxyManager();

      // Create the proxy debugger
      _proxyDebugger = ProxyDebugger(_proxyManager!);

      setState(() {
        _statusMessage = 'Proxy manager initialized';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Error initializing proxy manager: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _runDiagnostic() async {
    if (_proxyDebugger == null) {
      setState(() {
        _statusMessage = 'Proxy debugger not initialized';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _statusMessage = 'Running proxy diagnostic...';
      _diagnosticResults = '';
      _showFixButton = false;
    });

    try {
      final result = await _proxyDebugger!.runDiagnostic(
        testAllSources: true,
        validateProxies: true,
        testUrl: 'https://www.google.com',
        timeout: 15000,
      );

      setState(() {
        _diagnosticResults = result.getSummary();
        _isLoading = false;
        _statusMessage = 'Diagnostic complete';

        // Show fix button if there are issues
        _showFixButton =
            result.getNextProxySuccess != true ||
            result.currentValidatedProxies == 0;
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Error running diagnostic: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _attemptFix() async {
    if (_proxyDebugger == null) {
      setState(() {
        _statusMessage = 'Proxy debugger not initialized';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _statusMessage = 'Attempting to fix proxy issues...';
      _fixResults = '';
      _fixAttempted = true;
    });

    try {
      final result = await _proxyDebugger!.attemptFix();

      final buffer = StringBuffer();
      buffer.writeln('=== Fix Attempt Results ===');

      for (final step in result.steps) {
        buffer.writeln('- $step');
      }

      buffer.writeln('\nFix successful: ${result.fixSuccessful}');
      buffer.writeln('Proxies fetched: ${result.proxyCount}');
      buffer.writeln('Validated proxies: ${result.validatedProxyCount}');

      if (result.usesUnvalidatedProxies) {
        buffer.writeln('\nWARNING: Using unvalidated proxies as fallback');
      }

      setState(() {
        _fixResults = buffer.toString();
        _isLoading = false;
        _statusMessage =
            result.fixSuccessful
                ? 'Fix attempt successful'
                : 'Fix attempt completed with issues';
      });

      // Run diagnostic again to see the results
      await _runDiagnostic();
    } catch (e) {
      setState(() {
        _statusMessage = 'Error attempting fix: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return BaseScreen(
      title: 'Proxy Debugger',
      showBackButton: true,
      showThemeToggle: true,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Proxy System Status',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(_statusMessage),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _runDiagnostic,
                            child: const Text('Run Diagnostic'),
                          ),
                        ),
                        if (_showFixButton) ...[
                          const SizedBox(width: 16),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _attemptFix,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange,
                              ),
                              child: const Text('Attempt Fix'),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child:
                  _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (_diagnosticResults.isNotEmpty) ...[
                              Card(
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Diagnostic Results',
                                        style:
                                            Theme.of(
                                              context,
                                            ).textTheme.titleLarge,
                                      ),
                                      const SizedBox(height: 8),
                                      Container(
                                        padding: const EdgeInsets.all(8.0),
                                        decoration: BoxDecoration(
                                          color: Colors.grey[200],
                                          borderRadius: BorderRadius.circular(
                                            4.0,
                                          ),
                                        ),
                                        child: SelectableText(
                                          _diagnosticResults,
                                          style: const TextStyle(
                                            fontFamily: 'monospace',
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                            if (_fixAttempted && _fixResults.isNotEmpty) ...[
                              const SizedBox(height: 16),
                              Card(
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Fix Attempt Results',
                                        style:
                                            Theme.of(
                                              context,
                                            ).textTheme.titleLarge,
                                      ),
                                      const SizedBox(height: 8),
                                      Container(
                                        padding: const EdgeInsets.all(8.0),
                                        decoration: BoxDecoration(
                                          color: Colors.grey[200],
                                          borderRadius: BorderRadius.circular(
                                            4.0,
                                          ),
                                        ),
                                        child: SelectableText(
                                          _fixResults,
                                          style: const TextStyle(
                                            fontFamily: 'monospace',
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
            ),
          ],
        ),
      ),
    );
  }
}
