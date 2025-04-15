import 'dart:async';

import '../proxy_management/presentation/managers/proxy_manager.dart';
import 'advanced_web_scraper.dart';
import 'cookie_manager.dart';
import 'data_cache_manager.dart';
import 'rate_limiter.dart';
import 'scraping_job_scheduler.dart';
import 'user_agent_rotator.dart';

/// A comprehensive web scraping solution built on Pivox
class PivoxScraper {
  /// The advanced web scraper
  final AdvancedWebScraper _scraper;

  /// The rate limiter
  final RateLimiter _rateLimiter;

  /// The user agent rotator
  final UserAgentRotator _userAgentRotator;

  /// The cookie manager
  final CookieManager _cookieManager;

  /// The data cache manager
  final DataCacheManager _storageManager;

  /// The scraping job scheduler
  final ScrapingJobScheduler _jobScheduler;

  /// Creates a new [PivoxScraper] with the given components
  PivoxScraper({
    required AdvancedWebScraper scraper,
    required RateLimiter rateLimiter,
    required UserAgentRotator userAgentRotator,
    required CookieManager cookieManager,
    required DataCacheManager storageManager,
    required ScrapingJobScheduler jobScheduler,
  }) : _scraper = scraper,
       _rateLimiter = rateLimiter,
       _userAgentRotator = userAgentRotator,
       _cookieManager = cookieManager,
       _storageManager = storageManager,
       _jobScheduler = jobScheduler;

  /// Factory constructor to create a [PivoxScraper] with default components
  static Future<PivoxScraper> create({
    required ProxyManager proxyManager,
    int defaultTimeout = 30000,
    int maxRetries = 3,
    int defaultDelayMs = 1000,
    Map<String, int>? domainDelays,
    List<String>? userAgents,
    bool handleCookies = true,
    bool followRedirects = true,

    bool useDatabase = true,
  }) async {
    // Create components
    final rateLimiter = RateLimiter(
      defaultDelayMs: defaultDelayMs,
      domainDelays: domainDelays,
    );

    final userAgentRotator = UserAgentRotator(userAgents: userAgents);

    final cookieManager = await CookieManager.create();

    final scraper = await AdvancedWebScraper.create(
      proxyManager: proxyManager,
      defaultTimeout: defaultTimeout,
      maxRetries: maxRetries,
      handleCookies: handleCookies,
      followRedirects: followRedirects,
    );

    final storageManager = await DataCacheManager.create(
      useDatabase: useDatabase,
    );

    final jobScheduler = await ScrapingJobScheduler.create(scraper);

    return PivoxScraper(
      scraper: scraper,
      rateLimiter: rateLimiter,
      userAgentRotator: userAgentRotator,
      cookieManager: cookieManager,
      storageManager: storageManager,
      jobScheduler: jobScheduler,
    );
  }

  /// Gets the advanced web scraper
  AdvancedWebScraper get scraper => _scraper;

  /// Gets the rate limiter
  RateLimiter get rateLimiter => _rateLimiter;

  /// Gets the user agent rotator
  UserAgentRotator get userAgentRotator => _userAgentRotator;

  /// Gets the cookie manager
  CookieManager get cookieManager => _cookieManager;

  /// Gets the data cache manager
  DataCacheManager get storageManager => _storageManager;

  /// Gets the scraping job scheduler
  ScrapingJobScheduler get jobScheduler => _jobScheduler;

  /// Fetches HTML content from the given URL
  ///
  /// [url] is the URL to fetch
  /// [headers] are additional headers to send with the request
  /// [timeout] is the timeout for the request in milliseconds
  /// [retries] is the number of retry attempts
  Future<String> fetchHtml({
    required String url,
    Map<String, String>? headers,
    int? timeout,
    int? retries,
  }) {
    return _scraper.fetchHtml(
      url: url,
      headers: headers,
      timeout: timeout,
      retries: retries,
    );
  }

  /// Fetches JSON content from the given URL
  ///
  /// [url] is the URL to fetch
  /// [headers] are additional headers to send with the request
  /// [timeout] is the timeout for the request in milliseconds
  /// [retries] is the number of retry attempts
  Future<Map<String, dynamic>> fetchJson({
    required String url,
    Map<String, String>? headers,
    int? timeout,
    int? retries,
  }) {
    return _scraper.fetchJson(
      url: url,
      headers: headers,
      timeout: timeout,
      retries: retries,
    );
  }

  /// Submits a form with the given data
  ///
  /// [url] is the URL to submit the form to
  /// [method] is the HTTP method to use (GET or POST)
  /// [formData] is the form data to submit
  /// [headers] are additional headers to send with the request
  /// [timeout] is the timeout for the request in milliseconds
  /// [retries] is the number of retry attempts
  Future<String> submitForm({
    required String url,
    String method = 'POST',
    required Map<String, String> formData,
    Map<String, String>? headers,
    int? timeout,
    int? retries,
  }) {
    return _scraper.submitForm(
      url: url,
      method: method,
      formData: formData,
      headers: headers,
      timeout: timeout,
      retries: retries,
    );
  }

