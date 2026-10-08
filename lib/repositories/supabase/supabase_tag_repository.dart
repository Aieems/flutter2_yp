import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/supabase_errors.dart';
import '../../models/fund_tag.dart';
import '../../models/page_result.dart';
import '../../models/simple_list_query.dart';
import '../api/api_parsers.dart';
import '../tag_repository.dart';
import 'supabase_page.dart';
import 'supabase_row_mappers.dart';

class SupabaseTagRepository implements TagRepository {
  SupabaseClient get _db => Supabase.instance.client;

  Future<List<FundTag>> _loadAll({bool includeDeleted = false}) =>
      guardSupabase(() async {
        final rows = await _db.from('tags').select();
        return rows
            .map((e) => tagFromApi(tagRowToApi(Map<String, dynamic>.from(e as Map))))
            .where((t) => includeDeleted || !t.isDeleted)
            .toList();
      });

  List<FundTag> _filterSort(List<FundTag> rows, SimpleListQuery q) {
    var list = rows;
    if (q.search.trim().isNotEmpty) {
      final n = q.search.trim().toLowerCase();
      list = list.where((t) => t.name.toLowerCase().contains(n)).toList();
    }
    list.sort((a, b) {
      final cmp = a.name.compareTo(b.name);
      return q.sortAscending ? cmp : -cmp;
    });
    return list;
  }

  @override
  Future<PageResult<FundTag>> find(SimpleListQuery q) async {
    final all = await _loadAll(includeDeleted: q.includeDeleted);
    return paginateInMemory(
      all: _filterSort(all, q),
      page: q.page,
      size: q.size,
    );
  }

  @override
  Future<FundTag?> findById(int id) => guardSupabase(() async {
        final row = await _db.from('tags').select().eq('id', id).maybeSingle();
        if (row == null) return null;
        return tagFromApi(tagRowToApi(Map<String, dynamic>.from(row)));
      });

  @override
  Future<List<FundTag>> listForSelect({int? categoryId}) async {
    var all = await _loadAll();
    if (categoryId != null) {
      all = all.where((t) => t.categoryId == categoryId).toList();
    }
    all.sort((a, b) => a.name.compareTo(b.name));
    return all;
  }

  @override
  Future<FundTag> create(FundTag item) => guardSupabase(() async {
        final row = await _db
            .from('tags')
            .insert({'name': item.name, 'category_id': item.categoryId})
            .select()
            .single();
        return tagFromApi(tagRowToApi(Map<String, dynamic>.from(row)));
      });

  @override
  Future<FundTag> update(FundTag item) => guardSupabase(() async {
        final row = await _db
            .from('tags')
            .update({'name': item.name, 'category_id': item.categoryId})
            .eq('id', item.id)
            .select()
            .single();
        return tagFromApi(tagRowToApi(Map<String, dynamic>.from(row)));
      });

  @override
  Future<void> softDelete(int id) => guardSupabase(() async {
        await _db
            .from('tags')
            .update({'deleted_at': DateTime.now().toUtc().toIso8601String()})
            .eq('id', id);
      });

  @override
  Future<void> hardDelete(int id) => guardSupabase(() async {
        await _db.from('tags').delete().eq('id', id);
      });

  @override
  Future<void> restore(int id) => guardSupabase(() async {
        await _db.from('tags').update({'deleted_at': null}).eq('id', id);
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
}
