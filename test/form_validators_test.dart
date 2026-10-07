import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_2/validation/form_validators.dart';

void main() {
  group('FormValidators.required', () {
    test('пустая строка отклоняется', () {
      expect(FormValidators.required(''), isNotNull);
      expect(FormValidators.required('   '), isNotNull);
    });

    test('непустая строка принимается', () {
      expect(FormValidators.required('Проект помощи'), isNull);
    });
  });

  group('FormValidators.year', () {
    test('год вне диапазона отклоняется', () {
      expect(FormValidators.year('1800'), isNotNull);
      expect(FormValidators.year('abc'), isNotNull);
    });

    test('год в диапазоне принимается', () {
      expect(FormValidators.year('2024'), isNull);
    });
  });

  group('FormValidators.email', () {
    test('некорректный email отклоняется', () {
      expect(FormValidators.email('not-email'), isNotNull);
    });

    test('корректный email принимается', () {
      expect(FormValidators.email('user@example.org'), isNull);
    });
  });
}
