import 'package:shared_preferences/shared_preferences.dart';

import '../data/seed_tags.dart';
import '../models/fund_tag.dart';
import '../models/page_result.dart';
import '../models/simple_list_query.dart';
import 'persistence/json_list_storage.dart';
import 'tag_repository.dart';

class PersistentTagRepository implements TagRepository {
  PersistentTagRepository(
    SharedPreferences prefs, {
    void Function(String message)? onStorageReset,
  }) : _storage = JsonListStorage<FundTag>(
         prefs: prefs,
         storageKey: 'tags_v1',
         fromJson: FundTag.fromJson,
         toJson: (t) => t.toJson(),
         seed: buildSeedTags,
         onReset: onStorageReset,
       ) {
    _items = _storage.load();
    _nextId = _items.isEmpty
        ? 1
        : _items.map((t) => t.id).reduce((a, b) => a > b ? a : b) + 1;
  }

  final JsonListStorage<FundTag> _storage;
  late List<FundTag> _items;
  late int _nextId;

  Future<void> _save() => _storage.persist(_items);

  @override
  Future<PageResult<FundTag>> find(SimpleListQuery q) async {
    await Future.delayed(const Duration(milliseconds: 200));
    var rows = _items.where((t) => q.includeDeleted || !t.isDeleted).toList();
    if (q.search.trim().isNotEmpty) {
      final needle = q.search.trim().toLowerCase();
      rows = rows.where((t) => t.name.toLowerCase().contains(needle)).toList();
    }
    if (q.categoryId != null) {
      rows = rows.where((t) => t.categoryId == q.categoryId).toList();
    }
    rows.sort((a, b) {
      final result = switch (q.sortField) {
        'categoryId' => a.categoryId.compareTo(b.categoryId),
        _ => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
      };
      return q.sortAscending ? result : -result;
    });
    final total = rows.length;
    final from = (q.page - 1) * q.size;
    final to = (from + q.size) > total ? total : (from + q.size);
    final items = from >= total ? <FundTag>[] : rows.sublist(from, to);
    return PageResult(items: items, page: q.page, size: q.size, total: total);
  }

  @override
  Future<FundTag?> findById(int id) async {
    try {
      return _items.firstWhere((t) => t.id == id);
    } on StateError {
      return null;
    }
  }

  @override
  Future<List<FundTag>> listForSelect({int? categoryId}) async {
    var tags = _items.where((t) => !t.isDeleted).toList();
    if (categoryId != null) {
      tags = tags.where((t) => t.categoryId == categoryId).toList();
    }
    tags.sort((a, b) => a.name.compareTo(b.name));
    return tags;
  }

  @override
  Future<FundTag> create(FundTag item) async {
    final created = FundTag(
      id: _nextId++,
      name: item.name,
      categoryId: item.categoryId,
    );
    _items.add(created);
    await _save();
    return created;
  }

  @override
  Future<FundTag> update(FundTag item) async {
    final i = _items.indexWhere((t) => t.id == item.id);
    if (i == -1) throw StateError('Тег ${item.id} не найден');
    _items[i] = item;
    await _save();
    return item;
  }

  @override
  Future<void> softDelete(int id) async {
    final i = _items.indexWhere((t) => t.id == id);
    if (i == -1) throw StateError('Тег $id не найден');
    _items[i] = _items[i].copyWith(deletedAt: DateTime.now());
    await _save();
  }

  @override
  Future<void> hardDelete(int id) async {
    _items.removeWhere((t) => t.id == id);
    await _save();
  }

  @override
  Future<void> restore(int id) async {
    final i = _items.indexWhere((t) => t.id == id);
    if (i == -1) throw StateError('Тег $id не найден');
    _items[i] = _items[i].copyWith(clearDeletedAt: true);
    await _save();
  }

  @override
  Future<int> deleteMany(List<int> ids) async {
    var count = 0;
    for (final id in ids) {
      final i = _items.indexWhere((t) => t.id == id && !t.isDeleted);
      if (i != -1) {
        _items[i] = _items[i].copyWith(deletedAt: DateTime.now());
        count++;
      }
    }
    if (count > 0) await _save();
    return count;
  }
}
