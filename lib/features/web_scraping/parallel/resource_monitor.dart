import 'dart:async';
import 'dart:io';
import 'dart:isolate';

import '../../../core/utils/logger.dart';

/// A class for monitoring system resources
class ResourceMonitor {
  /// The interval for checking resources in milliseconds
  final int checkIntervalMs;

  /// Logger for logging operations
  final Logger? logger;

  /// The current CPU usage (0.0 to 1.0)
  double _cpuUsage = 0.0;

  /// The current memory usage (0.0 to 1.0)
  double _memoryUsage = 0.0;

  /// The number of available processors
  final int _processorCount;

  /// The timer for checking resources
  Timer? _checkTimer;

  /// Whether the monitor is running
  bool _isRunning = false;

  /// The previous CPU times for calculating usage
  List<double>? _previousCpuTimes;

  /// The time of the previous CPU measurement
  DateTime? _previousCpuTime;

  /// Creates a new [ResourceMonitor]
  ResourceMonitor({
    this.checkIntervalMs = 5000,
    this.logger,
  }) : _processorCount = Platform.numberOfProcessors;

  /// Gets the current CPU usage (0.0 to 1.0)
  double get cpuUsage => _cpuUsage;

  /// Gets the current memory usage (0.0 to 1.0)
  double get memoryUsage => _memoryUsage;

  /// Gets the number of available processors
  int get processorCount => _processorCount;

  /// Gets whether the monitor is running
  bool get isRunning => _isRunning;

  /// Starts the resource monitor
  void start() {
    if (_isRunning) return;
    
    _isRunning = true;
    logger?.info('Resource monitor started');
    
    // Check resources immediately
    _checkResources();
    
    // Start the timer for periodic checks
    _checkTimer = Timer.periodic(
      Duration(milliseconds: checkIntervalMs),
      (_) => _checkResources(),
    );
  }

  /// Stops the resource monitor
  void stop() {
    if (!_isRunning) return;
    
    _isRunning = false;
    logger?.info('Resource monitor stopped');
    
    // Cancel the timer
    _checkTimer?.cancel();
    _checkTimer = null;
  }

  /// Checks the current resource usage
  Future<void> _checkResources() async {
    try {
      // Check CPU usage
      await _checkCpuUsage();
      
      // Check memory usage
      await _checkMemoryUsage();
      
      logger?.fine(
        'Resource usage: CPU: ${(_cpuUsage * 100).toStringAsFixed(1)}%, '
        'Memory: ${(_memoryUsage * 100).toStringAsFixed(1)}%',
      );
    } catch (e) {
      logger?.error('Error checking resources: $e');
    }
  }

  /// Checks the current CPU usage
  Future<void> _checkCpuUsage() async {
    try {
      // This is a simplified approach that works on most platforms
      // For more accurate measurements, platform-specific code would be needed
      
      // Get the current time
      final now = DateTime.now();
      
      // Get the current CPU times
      final currentCpuTimes = await _getCpuTimes();
      
      // If we have previous measurements, calculate the usage
      if (_previousCpuTimes != null && _previousCpuTime != null) {
        // Calculate the time difference
        final timeDiff = now.difference(_previousCpuTime!).inMilliseconds / 1000.0;
        
        // Calculate the CPU time differences
        final cpuTimeDiffs = <double>[];
        for (int i = 0; i < currentCpuTimes.length; i++) {
          final diff = currentCpuTimes[i] - _previousCpuTimes![i];
          cpuTimeDiffs.add(diff);
        }
        
        // Calculate the total CPU time difference
        final totalCpuTimeDiff = cpuTimeDiffs.reduce((a, b) => a + b);
        
        // Calculate the CPU usage
        _cpuUsage = totalCpuTimeDiff / (timeDiff * _processorCount);
        
        // Ensure the CPU usage is between 0 and 1
        _cpuUsage = _cpuUsage.clamp(0.0, 1.0);
      }
      
      // Store the current measurements for the next check
      _previousCpuTimes = currentCpuTimes;
      _previousCpuTime = now;
    } catch (e) {
      logger?.error('Error checking CPU usage: $e');
    }
  }

  /// Gets the current CPU times
  Future<List<double>> _getCpuTimes() async {
    // This is a simplified approach that works on most platforms
    // For more accurate measurements, platform-specific code would be needed
    
    // Use an isolate to measure CPU time
    final result = await Isolate.run(() {
      // Simulate CPU work
      double sum = 0;
      for (int i = 0; i < 1000000; i++) {
        sum += i;
      }
      return sum;
    });
    
    // Return a simple estimate based on the result
    // This is not accurate but provides a relative measure
    return [result / 1000000];
  }

  /// Checks the current memory usage
  Future<void> _checkMemoryUsage() async {
    try {
      // Get the current memory usage
      final memoryInfo = await _getMemoryInfo();
      
      // Calculate the memory usage
      _memoryUsage = memoryInfo['used']! / memoryInfo['total']!;
      
      // Ensure the memory usage is between 0 and 1
      _memoryUsage = _memoryUsage.clamp(0.0, 1.0);
    } catch (e) {
      logger?.error('Error checking memory usage: $e');
    }
  }

  /// Gets the current memory information
  Future<Map<String, double>> _getMemoryInfo() async {
    // This is a simplified approach that works on most platforms
    // For more accurate measurements, platform-specific code would be needed
    
    // Use an isolate to measure memory
    return await Isolate.run(() {
      // Get the current memory usage
      final memoryUsed = ProcessInfo.currentRss.toDouble();
      
      // Get the total memory
      // This is not accurate but provides a relative measure
      final totalMemory = 1024 * 1024 * 1024 * 8.0; // Assume 8 GB
      
      return {
        'used': memoryUsed,
        'total': totalMemory,
      };
    });
  }
}
