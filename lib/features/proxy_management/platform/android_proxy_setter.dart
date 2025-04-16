import 'dart:io';

import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/services.dart';
import '../../proxy_management/domain/entities/proxy.dart';

/// A utility class for setting system proxy on Android
class AndroidProxySetter {
  /// The method channel for native communication
  static const MethodChannel _channel = MethodChannel('com.pivox/proxy_setter');

  /// Whether the proxy setter is supported on this platform
  static bool get isSupported => Platform.isAndroid;

  /// Sets the system proxy on Android
  ///
  /// This requires root access or ADB permissions
  /// Returns true if successful, false otherwise
  static Future<bool> setSystemProxy(Proxy proxy) async {
    if (!isSupported) {
      return false;
    }

    try {
      final result = await _channel.invokeMethod('setSystemProxy', {
        'host': proxy.ip,
        'port': proxy.port.toString(),
      });
      return result == true;
    } catch (e) {
      // Use a proper logging mechanism in production
      if (kDebugMode) {
        print('Error setting system proxy: $e');
      }
      return false;
    }
  }

  /// Clears the system proxy on Android
  ///
  /// This requires root access or ADB permissions
  /// Returns true if successful, false otherwise
  static Future<bool> clearSystemProxy() async {
    if (!isSupported) {
      return false;
    }

    try {
      final result = await _channel.invokeMethod('clearSystemProxy');
      return result == true;
    } catch (e) {
      if (kDebugMode) {
        print('Error clearing system proxy: $e');
      }
      return false;
    }
  }

  /// Checks if the app has permission to set system proxy
  ///
  /// Returns true if the app has permission, false otherwise
  static Future<bool> hasProxyPermission() async {
    if (!isSupported) {
      return false;
    }

    try {
      final result = await _channel.invokeMethod('hasProxyPermission');
      return result == true;
    } catch (e) {
      if (kDebugMode) {
        print('Error checking proxy permission: $e');
      }
      return false;
    }
  }

  /// Requests permission to set system proxy
  ///
  /// This will show a dialog to the user asking for permission
  /// Returns true if permission was granted, false otherwise
  static Future<bool> requestProxyPermission() async {
    if (!isSupported) {
      return false;
    }

    try {
      final result = await _channel.invokeMethod('requestProxyPermission');
      return result == true;
    } catch (e) {
      if (kDebugMode) {
        print('Error requesting proxy permission: $e');
      }
      return false;
    }
  }
}
