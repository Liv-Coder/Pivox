import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:data_cache_x/data_cache_x.dart';
import 'package:get_it/get_it.dart';

import '../../../core/utils/logger.dart';
import '../memory/data_chunker.dart';

/// Cache options for DataCacheX
class DataCacheOptions {
  /// The maximum age of cache entries in seconds
  final Duration? maxAge;

  /// Whether to compress the data
  final bool compress;

  /// Additional metadata to store with the cache entry
  final Map<String, dynamic> additionalMetadata;

  /// The storage type to use
  final String storageType;

  /// Creates new [DataCacheOptions]
  const DataCacheOptions({
    this.maxAge,
    this.compress = true,
    this.additionalMetadata = const {},
    this.storageType = 'both',
  });

  /// Creates [DataCacheOptions] for short-lived cache entries
  factory DataCacheOptions.shortLived() {
    return const DataCacheOptions(
      maxAge: Duration(minutes: 1),
      compress: false,
      storageType: 'memory',
    );
  }

  /// Creates [DataCacheOptions] for medium-lived cache entries
  factory DataCacheOptions.mediumLived() {
    return const DataCacheOptions(
      maxAge: Duration(hours: 1),
      compress: true,
      storageType: 'both',
    );
  }

  /// Creates [DataCacheOptions] for long-lived cache entries
  factory DataCacheOptions.longLived() {
    return const DataCacheOptions(
      maxAge: Duration(days: 1),
      compress: true,
      storageType: 'both',
    );
  }

  /// Creates [DataCacheOptions] for permanent cache entries
  factory DataCacheOptions.permanent() {
    return const DataCacheOptions(
      maxAge: null, // Never expires
      compress: true,
      storageType: 'both',
    );
  }
}

/// A manager for caching using DataCacheX
class DataCacheManager {
  /// The DataCacheX instance
  final DataCacheX _dataCache;

  /// The data chunker for compressing data
  final DataChunker _dataChunker;

  /// Logger for logging operations
  final Logger? logger;

  /// The namespace for cache keys
  final String namespace;

  /// Creates a new [DataCacheManager]
  DataCacheManager({
    required this.namespace,
    DataCacheX? dataCache,
    DataChunker? dataChunker,
    this.logger,
  }) : _dataCache = dataCache ?? GetIt.instance<DataCacheX>(),
       _dataChunker = dataChunker ?? DataChunker();

  /// Initializes the cache manager
  Future<void> initialize() async {
    try {
      // DataCacheX is already initialized by getIt
      logger?.info('DataCacheManager initialized with namespace: $namespace');
    } catch (e) {
      logger?.error('Error initializing DataCacheManager: $e');
      rethrow;
    }
  }

  /// Gets a cache entry
  Future<T?> get<T>(String key, {String? storageType}) async {
    final fullKey = _getFullKey(key);

    try {
      // Try to get the data from cache
      final cachedData = await _dataCache.get<Uint8List>(fullKey);

      if (cachedData != null) {
        // Decompress the data if needed
        final decompressedData =
            _isCompressed(cachedData)
                ? _dataChunker.decompressData(cachedData)
                : cachedData;

        // Deserialize the data
        final data = _deserializeData<T>(decompressedData);

        logger?.fine('Cache hit: $key');
        return data;
      }

      logger?.fine('Cache miss: $key');
      return null;
    } catch (e) {
      logger?.error('Error getting cache entry $key: $e');
      return null;
    }
  }

  /// Puts a cache entry
  Future<void> put<T>(
    String key,
    T data, {
    DataCacheOptions options = const DataCacheOptions(),
  }) async {
    final fullKey = _getFullKey(key);

    try {
      // Serialize the data
      final bytes = _serializeData(data);

      // Compress the data if needed
      final finalBytes =
          options.compress
              ? _dataChunker.compressData(bytes)
              : Uint8List.fromList(bytes);

      // Store the data in cache
      await _dataCache.put<Uint8List>(
        fullKey,
        finalBytes,
        policy: CachePolicy(expiry: options.maxAge),
      );

      logger?.info('Cached entry $key (${_formatSize(finalBytes.length)})');
    } catch (e) {
      logger?.error('Error caching entry $key: $e');
      rethrow;
    }
  }

  /// Removes a cache entry
  Future<void> remove(String key) async {
    final fullKey = _getFullKey(key);

    try {
      await _dataCache.delete(fullKey);
      logger?.info('Removed cache entry $key');
    } catch (e) {
      logger?.error('Error removing cache entry $key: $e');
      rethrow;
    }
  }

  /// Clears all cache entries for this namespace
  Future<void> clear() async {
    try {
      // Clear all cache entries
      await _dataCache.clear();

      logger?.info('Cleared all cache entries for namespace $namespace');
    } catch (e) {
      logger?.error('Error clearing cache: $e');
      rethrow;
    }
  }

  /// Gets the full key with namespace
  String _getFullKey(String key) {
    return '$namespace:$key';
  }

  /// Serializes data to bytes
  List<int> _serializeData(dynamic data) {
    if (data == null) {
      return [];
    } else if (data is String) {
      return utf8.encode(data);
    } else if (data is List<int>) {
      return data;
    } else if (data is Uint8List) {
      return data;
    } else {
      // Fallback: serialize to JSON
      return utf8.encode(jsonEncode(data));
    }
  }

  /// Deserializes bytes to data
  T _deserializeData<T>(List<int> bytes) {
    if (identical(T, String)) {
      return utf8.decode(bytes) as T;
    } else if (identical(T, List<int>) || identical(T, Uint8List)) {
      return Uint8List.fromList(bytes) as T;
    } else {
      // Fallback: deserialize from JSON
      return jsonDecode(utf8.decode(bytes)) as T;
    }
  }

  /// Checks if bytes are compressed
  bool _isCompressed(List<int> bytes) {
    // Check for GZIP magic number (0x1F, 0x8B)
    return bytes.length >= 2 && bytes[0] == 0x1F && bytes[1] == 0x8B;
  }

  /// Formats a size in bytes to a human-readable string
  String _formatSize(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    } else {
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
    }
  }
}
