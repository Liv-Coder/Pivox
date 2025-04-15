import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

import 'scraping_logger.dart';
import 'dynamic_user_agent_manager.dart';

/// A specialized handler for problematic websites
abstract class SpecializedSiteHandler {
  /// Checks if this handler can handle the given URL
  bool canHandle(String url);

  /// Fetches HTML content from the given URL
  Future<String> fetchHtml({
    required String url,
    required Map<String, String> headers,
    required int timeout,
    required ScrapingLogger logger,
  });
}

/// A registry of specialized site handlers
class SpecializedSiteHandlerRegistry {
  /// The list of registered handlers
  final List<SpecializedSiteHandler> _handlers = [];

  /// Creates a new [SpecializedSiteHandlerRegistry] with default handlers
  SpecializedSiteHandlerRegistry() {
    // Register default handlers
    registerHandler(OnlineKhabarHandler());
    registerHandler(VegaMoviesHandler());
  }

  /// Registers a new handler
  void registerHandler(SpecializedSiteHandler handler) {
    _handlers.add(handler);
  }

  /// Gets a handler for the given URL, or null if no handler is available
  SpecializedSiteHandler? getHandlerForUrl(String url) {
    for (final handler in _handlers) {
      if (handler.canHandle(url)) {
        return handler;
      }
    }
    return null;
  }

  /// Checks if there is a handler for the given URL
  bool hasHandlerForUrl(String url) {
    return getHandlerForUrl(url) != null;
  }
}

/// A specialized handler for onlinekhabar.com
class OnlineKhabarHandler implements SpecializedSiteHandler {
  /// The dynamic user agent manager
  final DynamicUserAgentManager _userAgentManager = DynamicUserAgentManager();

  @override
  bool canHandle(String url) {
    return url.contains('onlinekhabar.com');
  }

  @override
  Future<String> fetchHtml({
    required String url,
    required Map<String, String> headers,
    required int timeout,
    required ScrapingLogger logger,
  }) async {
    logger.info('Using specialized handler for onlinekhabar.com');

    // Get a sequence of user agents to try for this site
    final userAgents = _userAgentManager.getUserAgentSequenceForProblematicSite(
      url,
    );
    logger.info('Prepared ${userAgents.length} user agents to try');

    // Try with each user agent
    for (final userAgent in userAgents) {
      logger.info('Trying with user agent: ${_truncateUserAgent(userAgent)}');

      // Enhanced headers specifically for onlinekhabar.com
      final enhancedHeaders = {
        'User-Agent': userAgent,
        'Accept':
            'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8',
        'Accept-Language': 'en-US,en;q=0.5',
        'Accept-Encoding': 'gzip, deflate, br',
        'Connection': 'keep-alive',
        'Upgrade-Insecure-Requests': '1',
        'Cache-Control': 'max-age=0',
        'Sec-Fetch-Dest': 'document',
        'Sec-Fetch-Mode': 'navigate',
        'Sec-Fetch-Site': 'none',
        'Sec-Fetch-User': '?1',
        'Pragma': 'no-cache',
        ...headers,
      };

      // Try different approaches with this user agent
      try {
        // First try: HttpClient approach
        logger.info('Attempting direct HttpClient approach');
        try {
          final result = await _fetchWithHttpClient(
            url,
            enhancedHeaders,
            timeout,
            logger,
          );
          logger.success('Successfully fetched with HttpClient');
          return result;
        } catch (e) {
          logger.error('HttpClient approach failed: $e');
        }

        // Second try: http package
        logger.info('Attempting with http package');
        try {
          final response = await http
              .get(Uri.parse(url), headers: enhancedHeaders)
              .timeout(Duration(milliseconds: timeout));

          if (response.statusCode >= 200 && response.statusCode < 300) {
            logger.success('Successfully fetched with http package');
            return response.body;
          } else {
            logger.error('HTTP error: ${response.statusCode}');
          }
        } catch (e) {
          logger.error('http package approach failed: $e');
        }

        // Third try: Alternative URL format (without port)
        if (url.contains(':443')) {
          logger.info('Attempting with alternative URL format (without port)');
          final alternativeUrl = url.replaceAll(':443', '');

          try {
            final response = await http
                .get(Uri.parse(alternativeUrl), headers: enhancedHeaders)
                .timeout(Duration(milliseconds: timeout));

            if (response.statusCode >= 200 && response.statusCode < 300) {
              logger.success('Successfully fetched with alternative URL');
              return response.body;
            } else {
              logger.error(
                'HTTP error with alternative URL: ${response.statusCode}',
              );
            }
          } catch (e) {
            logger.error('Alternative URL approach failed: $e');
          }
        }
      } catch (e) {
        // This catch block should never be reached due to inner try-catch blocks,
        // but it's here as a safety net
        logger.error(
          'Unexpected error with user agent ${_truncateUserAgent(userAgent)}: $e',
        );
      }

      // If we reach here, all approaches with this user agent failed
      // We'll try the next user agent
    }

    // If we reach here, all user agents and approaches failed
    throw Exception(
      'All approaches failed for onlinekhabar.com after trying ${userAgents.length} user agents',
    );
  }

