import 'package:dio/dio.dart';

import '../../core/api_exceptions.dart';
import '../../models/fund_category.dart';
import '../../models/page_result.dart';
import '../../models/simple_list_query.dart';
import '../../utils/text_normalize.dart';
import '../category_repository.dart';
import '../project_repository.dart';
import 'api_parsers.dart';

class ApiCategoryRepository implements CategoryRepository {
  ApiCategoryRepository(this._dio, this._projects);

  final Dio _dio;
  final ProjectRepository _projects;

  List<FundCategory>? _selectCache;

  void _invalidateSelectCache() => _selectCache = null;

  @override
  Future<PageResult<FundCategory>> find(SimpleListQuery q) =>
      guard(() async {
        final response = await _dio.get<Map<String, dynamic>>(
          '/categories',
          queryParameters: {
            if (q.search.trim().isNotEmpty) 'search': q.search.trim(),
            'sort': '${q.sortField},${q.sortAscending ? 'asc' : 'desc'}',
            'page': q.page,
            'size': q.size,
            if (q.includeDeleted) 'includeDeleted': true,
          },
        );
        return parsePage(response.data!, categoryFromApi);
      });

  @override
  Future<FundCategory?> findById(int id) => guard(() async {
        try {
          final response =
              await _dio.get<Map<String, dynamic>>('/categories/$id');
          return categoryFromApi(response.data!);
        } on NotFoundException {
          return null;
        }
      });

  @override
  Future<FundCategory?> findByName(String name) => guard(() async {
        final response = await _dio.get<Map<String, dynamic>>(
          '/categories',
          queryParameters: {'search': name.trim(), 'page': 1, 'size': 50},
        );
        final key = normalizeName(name);
        for (final c in parsePage(response.data!, categoryFromApi).items) {
          if (!c.isDeleted && normalizeName(c.name) == key) return c;
        }
        return null;
      });

  @override
  Future<bool> isNameTaken(String name, {int? excludeId}) async {
    final found = await findByName(name);
    if (found == null) return false;
    if (excludeId == null) return true;
    return found.id != excludeId;
  }

  @override
  Future<List<FundCategory>> listForSelect() async {
    _selectCache ??= await _loadAllForSelect();
    return [..._selectCache!]
      ..sort((a, b) => a.name.compareTo(b.name));
  }

  Future<List<FundCategory>> _loadAllForSelect() => guard(() async {
        final response = await _dio.get<Map<String, dynamic>>(
          '/categories',
          queryParameters: {'page': 1, 'size': 500},
        );
        return parsePage(response.data!, categoryFromApi).items;
      });

  @override
  Future<FundCategory> create(FundCategory item) => guard(() async {
        _invalidateSelectCache();
        final response = await _dio.post<Map<String, dynamic>>(
          '/categories',
          data: {'name': item.name},
        );
        return categoryFromApi(response.data!);
      });

  @override
  Future<FundCategory> update(FundCategory item) => guard(() async {
        _invalidateSelectCache();
        final response = await _dio.put<Map<String, dynamic>>(
          '/categories/${item.id}',
          data: {'name': item.name},
        );
        return categoryFromApi(response.data!);
      });

  @override
  Future<void> softDelete(int id) => guard(() async {
        _invalidateSelectCache();
        await _dio.delete<void>('/categories/$id');
      });

  @override
  Future<void> hardDelete(int id) => guard(() async {
        _invalidateSelectCache();
        await _dio.delete<void>(
          '/categories/$id',
          queryParameters: {'hard': true},
        );
      });

  @override
  Future<void> restore(int id) => guard(() async {
        _invalidateSelectCache();
        await _dio.post<void>('/categories/$id/restore');
      });

  @override
  Future<int> deleteMany(List<int> ids) => guard(() async {
        _invalidateSelectCache();
        var count = 0;
        for (final id in ids) {
          try {
            await softDelete(id);
            count++;
          } on ConflictException {
            // пропуск
          }
        }
        return count;
      });

  @override
  Future<int> countLinkedProjects(int categoryId) =>
      _projects.countByCategoryId(categoryId);
}
