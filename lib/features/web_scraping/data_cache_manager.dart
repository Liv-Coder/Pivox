import 'dart:convert';
import 'dart:io';
import 'package:data_cache_x/data_cache_x.dart';
import 'package:data_cache_x/service_locator.dart';
import 'package:path_provider/path_provider.dart';

/// A manager for storing scraped data using data_cache_x
class DataCacheManager {
  /// The data cache instance
  final DataCacheX _cache;

  /// Key prefix for storing data
  static const String _dataKeyPrefix = 'scraped_data_';

  /// Key prefix for storing structured data
  static const String _structuredDataKeyPrefix = 'structured_data_';

  /// Key for storing the list of structured data IDs
  static const String _structuredDataIdsKey = 'structured_data_ids';

  /// Key for storing the list of structured data sources
  static const String _structuredDataSourcesKey = 'structured_data_sources';

  /// Creates a new [DataCacheManager] with the given cache
  DataCacheManager(this._cache);

  /// Factory constructor to create a [DataCacheManager]
  static Future<DataCacheManager> create({bool useDatabase = true}) async {
    // Initialize the data cache
    await setupDataCacheX(adapterType: CacheAdapterType.memory);
    final cache = getIt<DataCacheX>();
    return DataCacheManager(cache);
  }

  /// Stores data in the cache
  ///
  /// [id] is the unique identifier for the data
  /// [data] is the data to store
  Future<void> storeData(String id, dynamic data) async {
    await _cache.put(_dataKeyPrefix + id, data);
  }

  /// Gets data from the cache
  ///
  /// [id] is the unique identifier for the data
  dynamic getData(String id) {
    return _cache.get(_dataKeyPrefix + id);
  }

  /// Removes data from the cache
  ///
  /// [id] is the unique identifier for the data
  Future<void> removeData(String id) async {
    await _cache.delete(_dataKeyPrefix + id);
  }

  /// Stores structured data in the cache
  ///
  /// [id] is the unique identifier for the data
  /// [source] is the source of the data (e.g., the URL)
  /// [data] is the data to store
  Future<void> storeStructuredData(
    String id,
    String source,
    dynamic data,
  ) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;

    // Store the data
    await _cache.put(_structuredDataKeyPrefix + id, {
      'id': id,
      'source': source,
      'timestamp': timestamp,
      'data': data,
    });

    // Update the list of IDs
    final ids = _cache.get(_structuredDataIdsKey) as List<dynamic>? ?? [];
    if (!ids.contains(id)) {
      ids.add(id);
      await _cache.put(_structuredDataIdsKey, ids);
    }

    // Update the list of sources
    final sources =
        _cache.get(_structuredDataSourcesKey) as List<dynamic>? ?? [];
    if (!sources.contains(source)) {
      sources.add(source);
      await _cache.put(_structuredDataSourcesKey, sources);
    }
  }

  /// Gets structured data from the cache
  ///
  /// [id] is the unique identifier for the data
  Future<dynamic> getStructuredData(String id) async {
    final data =
        _cache.get(_structuredDataKeyPrefix + id) as Map<String, dynamic>?;
    if (data == null) return null;

    return data['data'];
  }

  /// Gets all structured data from the cache
  Future<List<Map<String, dynamic>>> getAllStructuredData() async {
    final ids = _cache.get(_structuredDataIdsKey) as List<dynamic>? ?? [];
    final result = <Map<String, dynamic>>[];

    for (final id in ids) {
      final data =
          _cache.get(_structuredDataKeyPrefix + id) as Map<String, dynamic>?;
      if (data != null) {
        result.add({
          'id': data['id'],
          'source': data['source'],
          'timestamp': data['timestamp'],
          'data': data['data'],
        });
      }
    }

    return result;
  }

  /// Gets structured data by source
  ///
  /// [source] is the source of the data (e.g., the URL)
  Future<List<Map<String, dynamic>>> getStructuredDataBySource(
    String source,
  ) async {
    final ids = _cache.get(_structuredDataIdsKey) as List<dynamic>? ?? [];
    final result = <Map<String, dynamic>>[];

    for (final id in ids) {
      final data =
          _cache.get(_structuredDataKeyPrefix + id) as Map<String, dynamic>?;
      if (data != null && data['source'] == source) {
        result.add({
          'id': data['id'],
          'source': data['source'],
          'timestamp': data['timestamp'],
          'data': data['data'],
        });
      }
    }

    return result;
  }

  /// Removes structured data from the cache
  ///
  /// [id] is the unique identifier for the data
  Future<void> removeStructuredData(String id) async {
    // Remove the data
    await _cache.delete(_structuredDataKeyPrefix + id);

    // Update the list of IDs
    final ids = _cache.get(_structuredDataIdsKey) as List<dynamic>? ?? [];
    if (ids.contains(id)) {
      ids.remove(id);
      await _cache.put(_structuredDataIdsKey, ids);
    }

    // We don't update the list of sources because other data might still use them
  }

  /// Exports data to a JSON file
  ///
  /// [filename] is the name of the file to export to
  Future<String> exportToJson(String filename) async {
    final data = await getAllStructuredData();
    final jsonData = jsonEncode(data);

    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/$filename');
      await file.writeAsString(jsonData);
      return file.path;
    } catch (e) {
      // If we can't write to a file, return the JSON data as a string
      return jsonData;
    }
  }

  /// Imports data from a JSON file or string
  ///
  /// [source] is the path to the file or the JSON string to import from
  Future<void> importFromJson(String source) async {
    String jsonData;

    try {
      // Try to read from a file
      final file = File(source);
      if (await file.exists()) {
        jsonData = await file.readAsString();
      } else {
        // If it's not a file, assume it's a JSON string
        jsonData = source;
      }
    } catch (_) {
      // If we can't read from a file, assume it's a JSON string
      jsonData = source;
    }

    try {
      final data = jsonDecode(jsonData) as List<dynamic>;

      for (final item in data) {
        final map = item as Map<String, dynamic>;
        await storeStructuredData(
          map['id'] as String,
          map['source'] as String,
          map['data'],
        );
      }
    } catch (e) {
      throw FormatException('Invalid JSON data: $e');
    }
  }

  /// Clears all data from the cache
  Future<void> clear() async {
    await _cache.clear();
  }
}