  /// Truncates a user agent string for logging
  String _truncateUserAgent(String userAgent) {
    if (userAgent.length <= 50) {
      return userAgent;
    }
    return '${userAgent.substring(0, 47)}...';
  }

  /// Fetches HTML content using HttpClient with specific settings
  Future<String> _fetchWithHttpClient(
    String url,
    Map<String, String> headers,
    int timeout,
    ScrapingLogger logger,
  ) async {
    final httpClient = HttpClient();

    try {
      // Configure client
      httpClient.connectionTimeout = Duration(milliseconds: timeout ~/ 2);
      httpClient.idleTimeout = Duration(milliseconds: timeout);
      httpClient.badCertificateCallback = (cert, host, port) => true;

      // Create request
      final request = await httpClient.getUrl(Uri.parse(url));

      // Add headers
      headers.forEach((name, value) {
        request.headers.set(name, value);
      });

      // Send request
      logger.request('Sending request to $url');
      final response = await request.close();
      logger.response('Received response: ${response.statusCode}');

      // Read response
      final completer = Completer<String>();
      final contents = StringBuffer();

      response
          .transform(utf8.decoder)
          .listen(
            (data) {
              contents.write(data);
            },
            onDone: () {
              completer.complete(contents.toString());
            },
            onError: (e) {
              completer.completeError(e);
            },
            cancelOnError: true,
          );

      return await completer.future;
    } finally {
      httpClient.close();
    }
  }
}

/// A specialized handler for vegamovies.td
class VegaMoviesHandler implements SpecializedSiteHandler {
  /// The dynamic user agent manager
  final DynamicUserAgentManager _userAgentManager = DynamicUserAgentManager();

  @override
  bool canHandle(String url) {
    return url.contains('vegamovies');
  }

  @override
  Future<String> fetchHtml({
    required String url,
    required Map<String, String> headers,
    required int timeout,
    required ScrapingLogger logger,
  }) async {
    logger.info('Using specialized handler for vegamovies');

    // Get a sequence of user agents to try for this site
    final userAgents = _userAgentManager.getUserAgentSequenceForProblematicSite(
      url,
    );
    logger.info('Prepared ${userAgents.length} user agents to try');

    // Ensure URL has proper scheme
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      url = 'https://$url';
    }

