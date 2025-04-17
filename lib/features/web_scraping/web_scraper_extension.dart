import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;

import 'web_scraper.dart';
import 'dynamic_user_agent_manager.dart';
import 'scraping_exception.dart';

/// Extension methods for WebScraper to enhance error handling and retry logic
extension WebScraperExtension on WebScraper {
  /// Fetches HTML content with enhanced error handling and retry logic
  ///
  /// This method adds additional error handling specifically for connection issues
  /// and implements a more robust retry mechanism with exponential backoff
  Future<String> fetchHtmlWithRetry({
    required String url,
    Map<String, String>? headers,
    int? timeout,
    int? retries,
    int initialBackoffMs = 500,
    double backoffMultiplier = 1.5,
    int maxBackoffMs = 10000,
  }) async {
    // Use the WebScraper's fetchHtml method which now uses adaptive strategy
    return fetchHtml(
      url: url,
      headers: headers,
      timeout: timeout,
      retries: retries,
    );
  }

  /// Fetches HTML content from a problematic site using specialized techniques
  ///
  /// This method uses multiple approaches to handle sites that are known to be
  /// difficult to scrape, such as those with anti-scraping measures
  Future<String> fetchFromProblematicSite({
    required String url,
    Map<String, String>? headers,
    int? timeout = 60000,
    int? retries = 5,
  }) async {
    // Log the attempt
    logger.info('Attempting to fetch from problematic site: $url');

    // First try with the standard method
    try {
      return await fetchHtml(
        url: url,
        headers: headers,
        timeout: timeout,
        retries: retries,
      );
    } catch (e) {
      logger.warning('Standard fetch failed: $e');
      logger.info('Trying alternative approaches...');

      // Try with different approaches
      return _tryAlternativeApproaches(url, headers, timeout ?? 60000);
    }
  }

  /// Tries multiple alternative approaches to fetch from a problematic site
  Future<String> _tryAlternativeApproaches(
    String url,
    Map<String, String>? headers,
    int timeout,
  ) async {
    // Create a dynamic user agent manager
    final userAgentManager = DynamicUserAgentManager(logger: logger);

    // Get a sequence of user agents to try for this site
    final userAgents = userAgentManager.getUserAgentSequenceForProblematicSite(
      url,
    );
    logger.info('Prepared ${userAgents.length} user agents to try');

    // Try with different user agents
    for (final userAgent in userAgents) {
      try {
        logger.info('Trying with user agent: ${_truncateUserAgent(userAgent)}');

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
          ...?headers,
        };

        // Try with http package directly
        final response = await http
            .get(Uri.parse(url), headers: enhancedHeaders)
            .timeout(Duration(milliseconds: timeout));

        if (response.statusCode >= 200 && response.statusCode < 300) {
          logger.success(
            'Successfully fetched with user agent: ${_truncateUserAgent(userAgent)}',
          );
          return response.body;
        }
      } catch (e) {
        logger.error(
          'Failed with user agent ${_truncateUserAgent(userAgent)}: $e',
        );
        // Continue to the next user agent
      }
    }

    // Try with HttpClient directly with a different user agent
    try {
      logger.info('Trying with HttpClient directly');

      // Get a specific user agent for HttpClient
      final httpClientUserAgent = userAgentManager.getUserAgentByType(
        BrowserType.chrome,
      );
      logger.info(
        'Using Chrome user agent for HttpClient: ${_truncateUserAgent(httpClientUserAgent)}',
      );

      final httpClient = HttpClient();
      httpClient.connectionTimeout = Duration(milliseconds: timeout ~/ 2);
      httpClient.idleTimeout = Duration(milliseconds: timeout);
      httpClient.badCertificateCallback = (cert, host, port) => true;

      final request = await httpClient.getUrl(Uri.parse(url));

      // Add headers
      final effectiveHeaders = {
        'User-Agent': httpClientUserAgent,
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
        ...?headers,
      };

      effectiveHeaders.forEach((name, value) {
        request.headers.set(name, value);
      });

      final response = await request.close();

      if (response.statusCode >= 200 && response.statusCode < 300) {
        logger.success('Successfully fetched with HttpClient');

        final contents = StringBuffer();
        await for (var data in response.transform(utf8.decoder)) {
          contents.write(data);
        }

        return contents.toString();
      } else {
        throw Exception('HTTP error: ${response.statusCode}');
      }
    } catch (e) {
      logger.error('Failed with HttpClient: $e');
    } finally {
      // No need to close httpClient here as it's created locally
    }

    // Try with alternative URL format (without port)
    if (url.contains(':443')) {
      try {
        logger.info('Trying with alternative URL format (without port)');

        final alternativeUrl = url.replaceAll(':443', '');

        // Get a mobile user agent for this attempt
        final mobileUserAgent = userAgentManager.getUserAgentByType(
          BrowserType.mobile,
        );
        logger.info(
          'Using mobile user agent for alternative URL: ${_truncateUserAgent(mobileUserAgent)}',
        );

        // Create headers with mobile user agent
        final mobileHeaders = headers ?? {};
        mobileHeaders['User-Agent'] = mobileUserAgent;

        return await fetchHtml(
          url: alternativeUrl,
          headers: mobileHeaders,
          timeout: timeout,
          retries: 3,
        );
      } catch (e) {
        logger.error('Failed with alternative URL format: $e');
      }
    }

    // If all approaches fail, throw an exception
    throw ScrapingException.network(
      'All approaches failed for problematic site',
      url: url,
      isRetryable: false,
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
