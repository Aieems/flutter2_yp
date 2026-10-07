import 'package:dio/dio.dart';

import '../../core/api_exceptions.dart';
import '../../models/fund_tag.dart';
import '../../models/page_result.dart';
import '../../models/simple_list_query.dart';
import '../tag_repository.dart';
import 'api_parsers.dart';

class ApiTagRepository implements TagRepository {
  ApiTagRepository(this._dio);

  final Dio _dio;

  List<FundTag>? _selectCache;

  void _invalidateSelectCache() => _selectCache = null;

  @override
  Future<PageResult<FundTag>> find(SimpleListQuery q) => guard(() async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/tags',
      queryParameters: {
        if (q.search.trim().isNotEmpty) 'search': q.search.trim(),
        'sort': '${q.sortField},${q.sortAscending ? 'asc' : 'desc'}',
        'page': q.page,
        'size': q.size,
        if (q.includeDeleted) 'includeDeleted': true,
      },
    );
    return parsePage(response.data!, tagFromApi);
  });

  @override
  Future<FundTag?> findById(int id) => guard(() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>('/tags/$id');
      return tagFromApi(response.data!);
    } on NotFoundException {
      return null;
    }
  });

  @override
  Future<List<FundTag>> listForSelect({int? categoryId}) async {
    _selectCache ??= await _loadAllForSelect();
    var tags = _selectCache!;
    if (categoryId != null) {
      tags = tags.where((t) => t.categoryId == categoryId).toList();
    }
    return [...tags]..sort((a, b) => a.name.compareTo(b.name));
  }

  Future<List<FundTag>> _loadAllForSelect() => guard(() async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/tags',
      queryParameters: {'page': 1, 'size': 500},
    );
    return parsePage(response.data!, tagFromApi).items;
  });

  @override
  Future<FundTag> create(FundTag item) => guard(() async {
    _invalidateSelectCache();
    final response = await _dio.post<Map<String, dynamic>>(
      '/tags',
      data: tagToApiBody(item),
    );
    return tagFromApi(response.data!);
  });

  @override
  Future<FundTag> update(FundTag item) => guard(() async {
    _invalidateSelectCache();
    final response = await _dio.put<Map<String, dynamic>>(
      '/tags/${item.id}',
      data: tagToApiBody(item),
    );
    return tagFromApi(response.data!);
  });

  @override
  Future<void> softDelete(int id) => guard(() async {
    _invalidateSelectCache();
    await _dio.delete<void>('/tags/$id');
  });

  @override
  Future<void> hardDelete(int id) => guard(() async {
    _invalidateSelectCache();
    await _dio.delete<void>('/tags/$id', queryParameters: {'hard': true});
  });

  @override
  Future<void> restore(int id) => guard(() async {
    _invalidateSelectCache();
    await _dio.post<void>('/tags/$id/restore');
  });

  @override
  Future<int> deleteMany(List<int> ids) => guard(() async {
    _invalidateSelectCache();
    final response = await _dio.post<Map<String, dynamic>>(
      '/tags/bulk-delete',
      data: {'ids': ids},
    );
    return response.data!['deleted'] as int? ?? 0;
  });
}
