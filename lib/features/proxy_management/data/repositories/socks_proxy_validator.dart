import 'dart:async';
import 'dart:io';

import '../../domain/entities/proxy.dart';
import '../../domain/entities/proxy_protocol.dart';
import '../../domain/entities/proxy_validation_options.dart';

/// Validator for SOCKS proxies
class SocksProxyValidator {
  /// Validates a SOCKS proxy
  static Future<bool> validate(
    Proxy proxy, {
    ProxyValidationOptions options = const ProxyValidationOptions(),
  }) async {
    if (!proxy.protocol.isSocks) {
      throw ArgumentError('Proxy is not a SOCKS proxy');
    }

    final url = options.testUrl ?? 'https://www.google.com';
    final uri = Uri.parse(url);

    try {
      final socket = await _connectThroughSocks(
        proxy,
        uri.host,
        uri.port > 0 ? uri.port : 80,
        timeout: options.timeout,
      );

      if (socket == null) {
        return false;
      }

      // For HTTPS, we need to establish a secure connection
      if (uri.scheme == 'https') {
        final secureSocket = await SecureSocket.secure(socket, host: uri.host);

        // Send a simple HTTP request
        secureSocket.write(
          'GET ${uri.path.isEmpty ? '/' : uri.path} HTTP/1.1\\r\\n'
          'Host: ${uri.host}\\r\\n'
          'Connection: close\\r\\n\\r\\n',
        );

        // Wait for the response
        final completer = Completer<bool>();
        secureSocket.listen(
          (data) {
            final response = String.fromCharCodes(data);
            if (response.contains('HTTP/1.1 200') ||
                response.contains('HTTP/1.0 200')) {
              completer.complete(true);
            } else {
              completer.complete(false);
            }
          },
          onError: (e) {
            completer.complete(false);
          },
          onDone: () {
            if (!completer.isCompleted) {
              completer.complete(false);
            }
          },
        );

        // Wait for the response with a timeout
        return await completer.future.timeout(
          Duration(milliseconds: options.timeout),
          onTimeout: () => false,
        );
      } else {
        // For HTTP, we can send the request directly
        socket.write(
          'GET ${uri.path.isEmpty ? '/' : uri.path} HTTP/1.1\\r\\n'
          'Host: ${uri.host}\\r\\n'
          'Connection: close\\r\\n\\r\\n',
        );

        // Wait for the response
        final completer = Completer<bool>();
        socket.listen(
          (data) {
            final response = String.fromCharCodes(data);
            if (response.contains('HTTP/1.1 200') ||
                response.contains('HTTP/1.0 200')) {
              completer.complete(true);
            } else {
              completer.complete(false);
            }
          },
          onError: (e) {
            completer.complete(false);
          },
          onDone: () {
            if (!completer.isCompleted) {
              completer.complete(false);
            }
          },
        );

        // Wait for the response with a timeout
        return await completer.future.timeout(
          Duration(milliseconds: options.timeout),
          onTimeout: () => false,
        );
      }
    } catch (e) {
      return false;
    }
  }

  /// Connects to a destination through a SOCKS proxy
  static Future<Socket?> _connectThroughSocks(
    Proxy proxy,
    String destinationHost,
    int destinationPort, {
    int timeout = 10000,
  }) async {
    try {
      // Connect to the proxy server
      final socket = await Socket.connect(
        proxy.ip,
        proxy.port,
        timeout: Duration(milliseconds: timeout),
      );

      // Handle SOCKS4 or SOCKS5 based on the proxy protocol
      if (proxy.protocol == ProxyProtocol.socks4) {
        return await _connectThroughSocks4(
          socket,
          proxy,
          destinationHost,
          destinationPort,
          timeout: timeout,
        );
      } else if (proxy.protocol == ProxyProtocol.socks5) {
        return await _connectThroughSocks5(
          socket,
          proxy,
          destinationHost,
          destinationPort,
          timeout: timeout,
        );
      } else {
        socket.destroy();
        return null;
      }
    } catch (e) {
      return null;
    }
  }

