import 'dart:async';

import 'isolate_pool.dart';

/// A utility class for processing tasks in parallel using Isolates
class ParallelProcessor<T, R> {
  /// The maximum number of isolates to use
  final int maxConcurrency;

  /// The isolate pool for parallel processing
  IsolatePool? _isolatePool;

  /// Creates a new [ParallelProcessor] with the given [maxConcurrency]
  ParallelProcessor({this.maxConcurrency = 5});

  /// Initializes the parallel processor
  Future<void> initialize() async {
    _isolatePool = IsolatePool(maxConcurrency);
    await _isolatePool!.initialize();
  }

  /// Processes a list of items in parallel
  ///
  /// [items] is the list of items to process
  /// [processFunction] is the function to apply to each item
  /// [onProgress] is an optional callback for progress updates
  Future<List<R>> process({
    required List<T> items,
    required Future<R> Function(T item) processFunction,
    void Function(int completed, int total)? onProgress,
  }) async {
    if (items.isEmpty) return [];

    // Use a single thread for small lists
    if (items.length <= 2) {
      final results = <R>[];
      for (var i = 0; i < items.length; i++) {
        final result = await processFunction(items[i]);
        results.add(result);
        onProgress?.call(i + 1, items.length);
      }
      return results;
    }

    // Initialize the isolate pool if needed
    if (_isolatePool == null) {
      await initialize();
    }

    // Register the process function
    _isolatePool!.registerFunction(processFunction);

    // Process the items using the isolate pool
    return _isolatePool!.process<T, R>(
      items: items,
      processFunction: processFunction,
      onProgress: onProgress,
    );
  }

  /// Disposes the parallel processor
  void dispose() {
    _isolatePool?.dispose();
    _isolatePool = null;
  }
}
