import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/seed_partners.dart';
import '../models/page_result.dart';
import '../models/partner.dart';
import '../models/partner_query.dart';
import '../models/project.dart';
import 'partner_repository.dart';
import 'persistence/json_list_storage.dart';
import 'project_repository.dart';

class PersistentPartnerRepository implements PartnerRepository {
  PersistentPartnerRepository(
    SharedPreferences prefs,
    this._projects, {
    void Function(String message)? onStorageReset,
  }) : _storage = JsonListStorage<Partner>(
          prefs: prefs,
          storageKey: 'partners_v1',
          fromJson: Partner.fromJson,
          toJson: (p) => p.toJson(),
          seed: () => [...seedPartners],
          onReset: onStorageReset,
        ) {
    _items = _storage.load();
    _nextId = _items.isEmpty
        ? 1
        : _items.map((p) => p.id).reduce((a, b) => a > b ? a : b) + 1;
  }

  final JsonListStorage<Partner> _storage;
  final ProjectRepository _projects;
  late List<Partner> _items;
  late int _nextId;

  Future<void> _save() => _storage.persist(_items);

  @override
  Future<PageResult<Partner>> find(
    PartnerQuery q, {
    CancelToken? cancelToken,
  }) async {
    await Future.delayed(const Duration(milliseconds: 250));
    var rows = _items.where((p) => q.includeDeleted || !p.isDeleted).toList();
    if (q.search.trim().isNotEmpty) {
      final needle = q.search.trim().toLowerCase();
      rows = rows
          .where(
            (p) =>
                p.lastName.toLowerCase().contains(needle) ||
                p.country.toLowerCase().contains(needle),
          )
          .toList();
    }
    rows.sort((a, b) {
      final result = switch (q.sortField) {
        'country' => a.country.toLowerCase().compareTo(b.country.toLowerCase()),
        'birthYear' => a.birthYear.compareTo(b.birthYear),
        _ => a.lastName.toLowerCase().compareTo(b.lastName.toLowerCase()),
      };
      return q.sortAscending ? result : -result;
    });
    final total = rows.length;
    final from = (q.page - 1) * q.size;
    final to = (from + q.size) > total ? total : (from + q.size);
    final items = from >= total ? <Partner>[] : rows.sublist(from, to);
    return PageResult(
      items: items,
      page: q.page,
      size: q.size,
      total: total,
    );
  }

  @override
  Future<Partner?> findById(int id) async {
    try {
      return _items.firstWhere((p) => p.id == id);
    } on StateError {
      return null;
    }
  }

  @override
  Future<Partner> create(Partner partner) async {
    final created = Partner(
      id: _nextId++,
      lastName: partner.lastName,
      firstName: partner.firstName,
      country: partner.country,
      birthYear: partner.birthYear,
    );
    _items.add(created);
    await _save();
    return created;
  }

  @override
  Future<Partner> update(Partner partner) async {
    final i = _items.indexWhere((p) => p.id == partner.id);
    if (i == -1) throw StateError('Партнёр ${partner.id} не найден');
    _items[i] = partner;
    await _save();
    return partner;
  }

  @override
  Future<void> softDelete(int id) async {
    final i = _items.indexWhere((p) => p.id == id);
    if (i == -1) throw StateError('Партнёр $id не найден');
    _items[i] = _items[i].copyWith(deletedAt: DateTime.now());
    await _save();
  }

  @override
  Future<void> hardDelete(int id) async {
    _items.removeWhere((p) => p.id == id);
    await _save();
  }

  @override
  Future<void> restore(int id) async {
    final i = _items.indexWhere((p) => p.id == id);
    if (i == -1) throw StateError('Партнёр $id не найден');
    _items[i] = _items[i].copyWith(clearDeletedAt: true);
    await _save();
  }

  @override
  Future<int> deleteMany(List<int> ids) async {
    var count = 0;
    for (final id in ids) {
      final i = _items.indexWhere((p) => p.id == id && !p.isDeleted);
      if (i != -1) {
        _items[i] = _items[i].copyWith(deletedAt: DateTime.now());
        count++;
      }
    }
    if (count > 0) await _save();
    return count;
  }

  @override
  Future<List<Partner>> listForSelect({int? categoryId}) async {
    var partners = _items.where((p) => !p.isDeleted).toList();
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
    partners.sort(
      (a, b) => a.lastName.toLowerCase().compareTo(b.lastName.toLowerCase()),
    );
    return partners;
  }
}
