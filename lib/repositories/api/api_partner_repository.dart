import 'package:dio/dio.dart';

import '../../core/api_exceptions.dart';
import '../../models/page_result.dart';
import '../../models/partner.dart';
import '../../models/partner_query.dart';
import '../../models/project.dart';
import '../partner_repository.dart';
import '../project_repository.dart';
import 'api_parsers.dart';

class ApiPartnerRepository implements PartnerRepository {
  ApiPartnerRepository(this._dio, this._projects);

  final Dio _dio;
  final ProjectRepository _projects;

  List<Partner>? _selectCache;

  void _invalidateSelectCache() => _selectCache = null;

  @override
  Future<PageResult<Partner>> find(
    PartnerQuery q, {
    CancelToken? cancelToken,
  }) =>
      guard(() async {
        final response = await _dio.get<Map<String, dynamic>>(
          '/partners',
          queryParameters: {
            if (q.search.trim().isNotEmpty) 'search': q.search.trim(),
            'sort':
                '${q.sortField},${q.sortAscending ? 'asc' : 'desc'}',
            'page': q.page,
            'size': q.size,
            if (q.includeDeleted) 'includeDeleted': true,
          },
          cancelToken: cancelToken,
        );
        return parsePage(response.data!, partnerFromApi);
      });

  @override
  Future<Partner?> findById(int id) => guard(() async {
        try {
          final response =
              await _dio.get<Map<String, dynamic>>('/partners/$id');
          return partnerFromApi(response.data!);
        } on NotFoundException {
          return null;
        }
      });

  @override
  Future<Partner> create(Partner partner) => guard(() async {
        _invalidateSelectCache();
        final response = await _dio.post<Map<String, dynamic>>(
          '/partners',
          data: {
            'lastName': partner.lastName,
            'firstName': partner.firstName,
            'country': partner.country,
            'birthYear': partner.birthYear,
          },
        );
        return partnerFromApi(response.data!);
      });

  @override
  Future<Partner> update(Partner partner) => guard(() async {
        _invalidateSelectCache();
        final response = await _dio.put<Map<String, dynamic>>(
          '/partners/${partner.id}',
          data: {
            'lastName': partner.lastName,
            'firstName': partner.firstName,
            'country': partner.country,
            'birthYear': partner.birthYear,
          },
        );
        return partnerFromApi(response.data!);
      });

  @override
  Future<void> softDelete(int id) => guard(() async {
        _invalidateSelectCache();
        await _dio.delete<void>('/partners/$id');
      });

  @override
  Future<void> hardDelete(int id) => guard(() async {
        _invalidateSelectCache();
        await _dio.delete<void>(
          '/partners/$id',
          queryParameters: {'hard': true},
        );
      });

  @override
  Future<void> restore(int id) => guard(() async {
        _invalidateSelectCache();
        await _dio.post<void>('/partners/$id/restore');
      });

  @override
  Future<int> deleteMany(List<int> ids) => guard(() async {
        _invalidateSelectCache();
        final response = await _dio.post<Map<String, dynamic>>(
          '/partners/bulk-delete',
          data: {'ids': ids},
        );
        return response.data!['deleted'] as int? ?? 0;
      });

  @override
  Future<List<Partner>> listForSelect({int? categoryId}) async {
    _selectCache ??= await _loadAllForSelect();
    var partners = _selectCache!;
    if (categoryId != null) {
      final allProjects = await _projects.listAll();
      final allowed = <int>{};
      for (final Project pr in allProjects) {
        if (pr.categoryId == categoryId) {
          allowed.addAll(pr.partnerIds);
        }
      }
      if (allowed.isNotEmpty) {
        partners = partners.where((p) => allowed.contains(p.id)).toList();
      }
    }
    return [...partners]
      ..sort(
        (a, b) => a.lastName.toLowerCase().compareTo(b.lastName.toLowerCase()),
      );
  }

  Future<List<Partner>> _loadAllForSelect() => guard(() async {
        final response = await _dio.get<Map<String, dynamic>>(
          '/partners',
          queryParameters: {'page': 1, 'size': 500},
        );
        return parsePage(response.data!, partnerFromApi).items;
      });
}
