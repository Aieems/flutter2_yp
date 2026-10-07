import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';

import 'package:flutter_2/core/api_client.dart';
import 'package:flutter_2/core/api_exceptions.dart';
import 'package:flutter_2/models/project.dart';
import 'package:flutter_2/models/project_query.dart';
import 'package:flutter_2/repositories/api/api_project_repository.dart';

void main() {
  late Dio dio;
  late DioAdapter adapter;
  late ApiProjectRepository repo;

  setUp(() {
    dio = buildDio(enableReadRetry: false);
    adapter = DioAdapter(dio: dio);
    dio.httpClientAdapter = adapter;
    repo = ApiProjectRepository(dio);
  });

  test('find разбирает постраничный ответ', () async {
    adapter.onGet(
      '/projects',
      (server) => server.reply(200, {
        'items': [
          {
            'id': 1,
            'title': 'Тест',
            'code': 'PRJ-999',
            'year': 2024,
            'goalAmount': 100,
            'categoryId': 1,
            'partnerIds': [1],
            'tagIds': [2],
            'volunteersTotal': 10,
            'volunteersActive': 5,
          },
        ],
        'page': 1,
        'size': 10,
        'total': 1,
      }),
      queryParameters: {'page': 1, 'size': 10, 'sort': 'title,asc'},
    );

    final page = await repo.find(const ProjectQuery());
    expect(page.total, 1);
    expect(page.items.single.code, 'PRJ-999');
    expect(page.items.single.goalAmount, 100);
  });

  test('create отправляет тело в формате API фонда', () async {
    adapter.onPost(
      '/projects',
      (server) => server.reply(201, {
        'id': 2,
        'title': 'Новый',
        'code': 'PRJ-NEW',
        'year': 2025,
        'goalAmount': 200,
        'categoryId': 1,
        'partnerIds': [],
        'tagIds': [],
        'volunteersTotal': 1,
        'volunteersActive': 1,
      }),
      data: {
        'title': 'Новый',
        'code': 'PRJ-NEW',
        'year': 2025,
        'goalAmount': 200,
        'categoryId': 1,
        'partnerIds': [],
        'tagIds': [],
        'volunteersTotal': 1,
        'volunteersActive': 1,
      },
    );

    final created = await repo.create(
      const Project(
        id: 0,
        title: 'Новый',
        code: 'PRJ-NEW',
        year: 2025,
        goalAmount: 200,
        categoryId: 1,
        partnerIds: [],
        tagIds: [],
        volunteersTotal: 1,
        volunteersActive: 1,
      ),
    );
    expect(created.id, 2);
  });

  test('404 findById возвращает null', () async {
    adapter.onGet(
      '/projects/99',
      (server) => server.reply(404, {'message': 'Не найдено'}),
    );
    expect(await repo.findById(99), isNull);
  });

  test('сбой соединения — NetworkException', () async {
    adapter.onGet(
      '/projects',
      (server) => server.throws(
        0,
        DioException(
          requestOptions: RequestOptions(path: '/projects'),
          type: DioExceptionType.connectionError,
        ),
      ),
    );

    await expectLater(
      repo.find(const ProjectQuery()),
      throwsA(isA<NetworkException>()),
    );
  });
}