  /// Connects through a SOCKS4 proxy
  static Future<Socket?> _connectThroughSocks4(
    Socket socket,
    Proxy proxy,
    String destinationHost,
    int destinationPort, {
    int timeout = 10000,
  }) async {
    try {
      // Resolve the destination host to an IP address
      final addresses = await InternetAddress.lookup(destinationHost);
      if (addresses.isEmpty) {
        socket.destroy();
        return null;
      }

      final destinationIp = addresses.first;

      // SOCKS4 request
      // VN(1) + CD(1) + DSTPORT(2) + DSTIP(4) + USERID(variable) + NULL(1)
      final request = <int>[
        4, // VN: SOCKS version number (4)
        1, // CD: Command code (1 for connect)
        (destinationPort >> 8) & 0xFF, // DSTPORT: high byte
        destinationPort & 0xFF, // DSTPORT: low byte
      ];

      // Add destination IP
      for (final byte in destinationIp.rawAddress) {
        request.add(byte);
      }

      // Add user ID if authenticated
      if (proxy.isAuthenticated && proxy.auth?.username != null) {
        for (final byte in proxy.auth!.username.codeUnits) {
          request.add(byte);
        }
      }

      // Add NULL terminator
      request.add(0);

      // Send the request
      socket.add(request);

      // Wait for the response
      final completer = Completer<Socket?>();
      socket.listen(
        (data) {
          if (data.length >= 8 && data[0] == 0 && data[1] == 90) {
            // Success
            completer.complete(socket);
          } else {
            // Failure
            socket.destroy();
            completer.complete(null);
          }
        },
        onError: (e) {
          socket.destroy();
          completer.complete(null);
        },
        onDone: () {
          if (!completer.isCompleted) {
            completer.complete(null);
          }
        },
      );

      // Wait for the response with a timeout
      return await completer.future.timeout(
        Duration(milliseconds: timeout),
        onTimeout: () {
          socket.destroy();
          return null;
        },
      );
    } catch (e) {
      socket.destroy();
      return null;
    }
  }

