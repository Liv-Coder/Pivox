/// Scraping configuration entity
class ScrapingConfig {
  final String url;
  final Map<String, String>? headers;
  final Map<String, String> selectors;
  final bool useProxy;
  final bool useHeadlessBrowser;
  final int timeout;
  final int retries;
  final int? maxItems;
  final bool followPagination;
  final String? paginationSelector;
  final int? maxPages;
  final bool waitForSelector;
  final String? waitSelector;
  final int? waitTimeout;
  final String? userAgent;
  final bool respectRobotsTxt;

  const ScrapingConfig({
    required this.url,
    this.headers,
    required this.selectors,
    this.useProxy = true,
    this.useHeadlessBrowser = false,
    this.timeout = 30,
    this.retries = 3,
    this.maxItems,
    this.followPagination = false,
    this.paginationSelector,
    this.maxPages,
    this.waitForSelector = false,
    this.waitSelector,
    this.waitTimeout,
    this.userAgent,
    this.respectRobotsTxt = true,
  });

  /// Copy with new values
  ScrapingConfig copyWith({
    String? url,
    Map<String, String>? headers,
    Map<String, String>? selectors,
    bool? useProxy,
    bool? useHeadlessBrowser,
    int? timeout,
    int? retries,
    int? maxItems,
    bool? followPagination,
    String? paginationSelector,
    int? maxPages,
    bool? waitForSelector,
    String? waitSelector,
    int? waitTimeout,
    String? userAgent,
    bool? respectRobotsTxt,
  }) {
    return ScrapingConfig(
      url: url ?? this.url,
      headers: headers ?? this.headers,
      selectors: selectors ?? this.selectors,
      useProxy: useProxy ?? this.useProxy,
      useHeadlessBrowser: useHeadlessBrowser ?? this.useHeadlessBrowser,
      timeout: timeout ?? this.timeout,
      retries: retries ?? this.retries,
      maxItems: maxItems ?? this.maxItems,
      followPagination: followPagination ?? this.followPagination,
      paginationSelector: paginationSelector ?? this.paginationSelector,
      maxPages: maxPages ?? this.maxPages,
      waitForSelector: waitForSelector ?? this.waitForSelector,
      waitSelector: waitSelector ?? this.waitSelector,
      waitTimeout: waitTimeout ?? this.waitTimeout,
      userAgent: userAgent ?? this.userAgent,
      respectRobotsTxt: respectRobotsTxt ?? this.respectRobotsTxt,
    );
  }
}
