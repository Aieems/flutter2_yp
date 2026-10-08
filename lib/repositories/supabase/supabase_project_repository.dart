import 'package:dio/dio.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/api_exceptions.dart';
import '../../core/supabase_errors.dart';
import '../../models/page_result.dart';
import '../../models/project.dart';
import '../../models/project_query.dart';
import '../../utils/text_normalize.dart';
import '../api/api_parsers.dart';
import '../project_repository.dart';
import 'supabase_page.dart';
import 'supabase_row_mappers.dart';

class SupabaseProjectRepository implements ProjectRepository {
  SupabaseClient get _db => Supabase.instance.client;

  Future<List<Project>> _loadAll({bool includeDeleted = false}) =>
      guardSupabase(() async {
        final rows = await _db.from('projects').select();
        return rows
            .map((e) => projectFromApi(projectRowToApi(Map<String, dynamic>.from(e as Map))))
            .where((p) => includeDeleted || !p.isDeleted)
            .toList();
      });

  List<Project> _filterAndSort(List<Project> rows, ProjectQuery q) {
    var list = rows;
    if (q.search.trim().isNotEmpty) {
      final needle = q.search.trim().toLowerCase();
      list = list
          .where(
            (p) =>
                p.title.toLowerCase().contains(needle) ||
                p.code.toLowerCase().contains(needle),
          )
          .toList();
    }
    if (q.tagId != null) {
      list = list.where((p) => p.tagIds.contains(q.tagId)).toList();
    }
    if (q.categoryId != null) {
      list = list.where((p) => p.categoryId == q.categoryId).toList();
    }
    if (q.yearFrom != null) {
      list = list.where((p) => p.year >= q.yearFrom!).toList();
    }
    if (q.yearTo != null) {
      list = list.where((p) => p.year <= q.yearTo!).toList();
    }
    list.sort((a, b) {
      final field = q.sortField;
      int cmp;
      switch (field) {
        case 'code':
          cmp = a.code.compareTo(b.code);
        case 'year':
          cmp = a.year.compareTo(b.year);
        case 'goalAmount':
          cmp = a.goalAmount.compareTo(b.goalAmount);
        default:
          cmp = a.title.compareTo(b.title);
      }
      return q.sortAscending ? cmp : -cmp;
    });
    return list;
  }

  @override
  Future<PageResult<Project>> find(
    ProjectQuery query, {
    CancelToken? cancelToken,
  }) async {
    if (cancelToken?.isCancelled == true) {
      throw const RequestCancelledException();
    }
    final all = await _loadAll(includeDeleted: query.includeDeleted);
    final filtered = _filterAndSort(all, query);
    return paginateInMemory(
      all: filtered,
      page: query.page,
      size: query.size,
    );
  }

  @override
  Future<Project?> findById(int id) => guardSupabase(() async {
        final row = await _db.from('projects').select().eq('id', id).maybeSingle();
        if (row == null) return null;
        return projectFromApi(projectRowToApi(Map<String, dynamic>.from(row)));
      });

  @override
  Future<Project?> findByCode(String code) async {
    final key = normalizeKey(code);
    final all = await _loadAll();
    for (final p in all) {
      if (normalizeKey(p.code) == key) return p;
    }
    return null;
  }

  @override
  Future<Project> create(Project project) => guardSupabase(() async {
        final body = projectToRow(project);
        final row = await _db.from('projects').insert(body).select().single();
        return projectFromApi(projectRowToApi(Map<String, dynamic>.from(row)));
      });

  @override
  Future<Project> update(Project project) => guardSupabase(() async {
        final body = projectToRow(project);
        final row = await _db
            .from('projects')
            .update(body)
            .eq('id', project.id)
            .select()
            .single();
        return projectFromApi(projectRowToApi(Map<String, dynamic>.from(row)));
      });

  @override
  Future<void> softDelete(int id) => guardSupabase(() async {
        await _db
            .from('projects')
            .update({'deleted_at': DateTime.now().toUtc().toIso8601String()})
            .eq('id', id);
      });

  @override
  Future<void> hardDelete(int id) => guardSupabase(() async {
        await _db.from('projects').delete().eq('id', id);
      });

  @override
  Future<void> restore(int id) => guardSupabase(() async {
        await _db.from('projects').update({'deleted_at': null}).eq('id', id);
      });

  @override
  Future<int> deleteMany(List<int> ids) async {
    var n = 0;
    for (final id in ids) {
      await softDelete(id);
      n++;
    }
    return n;
  }

  @override
  Future<bool> isCodeTaken(String code, {int? excludeId}) async {
    final found = await findByCode(code);
    if (found == null) return false;
    if (excludeId == null) return true;
    return found.id != excludeId;
  }

  @override
  Future<int> countByCategoryId(int categoryId) async {
    final all = await _loadAll();
    return all.where((p) => p.categoryId == categoryId).length;
  }

  @override
  Future<List<Project>> listAll({bool includeDeleted = false}) =>
      _loadAll(includeDeleted: includeDeleted);
}