  /// Connects through a SOCKS5 proxy
  static Future<Socket?> _connectThroughSocks5(
    Socket socket,
    Proxy proxy,
    String destinationHost,
    int destinationPort, {
    int timeout = 10000,
  }) async {
    try {
      // SOCKS5 authentication request
      // VER(1) + NMETHODS(1) + METHODS(variable)
      final authRequest = <int>[
        5, // VER: SOCKS version number (5)
        proxy.isAuthenticated ? 2 : 1, // NMETHODS: Number of methods
        0, // METHOD: No authentication
      ];

      // Add username/password authentication method if needed
      if (proxy.isAuthenticated) {
        authRequest.add(2); // METHOD: Username/password
      }

      // Send the authentication request
      socket.add(authRequest);

      // Wait for the authentication response
      final authCompleter = Completer<bool>();
      final subscription = socket.listen(
        (data) {
          if (data.length >= 2 && data[0] == 5) {
            if (data[1] == 0) {
              // No authentication required
              authCompleter.complete(true);
            } else if (data[1] == 2 && proxy.isAuthenticated) {
              // Username/password authentication required
              _performUsernamePasswordAuth(
                socket,
                proxy,
                authCompleter,
                timeout,
              );
            } else {
              // Unsupported authentication method
              socket.destroy();
              authCompleter.complete(false);
            }
          } else {
            // Invalid response
            socket.destroy();
            authCompleter.complete(false);
          }
        },
        onError: (e) {
          socket.destroy();
          authCompleter.complete(false);
        },
        onDone: () {
          if (!authCompleter.isCompleted) {
            authCompleter.complete(false);
          }
        },
      );

      // Wait for authentication to complete
      final authSuccess = await authCompleter.future.timeout(
        Duration(milliseconds: timeout),
        onTimeout: () {
          socket.destroy();
          return false;
        },
      );

      if (!authSuccess) {
        return null;
      }

      // Cancel the previous subscription
      await subscription.cancel();

      // SOCKS5 connection request
      // VER(1) + CMD(1) + RSV(1) + ATYP(1) + DST.ADDR(variable) + DST.PORT(2)
      final connectRequest = <int>[
        5, // VER: SOCKS version number (5)
        1, // CMD: Connect
        0, // RSV: Reserved
      ];

      // Try to resolve the destination host to an IP address
      try {
        final addresses = await InternetAddress.lookup(destinationHost);
        if (addresses.isNotEmpty) {
          // Use IP address
          final destinationIp = addresses.first;
          if (destinationIp.type == InternetAddressType.IPv4) {
            connectRequest.add(1); // ATYP: IPv4
            connectRequest.addAll(destinationIp.rawAddress);
          } else {
            connectRequest.add(4); // ATYP: IPv6
            connectRequest.addAll(destinationIp.rawAddress);
          }
        } else {
          // Use domain name
          connectRequest.add(3); // ATYP: Domain name
          connectRequest.add(destinationHost.length); // Length of domain name
          connectRequest.addAll(destinationHost.codeUnits); // Domain name
        }
      } catch (e) {
        // Use domain name
        connectRequest.add(3); // ATYP: Domain name
        connectRequest.add(destinationHost.length); // Length of domain name
        connectRequest.addAll(destinationHost.codeUnits); // Domain name
      }

      // Add destination port
      connectRequest.add((destinationPort >> 8) & 0xFF); // High byte
      connectRequest.add(destinationPort & 0xFF); // Low byte

      // Send the connection request
      socket.add(connectRequest);

      // Wait for the connection response
      final connectCompleter = Completer<Socket?>();
      socket.listen(
        (data) {
          if (data.length >= 10 && data[0] == 5 && data[1] == 0) {
            // Success
            connectCompleter.complete(socket);
          } else {
            // Failure
            socket.destroy();
            connectCompleter.complete(null);
          }
        },
        onError: (e) {
          socket.destroy();
          connectCompleter.complete(null);
        },
        onDone: () {
          if (!connectCompleter.isCompleted) {
            connectCompleter.complete(null);
          }
        },
      );

      // Wait for the connection response with a timeout
      return await connectCompleter.future.timeout(
        Duration(milliseconds: timeout),
        onTimeout: () {
          socket.destroy();
          return null;
        },
      );
    } catch (e) {
      socket.destroy();
      return null;
    }
  }

  /// Performs username/password authentication for SOCKS5
  static void _performUsernamePasswordAuth(
    Socket socket,
    Proxy proxy,
    Completer<bool> completer,
    int timeout,
  ) {
    try {
      if (!proxy.isAuthenticated || proxy.auth == null) {
        socket.destroy();
        completer.complete(false);
        return;
      }

      final username = proxy.auth!.username;
      final password = proxy.auth!.password;

      // Username/password authentication request
      // VER(1) + ULEN(1) + UNAME(variable) + PLEN(1) + PASSWD(variable)
      final authRequest = <int>[
        1, // VER: Username/password auth version
        username.length, // ULEN: Username length
      ];

      // Add username
      authRequest.addAll(username.codeUnits);

      // Add password length and password
      authRequest.add(password.length); // PLEN: Password length
      authRequest.addAll(password.codeUnits); // PASSWD: Password

      // Send the authentication request
      socket.add(authRequest);

      // Wait for the authentication response
      socket.listen(
        (data) {
          if (data.length >= 2 && data[0] == 1 && data[1] == 0) {
            // Authentication successful
            completer.complete(true);
          } else {
            // Authentication failed
            socket.destroy();
            completer.complete(false);
          }
        },
        onError: (e) {
          socket.destroy();
          completer.complete(false);
        },
        onDone: () {
          if (!completer.isCompleted) {
            completer.complete(false);
          }
        },
      );
    } catch (e) {
      socket.destroy();
      completer.complete(false);
    }
  }
}
