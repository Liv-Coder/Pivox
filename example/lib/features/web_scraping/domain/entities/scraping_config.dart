/// Entity representing the configuration for a web scraping operation
class ScrapingConfig {
  /// The URL to scrape
  final String url;

  /// The CSS selector to use
  final String? selector;

  /// The attribute to extract (optional)
  final String? attribute;

  /// The timeout in milliseconds
  final int timeout;

  /// The number of retries
  final int retries;

  /// Whether to use structured data extraction
  final bool useStructuredData;

  /// Creates a new [ScrapingConfig]
  const ScrapingConfig({
    required this.url,
    this.selector,
    this.attribute,
    this.timeout = 60000,
    this.retries = 5,
    this.useStructuredData = false,
  });

  /// Creates a copy of this [ScrapingConfig] with the given fields replaced with new values
  ScrapingConfig copyWith({
    String? url,
    String? selector,
    String? attribute,
    int? timeout,
    int? retries,
    bool? useStructuredData,
  }) {
    return ScrapingConfig(
      url: url ?? this.url,
      selector: selector ?? this.selector,
      attribute: attribute ?? this.attribute,
      timeout: timeout ?? this.timeout,
      retries: retries ?? this.retries,
      useStructuredData: useStructuredData ?? this.useStructuredData,
    );
  }

  /// Creates a new [ScrapingConfig] for structured data extraction
  factory ScrapingConfig.forStructuredData({
    required String url,
    int timeout = 60000,
    int retries = 5,
  }) {
    return ScrapingConfig(
      url: url,
      timeout: timeout,
      retries: retries,
      useStructuredData: true,
    );
  }
}
