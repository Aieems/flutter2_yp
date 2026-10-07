import 'package:dio/dio.dart';

import '../../core/api_exceptions.dart';
import '../../models/page_result.dart';
import '../../models/simple_list_query.dart';
import '../../models/volunteer.dart';
import '../../utils/text_normalize.dart';
import '../volunteer_repository.dart';
import 'api_parsers.dart';

class ApiVolunteerRepository implements VolunteerRepository {
  ApiVolunteerRepository(this._dio);

  final Dio _dio;

  @override
  Future<PageResult<Volunteer>> find(SimpleListQuery q) => guard(() async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/volunteers',
      queryParameters: {
        if (q.search.trim().isNotEmpty) 'search': q.search.trim(),
        'sort': '${q.sortField},${q.sortAscending ? 'asc' : 'desc'}',
        'page': q.page,
        'size': q.size,
        if (q.includeDeleted) 'includeDeleted': true,
      },
    );
    return parsePage(response.data!, volunteerFromApi);
  });

  @override
  Future<Volunteer?> findById(int id) => guard(() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>('/volunteers/$id');
      return volunteerFromApi(response.data!);
    } on NotFoundException {
      return null;
    }
  });

  @override
  Future<Volunteer> create(Volunteer item) => guard(() async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/volunteers',
      data: volunteerToApiBody(item),
    );
    return volunteerFromApi(response.data!);
  });

  @override
  Future<Volunteer> update(Volunteer item) => guard(() async {
    final response = await _dio.put<Map<String, dynamic>>(
      '/volunteers/${item.id}',
      data: volunteerToApiBody(item),
    );
    return volunteerFromApi(response.data!);
  });

  @override
  Future<void> softDelete(int id) =>
      guard(() => _dio.delete<void>('/volunteers/$id'));

  @override
  Future<void> hardDelete(int id) => guard(
    () => _dio.delete<void>('/volunteers/$id', queryParameters: {'hard': true}),
  );

  @override
  Future<void> restore(int id) =>
      guard(() => _dio.post<void>('/volunteers/$id/restore'));

  @override
  Future<int> deleteMany(List<int> ids) => guard(() async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/volunteers/bulk-delete',
      data: {'ids': ids},
    );
    return response.data!['deleted'] as int? ?? 0;
  });

  @override
  Future<bool> isEmailTaken(String email, {int? excludeId}) async {
    final response = await guard(
      () => _dio.get<Map<String, dynamic>>(
        '/volunteers',
        queryParameters: {'search': email.trim(), 'page': 1, 'size': 20},
      ),
    );
    final key = normalizeKey(email);
    for (final v in parsePage(response.data!, volunteerFromApi).items) {
      if (normalizeKey(v.email) == key) {
        if (excludeId == null || v.id != excludeId) return true;
      }
    }
    return false;
  }
}
