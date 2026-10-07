import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_2/models/project.dart';

void main() {
  group('Project.fromJson', () {
    test('отсутствующие поля не приводят к исключению', () {
      final p = Project.fromJson({'id': 1});
      expect(p.title, '');
      expect(p.partnerIds, isEmpty);
      expect(p.tagIds, isEmpty);
    });

    test('разбирает поля API фонда', () {
      final p = Project.fromJson({
        'id': 2,
        'title': 'Сбор',
        'code': 'PRJ-1',
        'year': 2023,
        'goalAmount': 5000,
        'categoryId': 3,
        'partnerIds': [1, 2],
        'tagIds': [4],
        'volunteersTotal': 10,
        'volunteersActive': 7,
      });
      expect(p.code, 'PRJ-1');
      expect(p.partnerIds, [1, 2]);
      expect(p.volunteersActive, 7);
    });
  });
}
