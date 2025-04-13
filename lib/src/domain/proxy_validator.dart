import 'package:pivox/pivox.dart';

abstract class ProxyValidator {
  Future<bool> validate(Proxy proxy);
}
