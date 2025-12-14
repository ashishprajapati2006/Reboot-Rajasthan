import 'package:flutter_test/flutter_test.dart';
import 'package:saaf_surksha/utils/validation_utils.dart';

void main() {
  group('ValidationUtils', () {
    test('validates email', () {
      expect(ValidationUtils.isValidEmail('test@example.com'), isTrue);
      expect(ValidationUtils.isValidEmail('bad-email'), isFalse);
    });

    test('validates phone', () {
      expect(ValidationUtils.isValidPhone('+919876543210'), isTrue);
      expect(ValidationUtils.isValidPhone('123'), isFalse);
    });
  });
}
