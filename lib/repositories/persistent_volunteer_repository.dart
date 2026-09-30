import 'package:shared_preferences/shared_preferences.dart';

import '../data/seed_volunteers.dart';
import '../utils/text_normalize.dart';
import '../models/page_result.dart';
import '../models/simple_list_query.dart';
import '../models/volunteer.dart';
import 'persistence/json_list_storage.dart';
import 'volunteer_repository.dart';

class PersistentVolunteerRepository implements VolunteerRepository {
  PersistentVolunteerRepository(
    SharedPreferences prefs, {
    void Function(String message)? onStorageReset,
  }) : _storage = JsonListStorage<Volunteer>(
          prefs: prefs,
          storageKey: 'volunteers_v1',
          fromJson: Volunteer.fromJson,
          toJson: (v) => v.toJson(),
          seed: buildSeedVolunteers,
          onReset: onStorageReset,
        ) {
    _items = _storage.load();
    _nextId = _items.isEmpty
        ? 1
        : _items.map((v) => v.id).reduce((a, b) => a > b ? a : b) + 1;
  }

  final JsonListStorage<Volunteer> _storage;
  late List<Volunteer> _items;
  late int _nextId;

  Future<void> _save() => _storage.persist(_items);

  @override
  Future<PageResult<Volunteer>> find(SimpleListQuery q) async {
    await Future.delayed(const Duration(milliseconds: 200));
    var rows = _items.where((v) => q.includeDeleted || !v.isDeleted).toList();
    if (q.search.trim().isNotEmpty) {
      final needle = q.search.trim().toLowerCase();
      rows = rows
          .where(
            (v) =>
                v.lastName.toLowerCase().contains(needle) ||
                v.email.toLowerCase().contains(needle),
          )
          .toList();
    }
    rows.sort((a, b) {
      final result = switch (q.sortField) {
        'email' => a.email.toLowerCase().compareTo(b.email.toLowerCase()),
        'firstName' =>
          a.firstName.toLowerCase().compareTo(b.firstName.toLowerCase()),
        _ => a.lastName.toLowerCase().compareTo(b.lastName.toLowerCase()),
      };
      return q.sortAscending ? result : -result;
    });
    final total = rows.length;
    final from = (q.page - 1) * q.size;
    final to = (from + q.size) > total ? total : (from + q.size);
    final items = from >= total ? <Volunteer>[] : rows.sublist(from, to);
    return PageResult(
      items: items,
      page: q.page,
      size: q.size,
      total: total,
    );
  }

  @override
  Future<Volunteer?> findById(int id) async {
    try {
      return _items.firstWhere((v) => v.id == id);
    } on StateError {
      return null;
    }
  }

  @override
  Future<Volunteer> create(Volunteer item) async {
    if (await isEmailTaken(item.email)) {
      throw StateError('Email «${item.email.trim()}» уже зарегистрирован');
    }
    final created = Volunteer(
      id: _nextId++,
      firstName: item.firstName,
      lastName: item.lastName,
      email: item.email,
      card: item.card,
    );
    _items.add(created);
    await _save();
    return created;
  }

  @override
  Future<Volunteer> update(Volunteer item) async {
    final i = _items.indexWhere((v) => v.id == item.id);
    if (i == -1) throw StateError('Волонтёр ${item.id} не найден');
    if (await isEmailTaken(item.email, excludeId: item.id)) {
      throw StateError('Email «${item.email.trim()}» уже зарегистрирован');
    }
    _items[i] = item;
    await _save();
    return item;
  }

  @override
  Future<void> softDelete(int id) async {
    final i = _items.indexWhere((v) => v.id == id);
    if (i == -1) throw StateError('Волонтёр $id не найден');
    _items[i] = _items[i].copyWith(deletedAt: DateTime.now());
    await _save();
  }

  @override
  Future<void> hardDelete(int id) async {
    _items.removeWhere((v) => v.id == id);
    await _save();
  }

  @override
  Future<void> restore(int id) async {
    final i = _items.indexWhere((v) => v.id == id);
    if (i == -1) throw StateError('Волонтёр $id не найден');
    _items[i] = _items[i].copyWith(clearDeletedAt: true);
    await _save();
  }

  @override
  Future<int> deleteMany(List<int> ids) async {
    var count = 0;
    for (final id in ids) {
      final i = _items.indexWhere((v) => v.id == id && !v.isDeleted);
      if (i != -1) {
        _items[i] = _items[i].copyWith(deletedAt: DateTime.now());
        count++;
      }
    }
    if (count > 0) await _save();
    return count;
  }

  @override
  Future<bool> isEmailTaken(String email, {int? excludeId}) async {
    final normalized = normalizeKey(email);
    if (normalized.isEmpty) return false;
    return _items.any(
      (v) =>
          normalizeKey(v.email) == normalized &&
          (excludeId == null || v.id != excludeId),
    );
  }
}
