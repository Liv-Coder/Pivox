import 'dart:async';
import 'dart:isolate';

/// A utility class for processing tasks in parallel using Isolates
class ParallelProcessor<T, R> {
  /// The maximum number of isolates to use
  final int maxConcurrency;
  
  /// Creates a new [ParallelProcessor] with the given [maxConcurrency]
  ParallelProcessor({this.maxConcurrency = 5});
  
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
    
    // Use a single isolate for small lists
    if (items.length <= 2) {
      final results = <R>[];
      for (var i = 0; i < items.length; i++) {
        final result = await processFunction(items[i]);
        results.add(result);
        onProgress?.call(i + 1, items.length);
      }
      return results;
    }
    
    // Calculate actual concurrency based on list size
    final actualConcurrency = items.length < maxConcurrency 
        ? items.length 
        : maxConcurrency;
    
    // Create a list to store the results
    final results = List<R?>.filled(items.length, null);
    
    // Create a completer to signal when all tasks are done
    final completer = Completer<void>();
    
    // Track the number of completed tasks
    var completedTasks = 0;
    
    // Create a pool of isolates
    final isolates = <Isolate>[];
    final receivePortsForIsolates = <ReceivePort>[];
    
    // Function to process the next item
    void processNextItem(int isolateIndex, int itemIndex) {
      if (itemIndex >= items.length) {
        // No more items to process
        return;
      }
      
      // Get the item to process
      final item = items[itemIndex];
      
      // Create a receive port for this task
      final receivePort = ReceivePort();
      
      // Create the isolate
      Isolate.spawn<_IsolateMessage<T, R>>(
        _isolateEntryPoint,
        _IsolateMessage<T, R>(
          item: item,
          processFunction: processFunction,
          sendPort: receivePort.sendPort,
        ),
      ).then((isolate) {
        isolates.add(isolate);
        
        // Listen for the result
        receivePort.listen((message) {
          if (message is R) {
            // Store the result
            results[itemIndex] = message;
            
            // Update progress
            completedTasks++;
            onProgress?.call(completedTasks, items.length);
            
            // Close the receive port
            receivePort.close();
            
            // Kill the isolate
            isolate.kill(priority: Isolate.immediate);
            
            // Process the next item
            processNextItem(isolateIndex, itemIndex + actualConcurrency);
            
            // Check if all tasks are done
            if (completedTasks == items.length) {
              completer.complete();
            }
          }
        });
      });
    }
    
    // Start processing items
    for (var i = 0; i < actualConcurrency; i++) {
      processNextItem(i, i);
    }
    
    // Wait for all tasks to complete
    await completer.future;
    
    // Clean up
    for (final receivePort in receivePortsForIsolates) {
      receivePort.close();
    }
    
    // Return the results (cast to non-nullable since we filled all positions)
    return results.cast<R>();
  }
}

/// Message sent to the isolate
class _IsolateMessage<T, R> {
  /// The item to process
  final T item;
  
  /// The function to apply to the item
  final Future<R> Function(T) processFunction;
  
  /// The send port to send the result back
  final SendPort sendPort;
  
  /// Creates a new [_IsolateMessage] with the given parameters
  _IsolateMessage({
    required this.item,
    required this.processFunction,
    required this.sendPort,
  });
}

/// Entry point for the isolate
Future<void> _isolateEntryPoint<T, R>(_IsolateMessage<T, R> message) async {
  try {
    // Process the item
    final result = await message.processFunction(message.item);
    
    // Send the result back
    message.sendPort.send(result);
  } catch (e) {
    // Send the error back
    message.sendPort.send(e);
  }
}
