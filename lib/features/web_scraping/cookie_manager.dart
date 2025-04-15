import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

/// A manager for cookies to maintain sessions across requests
class CookieManager {
  /// Shared preferences instance for storing cookies
  final SharedPreferences? _prefs;

  /// Key prefix for storing cookies in shared preferences
  static const String _cookieKeyPrefix = 'cookie_';

  /// Creates a new [CookieManager] with the given shared preferences
  CookieManager(this._prefs);

  /// Factory constructor to create a [CookieManager] from shared preferences
  static Future<CookieManager> create() async {
    final prefs = await SharedPreferences.getInstance();
    return CookieManager(prefs);
  }

  /// Stores cookies from a response for a domain
  void storeCookies(String domain, List<Cookie> cookies) {
    if (cookies.isEmpty) return;

    // Get existing cookies for this domain
    final existingCookies = getCookies(domain);
    final cookieMap = {for (var cookie in existingCookies) cookie.name: cookie};

    // Update with new cookies
    for (var cookie in cookies) {
      if (cookie.expires != null && cookie.expires!.isBefore(DateTime.now())) {
        // Cookie is expired, remove it
        cookieMap.remove(cookie.name);
      } else {
        // Update or add the cookie
        cookieMap[cookie.name] = cookie;
      }
    }

    // Convert cookies to a serializable format
    final serializedCookies =
        cookieMap.values.map((cookie) {
          return {
            'name': cookie.name,
            'value': cookie.value,
            'domain': cookie.domain,
            'path': cookie.path,
            'expires': cookie.expires?.millisecondsSinceEpoch,
            'httpOnly': cookie.httpOnly,
            'secure': cookie.secure,
          };
        }).toList();

    // Store the cookies
    _prefs?.setString(_cookieKeyPrefix + domain, jsonEncode(serializedCookies));
  }

  /// Gets cookies for a domain
  List<Cookie> getCookies(String domain) {
    final cookieJson = _prefs?.getString(_cookieKeyPrefix + domain);
    if (cookieJson == null) return [];

    try {
      final List<dynamic> cookieList = jsonDecode(cookieJson);
      return cookieList.map((cookieData) {
        final cookie = Cookie(cookieData['name'], cookieData['value']);

        if (cookieData['domain'] != null) cookie.domain = cookieData['domain'];
        if (cookieData['path'] != null) cookie.path = cookieData['path'];
        if (cookieData['expires'] != null) {
          cookie.expires = DateTime.fromMillisecondsSinceEpoch(
            cookieData['expires'],
          );
        }
        if (cookieData['httpOnly'] != null) {
          cookie.httpOnly = cookieData['httpOnly'];
        }
        if (cookieData['secure'] != null) {
          cookie.secure = cookieData['secure'];
        }

        return cookie;
      }).toList();
    } catch (e) {
      // If there's an error parsing the cookies, return an empty list
      return [];
    }
  }

  /// Gets a cookie header string for a domain
  String getCookieHeader(String domain) {
    final cookies = getCookies(domain);
    if (cookies.isEmpty) return '';

    return cookies.map((cookie) => '${cookie.name}=${cookie.value}').join('; ');
  }

  /// Clears cookies for a domain
  void clearCookies(String domain) {
    _prefs?.remove(_cookieKeyPrefix + domain);
  }

  /// Clears all cookies
  void clearAllCookies() {
    final keys = _prefs?.getKeys() ?? {};
    for (final key in keys) {
      if (key.startsWith(_cookieKeyPrefix)) {
        _prefs?.remove(key);
      }
    }
  }

  /// Extracts cookies from a response
  List<Cookie> extractCookiesFromResponse(HttpClientResponse response) {
    final cookies = <Cookie>[];
    final cookieHeaders = response.headers[HttpHeaders.setCookieHeader];

    if (cookieHeaders != null) {
      for (final header in cookieHeaders) {
        try {
          cookies.add(Cookie.fromSetCookieValue(header));
        } catch (_) {
          // Ignore invalid cookies
        }
      }
    }

    return cookies;
  }
}
