import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

import '../../../core/utils/logger.dart';
import '../memory/data_chunker.dart';

/// Cache entry metadata
class CacheEntryMetadata {
  /// The key of the cache entry
  final String key;

  /// The time when the entry was created
  final DateTime createdAt;

  /// The time when the entry was last accessed
  DateTime lastAccessedAt;

  /// The time when the entry expires
  final DateTime? expiresAt;

  /// The size of the entry in bytes
  final int size;

  /// The content type of the entry
  final String? contentType;

  /// Additional metadata
  final Map<String, dynamic> additionalMetadata;

  /// Creates a new [CacheEntryMetadata]
  CacheEntryMetadata({
    required this.key,
    required this.createdAt,
    required this.lastAccessedAt,
    this.expiresAt,
    required this.size,
    this.contentType,
    this.additionalMetadata = const {},
  });

  /// Creates a [CacheEntryMetadata] from JSON
  factory CacheEntryMetadata.fromJson(Map<String, dynamic> json) {
    return CacheEntryMetadata(
      key: json['key'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      lastAccessedAt: DateTime.parse(json['lastAccessedAt'] as String),
      expiresAt:
          json['expiresAt'] != null
              ? DateTime.parse(json['expiresAt'] as String)
              : null,
      size: json['size'] as int,
      contentType: json['contentType'] as String?,
      additionalMetadata:
          json['additionalMetadata'] as Map<String, dynamic>? ?? {},
    );
  }

  /// Converts the metadata to JSON
  Map<String, dynamic> toJson() {
    return {
      'key': key,
      'createdAt': createdAt.toIso8601String(),
      'lastAccessedAt': lastAccessedAt.toIso8601String(),
      'expiresAt': expiresAt?.toIso8601String(),
      'size': size,
      'contentType': contentType,
      'additionalMetadata': additionalMetadata,
    };
  }

  /// Updates the last accessed time
  void updateLastAccessedAt() {
    lastAccessedAt = DateTime.now();
  }

  /// Checks if the entry is expired
  bool get isExpired {
    if (expiresAt == null) return false;
    return DateTime.now().isAfter(expiresAt!);
  }
}

/// Cache entry
class CacheEntry {
  /// The metadata of the cache entry
  final CacheEntryMetadata metadata;

  /// The data of the cache entry
  final dynamic data;

  /// Creates a new [CacheEntry]
  CacheEntry({required this.metadata, required this.data});
}

/// Cache level
enum CacheLevel {
  /// Memory cache (fastest, but limited size)
  memory,

  /// Disk cache (slower, but larger size)
  disk,

  /// Remote cache (slowest, but largest size)
  remote,
}

/// Cache options
class CacheOptions {
  /// The maximum age of cache entries in seconds
  final int? maxAgeSeconds;

  /// The cache levels to use
  final List<CacheLevel> levels;

  /// Whether to compress the data
  final bool compress;

  /// Additional metadata to store with the cache entry
  final Map<String, dynamic> additionalMetadata;

  /// Creates new [CacheOptions]
  const CacheOptions({
    this.maxAgeSeconds,
    this.levels = const [CacheLevel.memory, CacheLevel.disk],
    this.compress = true,
    this.additionalMetadata = const {},
  });

  /// Creates [CacheOptions] for short-lived cache entries
  factory CacheOptions.shortLived() {
    return const CacheOptions(
      maxAgeSeconds: 60, // 1 minute
      levels: [CacheLevel.memory],
      compress: false,
    );
  }

  /// Creates [CacheOptions] for medium-lived cache entries
  factory CacheOptions.mediumLived() {
    return const CacheOptions(
      maxAgeSeconds: 3600, // 1 hour
      levels: [CacheLevel.memory, CacheLevel.disk],
      compress: true,
    );
  }

  /// Creates [CacheOptions] for long-lived cache entries
  factory CacheOptions.longLived() {
    return const CacheOptions(
      maxAgeSeconds: 86400, // 1 day
      levels: [CacheLevel.memory, CacheLevel.disk],
      compress: true,
    );
  }