    // Try with each user agent
    for (final userAgent in userAgents) {
      logger.info('Trying with user agent: ${_truncateUserAgent(userAgent)}');

      // Enhanced headers specifically for vegamovies
      final enhancedHeaders = {
        'User-Agent': userAgent,
        'Accept':
            'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8',
        'Accept-Language': 'en-US,en;q=0.5',
        'Accept-Encoding': 'gzip, deflate, br',
        'Connection': 'keep-alive',
        'Upgrade-Insecure-Requests': '1',
        'Cache-Control': 'max-age=0',
        'Sec-Fetch-Dest': 'document',
        'Sec-Fetch-Mode': 'navigate',
        'Sec-Fetch-Site': 'none',
        'Sec-Fetch-User': '?1',
        'Pragma': 'no-cache',
        ...headers,
      };

      // Try different approaches with this user agent
      try {
        // First try: HttpClient approach
        logger.info('Attempting direct HttpClient approach');
        try {
          final httpClient = HttpClient();

          try {
            // Configure client
            httpClient.connectionTimeout = Duration(milliseconds: timeout ~/ 2);
            httpClient.idleTimeout = Duration(milliseconds: timeout);
            httpClient.badCertificateCallback = (cert, host, port) => true;

            // Create request
            final request = await httpClient.getUrl(Uri.parse(url));

            // Add headers
            enhancedHeaders.forEach((name, value) {
              request.headers.set(name, value);
            });

            // Send request
            logger.request('Sending request to $url');
            final response = await request.close();
            logger.response('Received response: ${response.statusCode}');

            // Read response
            final completer = Completer<String>();
            final contents = StringBuffer();

            response
                .transform(utf8.decoder)
                .listen(
                  (data) {
                    contents.write(data);
                  },
                  onDone: () {
                    completer.complete(contents.toString());
                  },
                  onError: (e) {
                    completer.completeError(e);
                  },
                  cancelOnError: true,
                );

            final result = await completer.future;
            logger.success('Successfully fetched with HttpClient');
            return result;
          } finally {
            httpClient.close();
          }
        } catch (e) {
          logger.error('HttpClient approach failed: $e');
        }

        // Second try: http package
        logger.info('Attempting with http package');
        try {
          final response = await http
              .get(Uri.parse(url), headers: enhancedHeaders)
              .timeout(Duration(milliseconds: timeout));

          if (response.statusCode >= 200 && response.statusCode < 300) {
            logger.success('Successfully fetched with http package');
            return response.body;
          } else {
            logger.error('HTTP error: ${response.statusCode}');
          }
        } catch (e) {
          logger.error('http package approach failed: $e');
        }

        // Third try: Try with different domain extensions
        logger.info('Attempting with different domain extensions');
        final domains = [
          'vegamovies.tv',
          'vegamovies.td',
          'vegamovies.nl',
          'vegamovies.lol',
        ];

        for (final domain in domains) {
          if (!url.contains(domain)) {
            final baseUrl = url.split('/').last;
            final alternativeUrl = 'https://$domain/$baseUrl';

            try {
              logger.info('Trying alternative domain: $alternativeUrl');
              final response = await http
                  .get(Uri.parse(alternativeUrl), headers: enhancedHeaders)
                  .timeout(Duration(milliseconds: timeout));

              if (response.statusCode >= 200 && response.statusCode < 300) {
                logger.success(
                  'Successfully fetched with alternative domain: $domain',
                );
                return response.body;
              } else {
                logger.error(
                  'HTTP error with alternative domain: ${response.statusCode}',
                );
              }
            } catch (e) {
              logger.error(
                'Alternative domain approach failed for $domain: $e',
              );
            }
          }
        }
      } catch (e) {
        // This catch block should never be reached due to inner try-catch blocks,
        // but it's here as a safety net
        logger.error(
          'Unexpected error with user agent ${_truncateUserAgent(userAgent)}: $e',
        );
      }

      // If we reach here, all approaches with this user agent failed
      // We'll try the next user agent
    }

    // If we reach here, all user agents and approaches failed
    throw Exception(
      'All approaches failed for vegamovies after trying ${userAgents.length} user agents',
    );
  }

  /// Truncates a user agent string for logging
  String _truncateUserAgent(String userAgent) {
    if (userAgent.length <= 50) {
      return userAgent;
    }
    return '${userAgent.substring(0, 47)}...';
  }
}
