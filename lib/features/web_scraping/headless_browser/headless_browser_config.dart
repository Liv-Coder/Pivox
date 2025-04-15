import 'package:flutter/foundation.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

/// Configuration options for the headless browser
class HeadlessBrowserConfig {
  /// User agent to use for the browser
  final String? userAgent;

  /// Whether to enable JavaScript
  final bool javaScriptEnabled;

  /// Whether to enable DOM storage
  final bool domStorageEnabled;

  /// Whether to allow mixed content
  final bool mixedContentMode;

  /// Whether to cache resources
  final bool cacheEnabled;

  /// Timeout for page loading in milliseconds
  final int timeoutMillis;

  /// Whether to block images from loading
  final bool blockImages;

  /// Whether to block popups
  final bool blockPopups;

  /// Custom headers to send with requests
  final Map<String, String>? customHeaders;

  /// Whether to clear cookies before each request
  final bool clearCookies;

  /// Whether to clear cache before each request
  final bool clearCache;

  /// Whether to ignore SSL errors
  final bool ignoreSSLErrors;

  /// Whether to enable logging
  final bool loggingEnabled;

  /// Creates a new [HeadlessBrowserConfig] instance
  const HeadlessBrowserConfig({
    this.userAgent,
    this.javaScriptEnabled = true,
    this.domStorageEnabled = true,
    this.mixedContentMode = true,
    this.cacheEnabled = true,
    this.timeoutMillis = 30000,
    this.blockImages = false,
    this.blockPopups = true,
    this.customHeaders,
    this.clearCookies = false,
    this.clearCache = false,
    this.ignoreSSLErrors = false,
    this.loggingEnabled = kDebugMode,
  });

  /// Creates a new [HeadlessBrowserConfig] instance with default values
  factory HeadlessBrowserConfig.defaultConfig() {
    return const HeadlessBrowserConfig();
  }

  /// Creates a new [HeadlessBrowserConfig] instance optimized for performance
  factory HeadlessBrowserConfig.performance() {
    return const HeadlessBrowserConfig(
      blockImages: true,
      cacheEnabled: true,
      timeoutMillis: 15000,
    );
  }

  /// Creates a new [HeadlessBrowserConfig] instance optimized for stealth
  factory HeadlessBrowserConfig.stealth() {
    return const HeadlessBrowserConfig(
      clearCookies: true,
      clearCache: true,
      customHeaders: {
        'Accept':
            'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8',
        'Accept-Language': 'en-US,en;q=0.5',
        'DNT': '1',
        'Upgrade-Insecure-Requests': '1',
      },
    );
  }

  /// Converts this configuration to InAppWebView settings
  InAppWebViewSettings toInAppWebViewSettings() {
    return InAppWebViewSettings(
      userAgent: userAgent,
      javaScriptEnabled: javaScriptEnabled,
      cacheEnabled: cacheEnabled,
      // preferredContentMode is no longer available in the new API
      useShouldOverrideUrlLoading: true,
      mediaPlaybackRequiresUserGesture: false,
      verticalScrollBarEnabled: false,
      horizontalScrollBarEnabled: false,
      transparentBackground: true,
      supportZoom: false,
      disableHorizontalScroll: true,
      disableVerticalScroll: true,
      disableContextMenu: true,
      useHybridComposition: true,
      domStorageEnabled: domStorageEnabled,
      mixedContentMode:
          mixedContentMode
              ? MixedContentMode.MIXED_CONTENT_ALWAYS_ALLOW
              : MixedContentMode.MIXED_CONTENT_NEVER_ALLOW,
      blockNetworkImage: blockImages,
      safeBrowsingEnabled: false,
      disableDefaultErrorPage: true,
      allowsInlineMediaPlayback: true,
      allowsBackForwardNavigationGestures: false,
      allowsLinkPreview: false,
      isFraudulentWebsiteWarningEnabled: false,
      disableLongPressContextMenuOnLinks: true,
      suppressesIncrementalRendering: false,
    );
  }

  /// Creates a copy of this configuration with the given fields replaced
  HeadlessBrowserConfig copyWith({
    String? userAgent,
    bool? javaScriptEnabled,
    bool? domStorageEnabled,
    bool? mixedContentMode,
    bool? cacheEnabled,
    int? timeoutMillis,
    bool? blockImages,
    bool? blockPopups,
    Map<String, String>? customHeaders,
    bool? clearCookies,
    bool? clearCache,
    bool? ignoreSSLErrors,
    bool? loggingEnabled,
  }) {
    return HeadlessBrowserConfig(
      userAgent: userAgent ?? this.userAgent,
      javaScriptEnabled: javaScriptEnabled ?? this.javaScriptEnabled,
      domStorageEnabled: domStorageEnabled ?? this.domStorageEnabled,
      mixedContentMode: mixedContentMode ?? this.mixedContentMode,
      cacheEnabled: cacheEnabled ?? this.cacheEnabled,
      timeoutMillis: timeoutMillis ?? this.timeoutMillis,
      blockImages: blockImages ?? this.blockImages,
      blockPopups: blockPopups ?? this.blockPopups,
      customHeaders: customHeaders ?? this.customHeaders,
      clearCookies: clearCookies ?? this.clearCookies,
      clearCache: clearCache ?? this.clearCache,
      ignoreSSLErrors: ignoreSSLErrors ?? this.ignoreSSLErrors,
      loggingEnabled: loggingEnabled ?? this.loggingEnabled,
    );
  }
}