  /// Creates [CacheOptions] for permanent cache entries
  factory CacheOptions.permanent() {
    return const CacheOptions(
      maxAgeSeconds: null, // Never expires
      levels: [CacheLevel.memory, CacheLevel.disk],
      compress: true,
    );
  }
}

/// A manager for multi-level caching
class CacheManager {
  /// The maximum size of the memory cache in bytes
  final int maxMemoryCacheSize;

  /// The maximum size of the disk cache in bytes
  final int maxDiskCacheSize;

  /// The base directory for the disk cache
  final String? diskCacheDirectory;

  /// The data chunker for compressing data
  final DataChunker _dataChunker;

  /// Logger for logging operations
  final Logger? logger;

  /// The memory cache
  final Map<String, CacheEntry> _memoryCache = {};

  /// The total size of the memory cache in bytes
  int _memoryCacheSize = 0;

  /// The disk cache directory
  late final Directory _diskCacheDir;

  /// Whether the cache manager is initialized
  bool _isInitialized = false;

  /// Creates a new [CacheManager]
  CacheManager({
    this.maxMemoryCacheSize = 50 * 1024 * 1024, // 50 MB
    this.maxDiskCacheSize = 500 * 1024 * 1024, // 500 MB
    this.diskCacheDirectory,
    DataChunker? dataChunker,
    this.logger,
  }) : _dataChunker = dataChunker ?? DataChunker();

  /// Initializes the cache manager
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Initialize the disk cache directory
      if (diskCacheDirectory != null) {
        _diskCacheDir = Directory(diskCacheDirectory!);
      } else {
        final appDir = await getApplicationDocumentsDirectory();
        _diskCacheDir = Directory(path.join(appDir.path, 'cache'));
      }

      // Create the directory if it doesn't exist
      if (!await _diskCacheDir.exists()) {
        await _diskCacheDir.create(recursive: true);
      }

      // Clean up expired cache entries
      await _cleanupExpiredEntries();

