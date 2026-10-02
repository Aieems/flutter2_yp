import 'package:dio/dio.dart';

import '../../core/api_exceptions.dart';
import '../../models/page_result.dart';
import '../../models/project.dart';
import '../../models/project_query.dart';
import '../../utils/text_normalize.dart';
import '../project_repository.dart';
import 'api_parsers.dart';

class ApiProjectRepository implements ProjectRepository {
  ApiProjectRepository(this._dio);

  final Dio _dio;

  @override
  Future<PageResult<Project>> find(
    ProjectQuery q, {
    CancelToken? cancelToken,
  }) =>
      guard(() async {
        final response = await _dio.get<Map<String, dynamic>>(
          '/projects',
          queryParameters: {
            if (q.search.trim().isNotEmpty) 'search': q.search.trim(),
            if (q.tagId != null) 'tagId': q.tagId,
            if (q.categoryId != null) 'categoryId': q.categoryId,
            if (q.yearFrom != null) 'yearFrom': q.yearFrom,
            if (q.yearTo != null) 'yearTo': q.yearTo,
            'sort': '${projectSortToApi(q.sortField)},${q.sortAscending ? 'asc' : 'desc'}',
            'page': q.page,
            'size': q.size,
            if (q.includeDeleted) 'includeDeleted': true,
          },
          cancelToken: cancelToken,
        );
        return parsePage(response.data!, projectFromApi);
      });

  @override
  Future<Project?> findById(int id) async {
    try {
      return await guard(() async {
        final response = await _dio.get<Map<String, dynamic>>('/projects/$id');
        return projectFromApi(response.data!);
      });
    } on NotFoundException {
      return null;
    }
  }

  @override
  Future<Project?> findByCode(String code) => guard(() async {
        final response = await _dio.get<Map<String, dynamic>>(
          '/projects',
          queryParameters: {
            'search': code.trim(),
            'page': 1,
            'size': 50,
          },
        );
        final page = parsePage(response.data!, projectFromApi);
        final key = normalizeKey(code);
        for (final p in page.items) {
          if (normalizeKey(p.code) == key) return p;
        }
        return null;
      });

  @override
  Future<Project> create(Project project) => guard(() async {
        final response = await _dio.post<Map<String, dynamic>>(
          '/projects',
          data: projectToApiBody(project),
        );
        return projectFromApi(response.data!);
      });

  @override
  Future<Project> update(Project project) => guard(() async {
        final response = await _dio.put<Map<String, dynamic>>(
          '/projects/${project.id}',
          data: projectToApiBody(project),
        );
        return projectFromApi(response.data!);
      });

  @override
  Future<void> softDelete(int id) =>
      guard(() => _dio.delete<void>('/projects/$id'));

  @override
  Future<void> hardDelete(int id) => guard(
        () => _dio.delete<void>(
          '/projects/$id',
          queryParameters: {'hard': true},
        ),
      );

  @override
  Future<void> restore(int id) =>
      guard(() => _dio.post<void>('/projects/$id/restore'));

  @override
  Future<int> deleteMany(List<int> ids) => guard(() async {
        final response = await _dio.post<Map<String, dynamic>>(
          '/projects/bulk-delete',
          data: {'ids': ids},
        );
        return response.data!['deleted'] as int? ?? 0;
      });

  @override
  Future<bool> isCodeTaken(String code, {int? excludeId}) async {
    final found = await findByCode(code);
    if (found == null) return false;
    if (excludeId == null) return true;
    return found.id != excludeId;
  }

  @override
  Future<int> countByCategoryId(int categoryId) => guard(() async {
        final response = await _dio.get<Map<String, dynamic>>(
          '/projects',
          queryParameters: {
            'categoryId': categoryId,
            'page': 1,
            'size': 1,
          },
        );
        return response.data!['total'] as int? ?? 0;
      });

  @override
  Future<List<Project>> listAll({bool includeDeleted = false}) =>
      guard(() async {
        final response = await _dio.get<Map<String, dynamic>>(
          '/projects',
          queryParameters: {
            'page': 1,
            'size': 500,
            if (includeDeleted) 'includeDeleted': true,
          },
        );
        return parsePage(response.data!, projectFromApi).items;
      });
}
