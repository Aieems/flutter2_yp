import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/supabase_errors.dart';
import '../../models/page_result.dart';
import '../../models/simple_list_query.dart';
import '../../models/volunteer.dart';
import '../api/api_parsers.dart';
import '../volunteer_repository.dart';
import 'supabase_page.dart';
import 'supabase_row_mappers.dart';

class SupabaseVolunteerRepository implements VolunteerRepository {
  SupabaseClient get _db => Supabase.instance.client;

  Future<List<Volunteer>> _loadAll({bool includeDeleted = false}) =>
      guardSupabase(() async {
        final rows = await _db.from('volunteers').select();
        return rows
            .map((e) => volunteerFromApi(volunteerRowToApi(Map<String, dynamic>.from(e as Map))))
            .where((v) => includeDeleted || !v.isDeleted)
            .toList();
      });

  List<Volunteer> _filterSort(List<Volunteer> rows, SimpleListQuery q) {
    var list = rows;
    if (q.search.trim().isNotEmpty) {
      final n = q.search.trim().toLowerCase();
      list = list
          .where(
            (v) =>
                v.firstName.toLowerCase().contains(n) ||
                v.lastName.toLowerCase().contains(n) ||
                v.email.toLowerCase().contains(n),
          )
          .toList();
    }
    list.sort((a, b) => a.lastName.compareTo(b.lastName));
    return list;
  }

  @override
  Future<PageResult<Volunteer>> find(SimpleListQuery q) async {
    final all = await _loadAll(includeDeleted: q.includeDeleted);
    return paginateInMemory(
      all: _filterSort(all, q),
      page: q.page,
      size: q.size,
    );
  }

  @override
  Future<Volunteer?> findById(int id) => guardSupabase(() async {
        final row = await _db.from('volunteers').select().eq('id', id).maybeSingle();
        if (row == null) return null;
        return volunteerFromApi(volunteerRowToApi(Map<String, dynamic>.from(row)));
      });

  @override
  Future<Volunteer> create(Volunteer volunteer) => guardSupabase(() async {
        final row = await _db
            .from('volunteers')
            .insert({
              'first_name': volunteer.firstName,
              'last_name': volunteer.lastName,
              'email': volunteer.email,
              'card_number': volunteer.card.cardNumber,
              'card_issued_at': volunteer.card.issuedAt.toIso8601String(),
              'card_expires_at': volunteer.card.expiresAt.toIso8601String(),
            })
            .select()
            .single();
        return volunteerFromApi(volunteerRowToApi(Map<String, dynamic>.from(row)));
      });

  @override
  Future<Volunteer> update(Volunteer volunteer) => guardSupabase(() async {
        final row = await _db
            .from('volunteers')
            .update({
              'first_name': volunteer.firstName,
              'last_name': volunteer.lastName,
              'email': volunteer.email,
              'card_number': volunteer.card.cardNumber,
              'card_issued_at': volunteer.card.issuedAt.toIso8601String(),
              'card_expires_at': volunteer.card.expiresAt.toIso8601String(),
            })
            .eq('id', volunteer.id)
            .select()
            .single();
        return volunteerFromApi(volunteerRowToApi(Map<String, dynamic>.from(row)));
      });

  @override
  Future<void> softDelete(int id) => guardSupabase(() async {
        await _db
            .from('volunteers')
            .update({'deleted_at': DateTime.now().toUtc().toIso8601String()})
            .eq('id', id);
      });

  @override
  Future<void> hardDelete(int id) => guardSupabase(() async {
        await _db.from('volunteers').delete().eq('id', id);
      });

  @override
  Future<void> restore(int id) => guardSupabase(() async {
        await _db.from('volunteers').update({'deleted_at': null}).eq('id', id);
      });

  @override
  Future<bool> isEmailTaken(String email, {int? excludeId}) async {
    final all = await _loadAll();
    final key = email.trim().toLowerCase();
    for (final v in all) {
      if (v.email.toLowerCase() == key) {
        if (excludeId == null || v.id != excludeId) return true;
      }
    }
    return false;
  }

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
