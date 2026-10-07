import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_2/core/api_exceptions.dart';

void main() {
  test('422 разбирается в ValidationException', () {
    final e = mapHttpError(422, {
      'message': 'Ошибка валидации',
      'errors': {'code': 'Код проекта уже используется'},
    });
    expect(e, isA<ValidationException>());
    expect((e as ValidationException).errors['code'],
        'Код проекта уже используется');
  });
}
