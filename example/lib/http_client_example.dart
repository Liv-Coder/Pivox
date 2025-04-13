import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:pivox/pivox.dart';

class HttpClientExample extends StatefulWidget {
  const HttpClientExample({super.key});

  @override
  State<HttpClientExample> createState() => _HttpClientExampleState();
}

class _HttpClientExampleState extends State<HttpClientExample> {
  late PivoxClient _pivoxClient;
  late DefaultProxyPoolManager _poolManager;

  List<Proxy> _proxies = [];
  String _responseText = '';
  bool _isLoading = false;
  bool _isFetchingProxies = false;

  @override
  void initState() {
    super.initState();
    _initializePivox();
  }

  Future<void> _initializePivox() async {
    // Create rotation strategy
    final rotationStrategy = RoundRobinRotation();

    // Create proxy sources
    final sources = [
      FreeProxyListScraper(),
      GeoNodeProxySource(limit: 50),
      ProxyScrapeSource(proxyType: ProxyType.http),
      ProxyScrapeSource(proxyType: ProxyType.https),
      ProxyNovaSource(),
    ];

    // Create pool manager
    _poolManager = DefaultProxyPoolManager(
      sources: sources,
      rotationStrategy: rotationStrategy,
      refreshInterval: const Duration(minutes: 30),
    );

    // Create validator
    final validator = HttpProxyValidator();

    // Create Pivox client
    _pivoxClient = PivoxClient(poolManager: _poolManager, validator: validator);

    // Initial proxy fetch
    _fetchProxies();
  }

  Future<void> _fetchProxies() async {
    if (_isFetchingProxies) return;

    setState(() {
      _isFetchingProxies = true;
      _responseText = 'Fetching proxies...';
    });

    try {
      // Manually trigger a refresh
      await _poolManager.refreshProxies();

      // Get active proxies
      final proxies = await _poolManager.getActiveProxies();

      setState(() {
        _proxies = proxies;
        _responseText = 'Found ${proxies.length} proxies';
        _isFetchingProxies = false;
      });
    } catch (e) {
      setState(() {
        _responseText = 'Error fetching proxies: $e';
        _isFetchingProxies = false;
      });
    }
  }

  Future<void> _makeRequestWithPivoxClient() async {
    setState(() {
      _isLoading = true;
      _responseText = 'Making request with PivoxHttpClient...';
    });

    try {
      // Create an HTTP client using Pivox
      final client = _pivoxClient.createHttpClient();

      try {
        // Make a request
        final response = await client.get(Uri.parse('https://httpbin.org/ip'));

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          setState(() {
            _responseText = 'Response: ${json.encode(data)}';
            _isLoading = false;
          });
        } else {
          setState(() {
            _responseText = 'Error: ${response.statusCode}';
            _isLoading = false;
          });
        }
      } finally {
        client.close();
      }
    } catch (e) {
      setState(() {
        _responseText = 'Error: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _makeRequestWithManualProxy() async {
    if (_proxies.isEmpty) {
      setState(() {
        _responseText = 'No proxies available';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _responseText = 'Making request with manual proxy configuration...';
    });

    try {
      // Get a proxy
      final proxy = await _pivoxClient.getProxy();

      if (proxy == null) {
        setState(() {
          _responseText = 'No valid proxy available';
          _isLoading = false;
        });
        return;
      }

      // Format the proxy URL
      final proxyUrl = PivoxClient.formatProxyUrl(proxy);

      // Create a client with the proxy
      final client = http.Client();

      try {
        // Create a request
        final request = http.Request(
          'GET',
          Uri.parse('https://httpbin.org/ip'),
        );

        // Add proxy headers if needed
        request.headers.addAll(PivoxClient.createProxyAuthHeaders(proxy));

        // Send the request through the proxy
        final streamedResponse = await client.send(request);
        final response = await http.Response.fromStream(streamedResponse);

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          setState(() {
            _responseText = 'Response via $proxyUrl: ${json.encode(data)}';
            _isLoading = false;
          });
        } else {
          setState(() {
            _responseText = 'Error: ${response.statusCode}';
            _isLoading = false;
          });
        }
      } finally {
        client.close();
      }
    } catch (e) {
      setState(() {
        _responseText = 'Error: $e';
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _poolManager.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('HTTP Client Example'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton(
              onPressed: _isFetchingProxies ? null : _fetchProxies,
              child: Text(_isFetchingProxies ? 'Fetching...' : 'Fetch Proxies'),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _isLoading ? null : _makeRequestWithPivoxClient,
              child: const Text('Use PivoxHttpClient'),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _isLoading ? null : _makeRequestWithManualProxy,
              child: const Text('Use Manual Proxy Configuration'),
            ),
            const SizedBox(height: 16),
            const Text(
              'Response:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(_responseText),
            ),
            const SizedBox(height: 16),
            const Text(
              'Available Proxies:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Expanded(
              child:
                  _proxies.isEmpty
                      ? const Center(child: Text('No proxies available'))
                      : ListView.builder(
                        itemCount: _proxies.length,
                        itemBuilder: (context, index) {
                          final proxy = _proxies[index];
                          return ListTile(
                            title: Text('${proxy.host}:${proxy.port}'),
                            subtitle: Text(
                              'Type: ${proxy.type.name}, '
                              'Response Time: ${proxy.responseTime}ms',
                            ),
                          );
                        },
                      ),
            ),
          ],
        ),
      ),
    );
  }
}
