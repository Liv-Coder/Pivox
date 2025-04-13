import '../entities/proxy.dart';
import 'proxy_rotation_strategy.dart';

/// Geo-based proxy rotation strategy that rotates through proxies from different countries
class GeoRotationStrategy implements ProxyRotationStrategy {
  /// The list of proxies to rotate through
  final List<Proxy> _proxies;

  /// The current country index
  int _currentCountryIndex = 0;

  /// The current proxy index within the current country
  int _currentProxyIndex = 0;

  /// The list of unique country codes
  final List<String?> _countryCodes = [];

  /// The map of proxies by country code
  final Map<String?, List<Proxy>> _proxiesByCountry = {};

  /// Creates a new [GeoRotationStrategy] with the given parameters
  GeoRotationStrategy({required List<Proxy> proxies})
    : _proxies = List.from(proxies) {
    _initializeCountryData();
  }

  /// Initializes the country data
  void _initializeCountryData() {
    _proxiesByCountry.clear();
    _countryCodes.clear();

    // Group proxies by country
    for (final proxy in _proxies) {
      final countryCode = proxy.countryCode;
      if (!_proxiesByCountry.containsKey(countryCode)) {
        _proxiesByCountry[countryCode] = [];
        _countryCodes.add(countryCode);
      }
      _proxiesByCountry[countryCode]!.add(proxy);
    }

    // Sort country codes for deterministic behavior
    _countryCodes.sort((a, b) {
      if (a == null) return 1;
      if (b == null) return -1;
      return a.compareTo(b);
    });

    // Reset indices
    _currentCountryIndex = 0;
    _currentProxyIndex = 0;
  }

  @override
  Proxy selectProxy(List<Proxy> proxies) {
    if (proxies.isEmpty) {
      throw ArgumentError('Proxy list cannot be empty');
    }

    // Group proxies by country
    final proxiesByCountry = <String?, List<Proxy>>{};
    final countryCodes = <String?>[];

    for (final proxy in proxies) {
      final countryCode = proxy.countryCode;
      if (!proxiesByCountry.containsKey(countryCode)) {
        proxiesByCountry[countryCode] = [];
        countryCodes.add(countryCode);
      }
      proxiesByCountry[countryCode]!.add(proxy);
    }

    // Sort country codes for deterministic behavior
    countryCodes.sort((a, b) {
      if (a == null) return 1;
      if (b == null) return -1;
      return a.compareTo(b);
    });

    if (countryCodes.isEmpty) {
      return proxies.first;
    }

    // Get the current country code
    final countryIndex = _currentCountryIndex % countryCodes.length;
    final countryCode = countryCodes[countryIndex];

    // Get the proxies for the current country
    final countryProxies = proxiesByCountry[countryCode] ?? [];
    if (countryProxies.isEmpty) {
      // Move to the next country
      _currentCountryIndex = (_currentCountryIndex + 1) % countryCodes.length;
      return selectProxy(proxies);
    }

    // Get the current proxy
    final proxyIndex = _currentProxyIndex % countryProxies.length;
    final proxy = countryProxies[proxyIndex];

    // Move to the next proxy in the current country
    _currentProxyIndex = (_currentProxyIndex + 1) % countryProxies.length;

    // If we've gone through all proxies in the current country, move to the next country
    if (_currentProxyIndex == 0) {
      _currentCountryIndex = (_currentCountryIndex + 1) % countryCodes.length;
    }

    return proxy;
  }

  @override
  Proxy? getNextProxy() {
    if (_proxies.isEmpty || _countryCodes.isEmpty) {
      return null;
    }

    // Get the current country code
    final countryCode = _countryCodes[_currentCountryIndex];

    // Get the proxies for the current country
    final countryProxies = _proxiesByCountry[countryCode] ?? [];
    if (countryProxies.isEmpty) {
      // Move to the next country
      _currentCountryIndex = (_currentCountryIndex + 1) % _countryCodes.length;
      _currentProxyIndex = 0;
      return getNextProxy();
    }

    // Get the current proxy
    final proxy = countryProxies[_currentProxyIndex];

    // Move to the next proxy in the current country
    _currentProxyIndex = (_currentProxyIndex + 1) % countryProxies.length;

    // If we've gone through all proxies in the current country, move to the next country
    if (_currentProxyIndex == 0) {
      _currentCountryIndex = (_currentCountryIndex + 1) % _countryCodes.length;
    }

    return proxy;
  }

  @override
  void recordSuccess(Proxy proxy) {
    // No need to record success for this strategy
  }

  @override
  void recordFailure(Proxy proxy) {
    // No need to record failure for this strategy
  }

  @override
  void updateProxies(List<Proxy> proxies) {
    _proxies.clear();
    _proxies.addAll(proxies);
    _initializeCountryData();
  }
}
