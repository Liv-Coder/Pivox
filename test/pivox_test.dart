import 'package:flutter_test/flutter_test.dart';
import 'package:pivox/pivox.dart';

void main() {
  group('Pivox', () {
    test('can be instantiated', () {
      expect(Pivox.builder(), isNotNull);
    });
  });
}
