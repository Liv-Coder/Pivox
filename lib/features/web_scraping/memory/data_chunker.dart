import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import '../../../core/utils/logger.dart';

/// A class for chunking large datasets
class DataChunker<T> {
  /// The default chunk size in bytes
  static const int defaultChunkSize = 1024 * 1024; // 1 MB

  /// The chunk size in bytes
  final int chunkSize;

  /// Logger for logging operations
  final Logger? logger;

  /// Creates a new [DataChunker]
  DataChunker({this.chunkSize = defaultChunkSize, this.logger});

  /// Chunks a large string into smaller parts
  List<String> chunkString(String data) {
    final chunks = <String>[];

    // Calculate the number of chunks
    final numChunks = (data.length / chunkSize).ceil();

    // Split the data into chunks
    for (int i = 0; i < numChunks; i++) {
      final start = i * chunkSize;
      final end = (i + 1) * chunkSize;
      final chunk = data.substring(
        start,
        end > data.length ? data.length : end,
      );
      chunks.add(chunk);
    }

    logger?.info(
      'Chunked string of ${data.length} bytes into ${chunks.length} chunks',
    );
    return chunks;
  }

  /// Chunks a large list into smaller parts
  List<List<T>> chunkList(List<T> data) {
    final chunks = <List<T>>[];

    // Calculate the chunk size in items
    // Assume each item is roughly 100 bytes
    final itemsPerChunk = (chunkSize / 100).ceil();

    // Calculate the number of chunks
    final numChunks = (data.length / itemsPerChunk).ceil();

    // Split the data into chunks
    for (int i = 0; i < numChunks; i++) {
      final start = i * itemsPerChunk;
      final end = (i + 1) * itemsPerChunk;
      final chunk = data.sublist(start, end > data.length ? data.length : end);
      chunks.add(chunk);
    }

    logger?.info(
      'Chunked list of ${data.length} items into ${chunks.length} chunks',
    );
    return chunks;
  }

  /// Chunks a large map into smaller parts
  List<Map<K, V>> chunkMap<K, V>(Map<K, V> data) {
    final chunks = <Map<K, V>>[];

    // Convert the map to entries
    final entries = data.entries.toList();

    // Calculate the chunk size in items
    // Assume each item is roughly 100 bytes
    final itemsPerChunk = (chunkSize / 100).ceil();

    // Calculate the number of chunks
    final numChunks = (entries.length / itemsPerChunk).ceil();

    // Split the data into chunks
    for (int i = 0; i < numChunks; i++) {
      final start = i * itemsPerChunk;
      final end = (i + 1) * itemsPerChunk;
      final chunk = entries.sublist(
        start,
        end > entries.length ? entries.length : end,
      );
      final chunkMap = Map<K, V>.fromEntries(chunk);
      chunks.add(chunkMap);
    }

    logger?.info(
      'Chunked map of ${data.length} entries into ${chunks.length} chunks',
    );
    return chunks;
  }

  /// Processes a large string in chunks
  Future<R> processStringInChunks<R>({
    required String data,
    required FutureOr<R> Function(String chunk, R? previousResult) processor,
    R? initialResult,
  }) async {
    // Chunk the data
    final chunks = chunkString(data);

    // Process each chunk
    R? result = initialResult;
    for (final chunk in chunks) {
      result = await processor(chunk, result);
    }

    return result!;
  }

  /// Processes a large list in chunks
  Future<R> processListInChunks<R>({
    required List<T> data,
    required FutureOr<R> Function(List<T> chunk, R? previousResult) processor,
    R? initialResult,
  }) async {
    // Chunk the data
    final chunks = chunkList(data);

    // Process each chunk
    R? result = initialResult;
    for (final chunk in chunks) {
      result = await processor(chunk, result);
    }

    return result!;
  }

  /// Processes a large map in chunks
  Future<R> processMapInChunks<K, V, R>({
    required Map<K, V> data,
    required FutureOr<R> Function(Map<K, V> chunk, R? previousResult) processor,
    R? initialResult,
  }) async {
    // Chunk the data
    final chunks = chunkMap(data);

    // Process each chunk
    R? result = initialResult;
    for (final chunk in chunks) {
      result = await processor(chunk, result);
    }

    return result!;
  }

  /// Streams a large string in chunks
  Stream<String> streamString(String data) async* {
    // Chunk the data
    final chunks = chunkString(data);

    // Yield each chunk
    for (final chunk in chunks) {
      yield chunk;
    }
  }

  /// Streams a large list in chunks
  Stream<List<T>> streamList(List<T> data) async* {
    // Chunk the data
    final chunks = chunkList(data);

    // Yield each chunk
    for (final chunk in chunks) {
      yield chunk;
    }
  }

  /// Streams a large map in chunks
  Stream<Map<K, V>> streamMap<K, V>(Map<K, V> data) async* {
    // Chunk the data
    final chunks = chunkMap(data);

    // Yield each chunk
    for (final chunk in chunks) {
      yield chunk;
    }
  }

  /// Merges chunked strings back into a single string
  String mergeStringChunks(List<String> chunks) {
    return chunks.join();
  }

  /// Merges chunked lists back into a single list
  List<T> mergeListChunks(List<List<T>> chunks) {
    final result = <T>[];
    for (final chunk in chunks) {
      result.addAll(chunk);
    }
    return result;
  }

  /// Merges chunked maps back into a single map
  Map<K, V> mergeMapChunks<K, V>(List<Map<K, V>> chunks) {
    final result = <K, V>{};
    for (final chunk in chunks) {
      result.addAll(chunk);
    }
    return result;
  }

  /// Compresses data using GZIP
  Uint8List compressData(List<int> data) {
    return Uint8List.fromList(GZipCodec().encode(data));
  }

  /// Decompresses GZIP data
  Uint8List decompressData(List<int> compressedData) {
    return Uint8List.fromList(GZipCodec().decode(compressedData));
  }

  /// Compresses a string using GZIP
  Uint8List compressString(String data) {
    return compressData(utf8.encode(data));
  }

  /// Decompresses a GZIP string
  String decompressString(List<int> compressedData) {
    return utf8.decode(decompressData(compressedData));
  }
}
