import 'package:flutter_test/flutter_test.dart';
import 'package:pivox/pivox.dart';

class MockProxyPoolManager implements ProxyPoolManager {
  final List<Proxy> _proxies = [];
  int _currentIndex = 0;
  
  void addMockProxy(Proxy proxy) {
    _proxies.add(proxy);
  }
  
  @override
  Future<Proxy?> getNextProxy() async {
    if (_proxies.isEmpty) return null;
    
    final proxy = _proxies[_currentIndex];
    _currentIndex = (_currentIndex + 1) % _proxies.length;
    return proxy;
  }
  
  @override
  Future<void> addProxy(Proxy proxy) async {
    _proxies.add(proxy);
  }
  
  @override
  Future<List<Proxy>> getActiveProxies() async {
    return _proxies.where((p) => p.isActive).toList();
  }
  
  @override
  Future<void> markProxyAsInactive(Proxy proxy) async {
    final index = _proxies.indexWhere(
      (p) => p.host == proxy.host && p.port == proxy.port,
    );
    
    if (index != -1) {
      _proxies[index] = Proxy(
        host: proxy.host,
        port: proxy.port,
        username: proxy.username,
        password: proxy.password,
        type: proxy.type,
        lastChecked: DateTime.now(),
        responseTime: proxy.responseTime,
        isActive: false,
      );
    }
  }
  
  @override
  Future<void> removeProxy(Proxy proxy) async {
    _proxies.removeWhere(
      (p) => p.host == proxy.host && p.port == proxy.port,
    );
  }
}

class MockProxyValidator implements ProxyValidator {
  final Map<String, bool> _validationResults = {};
  
  void setValidationResult(String host, bool isValid) {
    _validationResults[host] = isValid;
  }
  
  @override
  Future<bool> validate(Proxy proxy) async {
    return _validationResults[proxy.host] ?? false;
  }
}

void main() {
  group('PivoxClient', () {
    late MockProxyPoolManager poolManager;
    late MockProxyValidator validator;
    late PivoxClient client;
    
    setUp(() {
      poolManager = MockProxyPoolManager();
      validator = MockProxyValidator();
      client = PivoxClient(
        poolManager: poolManager,
        validator: validator,
      );
    });
    
    test('should return null when no proxies are available', () async {
      final proxy = await client.getProxy();
      expect(proxy, isNull);
    });
    
    test('should return valid proxy', () async {
      final validProxy = Proxy(
        host: '192.168.1.1',
        port: 8080,
        type: ProxyType.http,
        lastChecked: DateTime.now(),
        responseTime: 100,
      );
      
      poolManager.addMockProxy(validProxy);
      validator.setValidationResult('192.168.1.1', true);
      
      final proxy = await client.getProxy();
      expect(proxy?.host, '192.168.1.1');
    });
    
    test('should skip invalid proxies', () async {
      final invalidProxy = Proxy(
        host: '192.168.1.1',
        port: 8080,
        type: ProxyType.http,
        lastChecked: DateTime.now(),
        responseTime: 100,
      );
      
      final validProxy = Proxy(
        host: '192.168.1.2',
        port: 8080,
        type: ProxyType.http,
        lastChecked: DateTime.now(),
        responseTime: 100,
      );
      
      poolManager.addMockProxy(invalidProxy);
      poolManager.addMockProxy(validProxy);
      
      validator.setValidationResult('192.168.1.1', false);
      validator.setValidationResult('192.168.1.2', true);
      
      final proxy = await client.getProxy();
      expect(proxy?.host, '192.168.1.2');
    });
  });
}
