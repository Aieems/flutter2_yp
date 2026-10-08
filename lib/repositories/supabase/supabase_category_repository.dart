import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/supabase_errors.dart';
import '../../models/fund_category.dart';
import '../../models/page_result.dart';
import '../../models/simple_list_query.dart';
import '../../utils/text_normalize.dart';
import '../api/api_parsers.dart';
import '../category_repository.dart';
import '../project_repository.dart';
import 'supabase_page.dart';
import 'supabase_row_mappers.dart';

class SupabaseCategoryRepository implements CategoryRepository {
  SupabaseCategoryRepository(this._projects);

  final ProjectRepository _projects;
  List<FundCategory>? _selectCache;

  SupabaseClient get _db => Supabase.instance.client;

  void _invalidate() => _selectCache = null;

  Future<List<FundCategory>> _loadAll({bool includeDeleted = false}) =>
      guardSupabase(() async {
        final rows = await _db.from('categories').select();
        return rows
            .map((e) => categoryFromApi(categoryRowToApi(Map<String, dynamic>.from(e as Map))))
            .where((c) => includeDeleted || !c.isDeleted)
            .toList();
      });

  List<FundCategory> _filterSort(List<FundCategory> rows, SimpleListQuery q) {
    var list = rows;
    if (q.search.trim().isNotEmpty) {
      final n = q.search.trim().toLowerCase();
      list = list.where((c) => c.name.toLowerCase().contains(n)).toList();
    }
    list.sort((a, b) {
      final cmp = a.name.compareTo(b.name);
      return q.sortAscending ? cmp : -cmp;
    });
    return list;
  }

  @override
  Future<PageResult<FundCategory>> find(SimpleListQuery q) async {
    final all = await _loadAll(includeDeleted: q.includeDeleted);
    return paginateInMemory(
      all: _filterSort(all, q),
      page: q.page,
      size: q.size,
    );
  }

  @override
  Future<FundCategory?> findById(int id) => guardSupabase(() async {
        final row = await _db.from('categories').select().eq('id', id).maybeSingle();
        if (row == null) return null;
        return categoryFromApi(categoryRowToApi(Map<String, dynamic>.from(row)));
      });

  @override
  Future<FundCategory?> findByName(String name) async {
    final key = normalizeName(name);
    for (final c in await _loadAll()) {
      if (!c.isDeleted && normalizeName(c.name) == key) return c;
    }
    return null;
  }

  @override
  Future<bool> isNameTaken(String name, {int? excludeId}) async {
    final found = await findByName(name);
    if (found == null) return false;
    if (excludeId == null) return true;
    return found.id != excludeId;
  }

  @override
  Future<List<FundCategory>> listForSelect() async {
    _selectCache ??= await _loadAll();
    return [..._selectCache!]..sort((a, b) => a.name.compareTo(b.name));
  }

  @override
  Future<FundCategory> create(FundCategory item) => guardSupabase(() async {
        _invalidate();
        final row = await _db
            .from('categories')
            .insert({'name': item.name})
            .select()
            .single();
        return categoryFromApi(categoryRowToApi(Map<String, dynamic>.from(row)));
      });

  @override
  Future<FundCategory> update(FundCategory item) => guardSupabase(() async {
        _invalidate();
        final row = await _db
            .from('categories')
            .update({'name': item.name})
            .eq('id', item.id)
            .select()
            .single();
        return categoryFromApi(categoryRowToApi(Map<String, dynamic>.from(row)));
      });

  @override
  Future<void> softDelete(int id) => guardSupabase(() async {
        _invalidate();
        await _db
            .from('categories')
            .update({'deleted_at': DateTime.now().toUtc().toIso8601String()})
            .eq('id', id);
      });

  @override
  Future<void> hardDelete(int id) => guardSupabase(() async {
        _invalidate();
        await _db.from('categories').delete().eq('id', id);
      });

  @override
  Future<void> restore(int id) => guardSupabase(() async {
        _invalidate();
        await _db.from('categories').update({'deleted_at': null}).eq('id', id);
      });

  @override
  Future<int> deleteMany(List<int> ids) async {
    _invalidate();
    var n = 0;
    for (final id in ids) {
      await softDelete(id);
      n++;
    }
    return n;
  }

  @override
  Future<int> countLinkedProjects(int categoryId) =>
      _projects.countByCategoryId(categoryId);
}
