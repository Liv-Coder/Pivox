import 'package:pivox/pivox.dart';

abstract class ProxyPoolManager {
  Future<Proxy?> getNextProxy();
  Future<void> addProxy(Proxy proxy);
  Future<void> removeProxy(Proxy proxy);
  Future<void> markProxyAsInactive(Proxy proxy);
  Future<List<Proxy>> getActiveProxies();
}
