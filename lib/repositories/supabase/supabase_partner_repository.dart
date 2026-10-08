import 'package:dio/dio.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/api_exceptions.dart';
import '../../core/supabase_errors.dart';
import '../../models/page_result.dart';
import '../../models/partner.dart';
import '../../models/partner_query.dart';
import '../api/api_parsers.dart';
import '../partner_repository.dart';
import 'supabase_page.dart';
import 'supabase_row_mappers.dart';

class SupabasePartnerRepository implements PartnerRepository {
  SupabaseClient get _db => Supabase.instance.client;

  Future<List<Partner>> _loadAll({bool includeDeleted = false}) =>
      guardSupabase(() async {
        final rows = await _db.from('partners').select();
        return rows
            .map((e) => partnerFromApi(partnerRowToApi(Map<String, dynamic>.from(e as Map))))
            .where((p) => includeDeleted || !p.isDeleted)
            .toList();
      });

  List<Partner> _filterSort(List<Partner> rows, PartnerQuery q) {
    var list = rows;
    if (q.search.trim().isNotEmpty) {
      final n = q.search.trim().toLowerCase();
      list = list
          .where(
            (p) =>
                p.lastName.toLowerCase().contains(n) ||
                p.firstName.toLowerCase().contains(n) ||
                p.country.toLowerCase().contains(n),
          )
          .toList();
    }
    list.sort((a, b) {
      final cmp = a.lastName.compareTo(b.lastName);
      return q.sortAscending ? cmp : -cmp;
    });
    return list;
  }

  @override
  Future<PageResult<Partner>> find(
    PartnerQuery query, {
    CancelToken? cancelToken,
  }) async {
    if (cancelToken?.isCancelled == true) {
      throw const RequestCancelledException();
    }
    final all = await _loadAll(includeDeleted: query.includeDeleted);
    return paginateInMemory(
      all: _filterSort(all, query),
      page: query.page,
      size: query.size,
    );
  }

  @override
  Future<Partner?> findById(int id) => guardSupabase(() async {
        final row = await _db.from('partners').select().eq('id', id).maybeSingle();
        if (row == null) return null;
        return partnerFromApi(partnerRowToApi(Map<String, dynamic>.from(row)));
      });

  @override
  Future<Partner> create(Partner partner) => guardSupabase(() async {
        final row = await _db
            .from('partners')
            .insert({
              'last_name': partner.lastName,
              'first_name': partner.firstName,
              'country': partner.country,
              'birth_year': partner.birthYear,
            })
            .select()
            .single();
        return partnerFromApi(partnerRowToApi(Map<String, dynamic>.from(row)));
      });

  @override
  Future<Partner> update(Partner partner) => guardSupabase(() async {
        final row = await _db
            .from('partners')
            .update({
              'last_name': partner.lastName,
              'first_name': partner.firstName,
              'country': partner.country,
              'birth_year': partner.birthYear,
            })
            .eq('id', partner.id)
            .select()
            .single();
        return partnerFromApi(partnerRowToApi(Map<String, dynamic>.from(row)));
      });

  @override
  Future<void> softDelete(int id) => guardSupabase(() async {
        await _db
            .from('partners')
            .update({'deleted_at': DateTime.now().toUtc().toIso8601String()})
            .eq('id', id);
      });

  @override
  Future<void> hardDelete(int id) => guardSupabase(() async {
        await _db.from('partners').delete().eq('id', id);
      });

  @override
  Future<void> restore(int id) => guardSupabase(() async {
        await _db.from('partners').update({'deleted_at': null}).eq('id', id);
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
  Future<List<Partner>> listForSelect({int? categoryId}) async {
    final all = await _loadAll();
    all.sort((a, b) => a.displayName.compareTo(b.displayName));
    return all;
  }
}