      _isInitialized = true;
      logger?.info('Cache manager initialized');
    } catch (e) {
      logger?.error('Error initializing cache manager: $e');
      rethrow;
    }
  }

  /// Gets a cache entry
  Future<T?> get<T>(String key, {List<CacheLevel>? levels}) async {
    await _ensureInitialized();

    // Normalize the levels
    levels ??= [CacheLevel.memory, CacheLevel.disk];

    // Try to get the entry from each level
    for (final level in levels) {
      final entry = await _getFromLevel<T>(key, level);
      if (entry != null) {
        // Update the last accessed time
        entry.metadata.updateLastAccessedAt();

        // If the entry was found in a lower level, store it in higher levels
        if (level != CacheLevel.memory && levels.contains(CacheLevel.memory)) {
          await _storeInLevel(
            key,
            entry.data,
            entry.metadata,
            CacheLevel.memory,
          );
        }

        return entry.data as T;
      }
    }

    return null;
  }

  /// Puts a cache entry
  Future<void> put<T>(
    String key,
    T data, {
    CacheOptions options = const CacheOptions(),
  }) async {
    await _ensureInitialized();

    try {
      // Calculate the size of the data
      final size = _calculateDataSize(data);

      // Create the metadata
      final metadata = CacheEntryMetadata(
        key: key,
        createdAt: DateTime.now(),
        lastAccessedAt: DateTime.now(),
        expiresAt:
            options.maxAgeSeconds != null
                ? DateTime.now().add(Duration(seconds: options.maxAgeSeconds!))
                : null,
        size: size,
        contentType: T.toString(),
        additionalMetadata: options.additionalMetadata,
      );

      // Store the entry in each level
      for (final level in options.levels) {
        await _storeInLevel(
          key,
          data,
          metadata,
          level,
          compress: options.compress,
        );
      }

      logger?.info('Cached entry $key (${_formatSize(size)})');
    } catch (e) {
      logger?.error('Error caching entry $key: $e');
      rethrow;
    }
  }

  /// Removes a cache entry
  Future<void> remove(String key) async {
    await _ensureInitialized();

    try {
      // Remove from memory cache
      final memoryEntry = _memoryCache[key];
      if (memoryEntry != null) {
        _memoryCacheSize -= memoryEntry.metadata.size;
        _memoryCache.remove(key);
      }

      // Remove from disk cache
      final diskFile = _getDiskCacheFile(key);
      final diskMetaFile = _getDiskCacheMetaFile(key);

      if (await diskFile.exists()) {
        await diskFile.delete();
      }

      if (await diskMetaFile.exists()) {
        await diskMetaFile.delete();
      }

      logger?.info('Removed cache entry $key');
    } catch (e) {
      logger?.error('Error removing cache entry $key: $e');
      rethrow;
    }
  }

  /// Clears the cache
  Future<void> clear() async {
    await _ensureInitialized();

    try {
      // Clear memory cache
      _memoryCache.clear();
      _memoryCacheSize = 0;

      // Clear disk cache
      if (await _diskCacheDir.exists()) {
        final files = await _diskCacheDir.list().toList();
        for (final file in files) {
          await file.delete();
        }
      }

      logger?.info('Cache cleared');
    } catch (e) {
      logger?.error('Error clearing cache: $e');
      rethrow;
    }
  }

  /// Gets the size of the cache
  Future<Map<CacheLevel, int>> getSize() async {
    await _ensureInitialized();

    final sizes = <CacheLevel, int>{};

    // Get memory cache size
    sizes[CacheLevel.memory] = _memoryCacheSize;

    // Get disk cache size
    int diskSize = 0;
    if (await _diskCacheDir.exists()) {
      final files = await _diskCacheDir.list().toList();
      for (final file in files) {
        if (file is File) {
          final stat = await file.stat();
          diskSize += stat.size;
        }
      }
    }
    sizes[CacheLevel.disk] = diskSize;

    return sizes;
  }

  /// Gets a cache entry from a specific level
  Future<CacheEntry?> _getFromLevel<T>(String key, CacheLevel level) async {
    switch (level) {
      case CacheLevel.memory:
        return _getFromMemory<T>(key);
      case CacheLevel.disk:
        return _getFromDisk<T>(key);
      case CacheLevel.remote:
        return _getFromRemote<T>(key);
    }
  }

  /// Gets a cache entry from memory
  CacheEntry? _getFromMemory<T>(String key) {
    final entry = _memoryCache[key];
    if (entry != null) {
      // Check if the entry is expired
      if (entry.metadata.isExpired) {
        _memoryCache.remove(key);
        _memoryCacheSize -= entry.metadata.size;
        return null;
      }

      logger?.fine('Cache hit (memory): $key');
      return entry;
    }

    return null;
  }

  /// Gets a cache entry from disk
  Future<CacheEntry?> _getFromDisk<T>(String key) async {
    final file = _getDiskCacheFile(key);
    final metaFile = _getDiskCacheMetaFile(key);

    if (await file.exists() && await metaFile.exists()) {
      try {
        // Read the metadata
        final metaJson = jsonDecode(await metaFile.readAsString());
        final metadata = CacheEntryMetadata.fromJson(metaJson);

        // Check if the entry is expired
        if (metadata.isExpired) {
          await file.delete();
          await metaFile.delete();
          return null;
        }

        // Read the data
        final bytes = await file.readAsBytes();

        // Decompress the data if needed
        final decompressedBytes =
            _isCompressed(bytes)
                ? _dataChunker.decompressData(bytes)
                : Uint8List.fromList(bytes);

        // Deserialize the data
        final data = _deserializeData<T>(decompressedBytes);

        logger?.fine('Cache hit (disk): $key');
        return CacheEntry(metadata: metadata, data: data);
      } catch (e) {
        logger?.error('Error reading disk cache entry $key: $e');

        // Delete the corrupted files
        await file.delete();
        await metaFile.delete();
      }
    }

    return null;
  }

  /// Gets a cache entry from a remote source
  Future<CacheEntry?> _getFromRemote<T>(String key) async {
    // Remote cache is not implemented yet
    return null;
  }

  /// Stores a cache entry in a specific level
  Future<void> _storeInLevel<T>(
    String key,
    T data,
    CacheEntryMetadata metadata,
    CacheLevel level, {
    bool compress = true,
  }) async {
    switch (level) {
      case CacheLevel.memory:
        await _storeInMemory(key, data, metadata);
        break;
      case CacheLevel.disk:
        await _storeInDisk(key, data, metadata, compress: compress);
        break;
      case CacheLevel.remote:
        await _storeInRemote(key, data, metadata, compress: compress);
        break;
    }
  }

  /// Stores a cache entry in memory
  Future<void> _storeInMemory<T>(
    String key,
    T data,
    CacheEntryMetadata metadata,
  ) async {
    // Check if we need to make room in the cache
    if (_memoryCacheSize + metadata.size > maxMemoryCacheSize) {
      await _evictFromMemory(metadata.size);
    }

    // Store the entry
    final entry = CacheEntry(metadata: metadata, data: data);
    _memoryCache[key] = entry;
    _memoryCacheSize += metadata.size;
  }

  /// Stores a cache entry on disk
  Future<void> _storeInDisk<T>(
    String key,
    T data,
    CacheEntryMetadata metadata, {
    bool compress = true,
  }) async {
    // Check if we need to make room in the cache
    final diskSize = (await getSize())[CacheLevel.disk] ?? 0;
    if (diskSize + metadata.size > maxDiskCacheSize) {
      await _evictFromDisk(metadata.size);
    }

    // Serialize the data
    final bytes = _serializeData(data);

    // Compress the data if needed
    final finalBytes =
        compress ? _dataChunker.compressData(bytes) : Uint8List.fromList(bytes);

    // Write the data to disk
    final file = _getDiskCacheFile(key);
    final metaFile = _getDiskCacheMetaFile(key);

    await file.writeAsBytes(finalBytes);
    await metaFile.writeAsString(jsonEncode(metadata.toJson()));
  }

  /// Stores a cache entry in a remote source
  Future<void> _storeInRemote<T>(
    String key,
    T data,
    CacheEntryMetadata metadata, {
    bool compress = true,
  }) async {
    // Remote cache is not implemented yet
  }

  /// Evicts entries from memory to make room for a new entry
  Future<void> _evictFromMemory(int sizeNeeded) async {
    // Sort entries by last accessed time (oldest first)
    final entries =
        _memoryCache.entries.toList()..sort(
          (a, b) => a.value.metadata.lastAccessedAt.compareTo(
            b.value.metadata.lastAccessedAt,
          ),
        );

    // Remove entries until we have enough space
    int spaceFreed = 0;
    for (final entry in entries) {
      if (_memoryCacheSize - spaceFreed <= maxMemoryCacheSize - sizeNeeded) {
        break;
      }

      _memoryCache.remove(entry.key);
      spaceFreed += entry.value.metadata.size;
    }

    _memoryCacheSize -= spaceFreed;
    logger?.info(
      'Evicted ${entries.length} entries from memory cache (${_formatSize(spaceFreed)})',
    );
  }

  /// Evicts entries from disk to make room for a new entry
  Future<void> _evictFromDisk(int sizeNeeded) async {
    // Get all metadata files
    final metaFiles =
        await _diskCacheDir
            .list()
            .where((entity) => entity is File && entity.path.endsWith('.meta'))
            .cast<File>()
            .toList();

    // Read metadata and sort by last accessed time (oldest first)
    final metadataList = <CacheEntryMetadata>[];
    for (final metaFile in metaFiles) {
      try {
        final metaJson = jsonDecode(await metaFile.readAsString());
        final metadata = CacheEntryMetadata.fromJson(metaJson);
        metadataList.add(metadata);
      } catch (e) {
        logger?.error('Error reading metadata file ${metaFile.path}: $e');
        await metaFile.delete();
      }
    }

    metadataList.sort((a, b) => a.lastAccessedAt.compareTo(b.lastAccessedAt));

    // Calculate current disk cache size
    final diskSize = (await getSize())[CacheLevel.disk] ?? 0;

    // Remove entries until we have enough space
    int spaceFreed = 0;
    int entriesRemoved = 0;
    for (final metadata in metadataList) {
      if (diskSize - spaceFreed <= maxDiskCacheSize - sizeNeeded) {
        break;
      }

      final file = _getDiskCacheFile(metadata.key);
      final metaFile = _getDiskCacheMetaFile(metadata.key);

      if (await file.exists()) {
        await file.delete();
      }

      if (await metaFile.exists()) {
        await metaFile.delete();
      }

      spaceFreed += metadata.size;
      entriesRemoved++;
    }

    logger?.info(
      'Evicted $entriesRemoved entries from disk cache (${_formatSize(spaceFreed)})',
    );
  }

  /// Cleans up expired cache entries
  Future<void> _cleanupExpiredEntries() async {
    // Clean up memory cache
    final expiredMemoryKeys = <String>[];
    for (final entry in _memoryCache.entries) {
      if (entry.value.metadata.isExpired) {
        expiredMemoryKeys.add(entry.key);
        _memoryCacheSize -= entry.value.metadata.size;
      }
    }

    for (final key in expiredMemoryKeys) {
      _memoryCache.remove(key);
    }

    // Clean up disk cache
    final metaFiles =
        await _diskCacheDir
            .list()
            .where((entity) => entity is File && entity.path.endsWith('.meta'))
            .cast<File>()
            .toList();

    int expiredDiskEntries = 0;
    for (final metaFile in metaFiles) {
      try {
        final metaJson = jsonDecode(await metaFile.readAsString());
        final metadata = CacheEntryMetadata.fromJson(metaJson);

        if (metadata.isExpired) {
          final file = _getDiskCacheFile(metadata.key);

          if (await file.exists()) {
            await file.delete();
          }

          await metaFile.delete();
          expiredDiskEntries++;
        }
      } catch (e) {
        logger?.error('Error reading metadata file ${metaFile.path}: $e');
        await metaFile.delete();
      }
    }

    logger?.info(
      'Cleaned up ${expiredMemoryKeys.length} expired memory entries and $expiredDiskEntries expired disk entries',
    );
  }

  /// Gets the disk cache file for a key
  File _getDiskCacheFile(String key) {
    final hashedKey = _hashKey(key);
    return File(path.join(_diskCacheDir.path, '$hashedKey.cache'));
  }

  /// Gets the disk cache metadata file for a key
  File _getDiskCacheMetaFile(String key) {
    final hashedKey = _hashKey(key);
    return File(path.join(_diskCacheDir.path, '$hashedKey.meta'));
  }

  /// Hashes a key
  String _hashKey(String key) {
    final bytes = utf8.encode(key);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Calculates the size of data in bytes
  int _calculateDataSize(dynamic data) {
    if (data == null) {
      return 0;
    } else if (data is String) {
      return utf8.encode(data).length;
    } else if (data is List<int>) {
      return data.length;
    } else if (data is Map) {
      return utf8.encode(jsonEncode(data)).length;
    } else if (data is List) {
      return utf8.encode(jsonEncode(data)).length;
    } else {
      // Fallback: serialize to JSON and measure the size
      return utf8.encode(jsonEncode(data)).length;
    }
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

  /// Ensures the cache manager is initialized
  Future<void> _ensureInitialized() async {
    if (!_isInitialized) {
      await initialize();
    }
  }
}
