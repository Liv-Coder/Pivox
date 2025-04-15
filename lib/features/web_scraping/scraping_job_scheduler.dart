import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import 'advanced_web_scraper.dart';

/// A scheduler for recurring scraping jobs
class ScrapingJobScheduler {
  /// The advanced web scraper to use for jobs
  final AdvancedWebScraper _scraper;

  /// Shared preferences instance for storing job data
  final SharedPreferences _prefs;

  /// Map of job IDs to their timers
  final Map<String, Timer> _jobTimers = {};

  /// Key prefix for storing jobs in shared preferences
  static const String _jobKeyPrefix = 'scraping_job_';

  /// Creates a new [ScrapingJobScheduler] with the given parameters
  ScrapingJobScheduler(this._scraper, this._prefs);

  /// Factory constructor to create a [ScrapingJobScheduler] from shared preferences
  static Future<ScrapingJobScheduler> create(AdvancedWebScraper scraper) async {
    final prefs = await SharedPreferences.getInstance();
    return ScrapingJobScheduler(scraper, prefs);
  }

  /// Schedules a new scraping job
  ///
  /// [id] is the unique identifier for the job
  /// [url] is the URL to scrape
  /// [interval] is the interval between runs in milliseconds
  /// [selectors] is a map of field names to CSS selectors
  /// [attributes] is a map of field names to attributes to extract (optional)
  /// [onResult] is a callback for handling the results
  /// [onError] is a callback for handling errors
  void scheduleJob({
    required String id,
    required String url,
    required int interval,
    required Map<String, String> selectors,
    Map<String, String?>? attributes,
    void Function(List<Map<String, String>>)? onResult,
    void Function(Exception)? onError,
  }) {
    // Cancel any existing job with the same ID
    cancelJob(id);

    // Create a new job
    final job = ScrapingJob(
      id: id,
      url: url,
      interval: interval,
      selectors: selectors,
      attributes: attributes,
      lastRun: DateTime.now().millisecondsSinceEpoch,
    );

    // Save the job
    _saveJob(job);

    // Schedule the job
    _scheduleJob(job, onResult, onError);
  }

  /// Cancels a scraping job
  ///
  /// [id] is the unique identifier for the job
  void cancelJob(String id) {
    // Cancel the timer
    _jobTimers[id]?.cancel();
    _jobTimers.remove(id);

    // Remove the job from storage
    _prefs.remove(_jobKeyPrefix + id);
  }

  /// Gets all scheduled jobs
  List<ScrapingJob> getJobs() {
    final jobs = <ScrapingJob>[];
    final keys = _prefs.getKeys();

    for (final key in keys) {
      if (key.startsWith(_jobKeyPrefix)) {
        final jobJson = _prefs.getString(key);
        if (jobJson != null) {
          try {
            final jobMap = jsonDecode(jobJson) as Map<String, dynamic>;
            jobs.add(ScrapingJob.fromJson(jobMap));
          } catch (_) {
            // Ignore invalid jobs
          }
        }
      }
    }

    return jobs;
  }

  /// Restores all jobs from storage
  void restoreJobs({
    void Function(List<Map<String, String>>, String)? onResult,
    void Function(Exception, String)? onError,
  }) {
    final jobs = getJobs();

    for (final job in jobs) {
      _scheduleJob(
        job,
        onResult != null ? (result) => onResult(result, job.id) : null,
        onError != null ? (error) => onError(error, job.id) : null,
      );
    }
  }

  /// Saves a job to storage
  void _saveJob(ScrapingJob job) {
    _prefs.setString(_jobKeyPrefix + job.id, jsonEncode(job.toJson()));
  }

  /// Schedules a job to run
  void _scheduleJob(
    ScrapingJob job,
    void Function(List<Map<String, String>>)? onResult,
    void Function(Exception)? onError,
  ) {
    // Calculate the next run time
    final now = DateTime.now().millisecondsSinceEpoch;
    final nextRun = job.lastRun + job.interval;
    final delay = nextRun > now ? nextRun - now : 0;

    // Schedule the job
    _jobTimers[job.id] = Timer(Duration(milliseconds: delay), () async {
      try {
        // Run the job
        final html = await _scraper.fetchHtml(url: job.url);
        final results = _scraper.extractStructuredData(
          html: html,
          selectors: job.selectors,
          attributes: job.attributes,
        );

        // Update the last run time
        job.lastRun = DateTime.now().millisecondsSinceEpoch;
        _saveJob(job);

        // Call the result callback
        onResult?.call(results);
      } catch (e) {
        // Call the error callback
        onError?.call(e is Exception ? e : Exception(e.toString()));
      } finally {
        // Schedule the next run
        _scheduleJob(job, onResult, onError);
      }
    });
  }

  /// Cancels all jobs
  void cancelAllJobs() {
    final jobs = getJobs();
    for (final job in jobs) {
      cancelJob(job.id);
    }
  }

  /// Disposes the scheduler
  void dispose() {
    cancelAllJobs();
  }
}

/// A scraping job
class ScrapingJob {
  /// The unique identifier for the job
  final String id;

  /// The URL to scrape
  final String url;

  /// The interval between runs in milliseconds
  final int interval;

  /// The CSS selectors to use
  final Map<String, String> selectors;

  /// The attributes to extract (optional)
  final Map<String, String?>? attributes;

  /// The timestamp of the last run
  int lastRun;

  /// Creates a new [ScrapingJob] with the given parameters
  ScrapingJob({
    required this.id,
    required this.url,
    required this.interval,
    required this.selectors,
    this.attributes,
    required this.lastRun,
  });

  /// Creates a [ScrapingJob] from a JSON map
  factory ScrapingJob.fromJson(Map<String, dynamic> json) {
    return ScrapingJob(
      id: json['id'] as String,
      url: json['url'] as String,
      interval: json['interval'] as int,
      selectors: Map<String, String>.from(json['selectors'] as Map),
      attributes: json['attributes'] != null
          ? Map<String, String?>.from(json['attributes'] as Map)
          : null,
      lastRun: json['lastRun'] as int,
    );
  }

  /// Converts the job to a JSON map
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'url': url,
      'interval': interval,
      'selectors': selectors,
      'attributes': attributes,
      'lastRun': lastRun,
    };
  }
}
