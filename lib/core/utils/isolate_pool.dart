import 'dart:async';
import 'dart:isolate';

/// A pool of isolates for parallel processing
class IsolatePool {
  /// The list of isolates in the pool
  final List<Isolate> _isolates = [];
  
  /// The list of send ports for communicating with the isolates
  final List<SendPort> _sendPorts = [];
  
  /// The list of receive ports for receiving messages from the isolates
  final List<ReceivePort> _receivePorts = [];
  
  /// The number of isolates in the pool
  final int _poolSize;
  
  /// The current index for round-robin assignment
  int _currentIndex = 0;
  
  /// Creates a new [IsolatePool] with the given pool size
  IsolatePool(this._poolSize);
  
  /// Initializes the isolate pool
  Future<void> initialize() async {
    for (int i = 0; i < _poolSize; i++) {
      final receivePort = ReceivePort();
      final completer = Completer<SendPort>();
      
      receivePort.listen((message) {
        if (message is SendPort) {
          completer.complete(message);
        } else if (message is _IsolateResponse) {
          message.completer.complete(message.result);
        }
      });
      
      final isolate = await Isolate.spawn(
        _isolateEntryPoint,
        receivePort.sendPort,
      );
      
      _isolates.add(isolate);
      _receivePorts.add(receivePort);
      _sendPorts.add(await completer.future);
    }
  }
  
  /// Processes a list of items in parallel
  /// 
  /// [items] is the list of items to process
  /// [processFunction] is the function to apply to each item
  /// [onProgress] is an optional callback for progress updates
  Future<List<R>> process<T, R>({
    required List<T> items,
    required Future<R> Function(T) processFunction,
    void Function(int completed, int total)? onProgress,
  }) async {
    final results = List<R?>.filled(items.length, null);
    final completers = List<Completer<R>>.generate(
      items.length,
      (_) => Completer<R>(),
    );
    
    int completedCount = 0;
    
    // Process items in parallel using the isolate pool
    for (int i = 0; i < items.length; i++) {
      final item = items[i];
      final completer = completers[i];
      
      // Get the next isolate in round-robin fashion
      final isolateIndex = _currentIndex;
      _currentIndex = (_currentIndex + 1) % _poolSize;
      
      // Send the task to the isolate
      _sendPorts[isolateIndex].send(_IsolateRequest(
        id: i,
        item: item,
        functionId: processFunction.hashCode,
        responsePort: _receivePorts[isolateIndex].sendPort,
      ));
      
      // Set up the completion handler
      completer.future.then((result) {
        results[i] = result;
        completedCount++;
        
        if (onProgress != null) {
          onProgress(completedCount, items.length);
        }
      });
    }
    
    // Wait for all tasks to complete
    await Future.wait(completers.map((c) => c.future));
    
    return results.cast<R>();
  }
  
  /// Disposes the isolate pool
  void dispose() {
    for (int i = 0; i < _poolSize; i++) {
      _isolates[i].kill();
      _receivePorts[i].close();
    }
    
    _isolates.clear();
    _sendPorts.clear();
    _receivePorts.clear();
  }
  
  /// Registers a function to be available in the isolates
  void registerFunction<T, R>(
    Future<R> Function(T) function,
  ) {
    final functionId = function.hashCode;
    for (int i = 0; i < _poolSize; i++) {
      _sendPorts[i].send(_FunctionRegistration(
        functionId: functionId,
        function: function,
      ));
    }
  }
}

/// Entry point for the isolate
void _isolateEntryPoint(SendPort sendPort) {
  final receivePort = ReceivePort();
  sendPort.send(receivePort.sendPort);
  
  final functions = <int, Function>{};
  
  receivePort.listen((message) async {
    if (message is _FunctionRegistration) {
      functions[message.functionId] = message.function;
    } else if (message is _IsolateRequest) {
      final functionId = message.functionId;
      final function = functions[functionId];
      
      if (function != null) {
        try {
          final result = await Function.apply(
            function,
            [message.item],
          );
          
          message.responsePort.send(_IsolateResponse(
            id: message.id,
            result: result,
            completer: Completer<dynamic>()..complete(result),
          ));
        } catch (e) {
          message.responsePort.send(_IsolateResponse(
            id: message.id,
            result: null,
            completer: Completer<dynamic>()..completeError(e),
          ));
        }
      }
    }
  });
}

/// A request to be processed by an isolate
class _IsolateRequest<T> {
  /// The ID of the request
  final int id;
  
  /// The item to process
  final T item;
  
  /// The ID of the function to apply
  final int functionId;
  
  /// The port to send the response to
  final SendPort responsePort;
  
  /// Creates a new [_IsolateRequest]
  _IsolateRequest({
    required this.id,
    required this.item,
    required this.functionId,
    required this.responsePort,
  });
}

/// A response from an isolate
class _IsolateResponse<R> {
  /// The ID of the request
  final int id;
  
  /// The result of the processing
  final R? result;
  
  /// The completer to complete with the result
  final Completer<R> completer;
  
  /// Creates a new [_IsolateResponse]
  _IsolateResponse({
    required this.id,
    required this.result,
    required this.completer,
  });
}

/// A function registration for an isolate
class _FunctionRegistration<T, R> {
  /// The ID of the function
  final int functionId;
  
  /// The function to register
  final Future<R> Function(T) function;
  
  /// Creates a new [_FunctionRegistration]
  _FunctionRegistration({
    required this.functionId,
    required this.function,
  });
}
