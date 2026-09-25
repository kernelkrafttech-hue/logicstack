import 'package:flutter_test/flutter_test.dart';
import 'package:maintenanceos/core/utils/validators.dart';

void main() {
  group('Validators.usState', () {
    test('rejects empty input', () {
      expect(Validators.usState(''), isNotNull);
      expect(Validators.usState('   '), isNotNull);
      expect(Validators.usState(null), isNotNull);
    });

    test('rejects non 2-letter inputs', () {
      expect(Validators.usState('California'), isNotNull);
      expect(Validators.usState('C'), isNotNull);
      expect(Validators.usState('12'), isNotNull);
    });

    test('accepts 2-letter codes regardless of case', () {
      expect(Validators.usState('CA'), isNull);
      expect(Validators.usState('ca'), isNull);
    });
  });

  group('Validators.zipCode', () {
    test('rejects empty input', () {
      expect(Validators.zipCode(''), isNotNull);
      expect(Validators.zipCode(null), isNotNull);
    });

    test('rejects malformed codes', () {
      expect(Validators.zipCode('1234'), isNotNull);
      expect(Validators.zipCode('123456'), isNotNull);
      expect(Validators.zipCode('12345-67'), isNotNull);
      expect(Validators.zipCode('abcde'), isNotNull);
    });

    test('accepts 5-digit and ZIP+4 formats', () {
      expect(Validators.zipCode('94607'), isNull);
      expect(Validators.zipCode('94607-1234'), isNull);
    });
  });
}
