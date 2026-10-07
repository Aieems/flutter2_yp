import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_2/widgets/password_strength_field.dart';

void main() {
  group('PasswordStrengthField.isStrong', () {
    test('слабый пароль отклоняется', () {
      expect(PasswordStrengthField.isStrong('short'), isFalse);
      expect(PasswordStrengthField.isStrong('longenough'), isFalse);
    });

    test('сильный пароль принимается', () {
      expect(PasswordStrengthField.isStrong('VolunteeR1!'), isTrue);
    });
  });
}