  /// Extracts data from HTML content using CSS selectors
  ///
  /// [html] is the HTML content to parse
  /// [selector] is the CSS selector to use
  /// [attribute] is the attribute to extract (optional)
  /// [asText] whether to extract the text content (default: true)
  List<String> extractData({
    required String html,
    required String selector,
    String? attribute,
    bool asText = true,
  }) {
    return _scraper.extractData(
      html: html,
      selector: selector,
      attribute: attribute,
      asText: asText,
    );
  }

  /// Extracts structured data from HTML content using CSS selectors
  ///
  /// [html] is the HTML content to parse
  /// [selectors] is a map of field names to CSS selectors
  /// [attributes] is a map of field names to attributes to extract (optional)
  List<Map<String, String>> extractStructuredData({
    required String html,
    required Map<String, String> selectors,
    Map<String, String?>? attributes,
  }) {
    return _scraper.extractStructuredData(
      html: html,
      selectors: selectors,
      attributes: attributes,
    );
  }

  /// Schedules a scraping job
  ///
  /// [id] is the unique identifier for the job
  /// [url] is the URL to scrape
  /// [interval] is the interval between runs in milliseconds
  /// [selectors] is a map of field names to CSS selectors
  /// [attributes] is a map of field names to attributes to extract (optional)
  /// [storeResults] whether to store the results in the data storage manager
  /// [onResult] is a callback for handling the results
  /// [onError] is a callback for handling errors
  void scheduleJob({
    required String id,
    required String url,
    required int interval,
    required Map<String, String> selectors,
    Map<String, String?>? attributes,
    bool storeResults = true,
    void Function(List<Map<String, String>>)? onResult,
    void Function(Exception)? onError,
  }) {
    _jobScheduler.scheduleJob(
      id: id,
      url: url,
      interval: interval,
      selectors: selectors,
      attributes: attributes,
      onResult: (results) {
        if (storeResults) {
          _storageManager.storeStructuredData(id, url, results);
        }
        onResult?.call(results);
      },
      onError: onError,
    );
  }

  /// Cancels a scraping job
  ///
  /// [id] is the unique identifier for the job
  void cancelJob(String id) {
    _jobScheduler.cancelJob(id);
  }

  /// Gets all scheduled jobs
  List<ScrapingJob> getJobs() {
    return _jobScheduler.getJobs();
  }

  /// Restores all jobs from storage
  void restoreJobs({
    bool storeResults = true,
    void Function(List<Map<String, String>>, String)? onResult,
    void Function(Exception, String)? onError,
  }) {
    _jobScheduler.restoreJobs(
      onResult: (results, id) {
        if (storeResults) {
          final jobs = _jobScheduler.getJobs();
          final job = jobs.firstWhere((job) => job.id == id);
          _storageManager.storeStructuredData(id, job.url, results);
        }
        onResult?.call(results, id);
      },
      onError: onError,
    );
  }

  /// Stores data in the storage manager
  ///
  /// [id] is the unique identifier for the data
  /// [data] is the data to store
  Future<void> storeData(String id, dynamic data) {
    return _storageManager.storeData(id, data);
  }

  /// Gets data from the storage manager
  ///
  /// [id] is the unique identifier for the data
  dynamic getData(String id) {
    return _storageManager.getData(id);
  }

  /// Stores structured data in the storage manager
  ///
  /// [id] is the unique identifier for the data
  /// [source] is the source of the data (e.g., the URL)
  /// [data] is the data to store
  Future<void> storeStructuredData(String id, String source, dynamic data) {
    return _storageManager.storeStructuredData(id, source, data);
  }

  /// Gets structured data from the storage manager
  ///
  /// [id] is the unique identifier for the data
  Future<dynamic> getStructuredData(String id) {
    return _storageManager.getStructuredData(id);
  }

  /// Gets all structured data from the storage manager
  Future<List<Map<String, dynamic>>> getAllStructuredData() {
    return _storageManager.getAllStructuredData();
  }

  /// Exports data to a JSON file
  ///
  /// [filename] is the name of the file to export to
  Future<String> exportData(String filename) {
    return _storageManager.exportToJson(filename);
  }

  /// Imports data from a JSON file
  ///
  /// [filePath] is the path to the file to import from
  Future<void> importData(String filePath) {
    return _storageManager.importFromJson(filePath);
  }

  /// Sets a custom delay for a domain
  ///
  /// [domain] is the domain to set the delay for
  /// [delayMs] is the delay in milliseconds
  void setDomainDelay(String domain, int delayMs) {
    _rateLimiter.setDomainDelay(domain, delayMs);
  }

  /// Adds a user agent to the rotator
  ///
  /// [userAgent] is the user agent to add
  void addUserAgent(String userAgent) {
    _userAgentRotator.addUserAgent(userAgent);
  }

  /// Clears cookies for a domain
  ///
  /// [domain] is the domain to clear cookies for
  void clearCookies(String domain) {
    _cookieManager.clearCookies(domain);
  }

  /// Closes all resources
  Future<void> close() async {
    _scraper.close();
    _jobScheduler.dispose();
    await _storageManager.clear();
  }
}
