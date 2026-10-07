import 'package:shared_preferences/shared_preferences.dart';

import '../data/seed_categories.dart';
import '../utils/text_normalize.dart';
import '../models/fund_category.dart';
import '../models/page_result.dart';
import '../models/simple_list_query.dart';
import 'category_repository.dart';
import 'persistence/json_list_storage.dart';
import 'project_repository.dart';

class PersistentCategoryRepository implements CategoryRepository {
  PersistentCategoryRepository(
    SharedPreferences prefs,
    this._projects, {
    void Function(String message)? onStorageReset,
  }) : _storage = JsonListStorage<FundCategory>(
         prefs: prefs,
         storageKey: 'categories_v1',
         fromJson: FundCategory.fromJson,
         toJson: (c) => c.toJson(),
         seed: buildSeedCategories,
         onReset: onStorageReset,
       ) {
    _items = _storage.load();
    _nextId = _items.isEmpty
        ? 1
        : _items.map((c) => c.id).reduce((a, b) => a > b ? a : b) + 1;
  }

  final JsonListStorage<FundCategory> _storage;
  final ProjectRepository _projects;
  late List<FundCategory> _items;
  late int _nextId;

  Future<void> _save() => _storage.persist(_items);

  void _refreshItemsFromPrefs() {
    final decoded = _storage.decodeFromPrefs();
    if (decoded == null) return;
    _items = decoded;
    final maxId = _items.isEmpty
        ? 0
        : _items.map((c) => c.id).reduce((a, b) => a > b ? a : b);
    if (_nextId <= maxId) _nextId = maxId + 1;
  }

  @override
  Future<PageResult<FundCategory>> find(SimpleListQuery q) async {
    await Future.delayed(const Duration(milliseconds: 200));
    var rows = _items.where((c) => q.includeDeleted || !c.isDeleted).toList();
    if (q.search.trim().isNotEmpty) {
      final needle = q.search.trim().toLowerCase();
      rows = rows.where((c) => c.name.toLowerCase().contains(needle)).toList();
    }
    rows.sort((a, b) {
      final result = a.name.toLowerCase().compareTo(b.name.toLowerCase());
      return q.sortAscending ? result : -result;
    });
    final total = rows.length;
    final from = (q.page - 1) * q.size;
    final to = (from + q.size) > total ? total : (from + q.size);
    final items = from >= total ? <FundCategory>[] : rows.sublist(from, to);
    return PageResult(items: items, page: q.page, size: q.size, total: total);
  }

  @override
  Future<FundCategory?> findById(int id) async {
    _refreshItemsFromPrefs();
    try {
      return _items.firstWhere((c) => c.id == id);
    } on StateError {
      return null;
    }
  }

  @override
  Future<FundCategory?> findByName(String name) async {
    _refreshItemsFromPrefs();
    final key = normalizeName(name);
    if (key.isEmpty) return null;
    for (final c in _items) {
      if (c.isDeleted) continue;
      if (normalizeName(c.name) == key) return c;
    }
    return null;
  }

  @override
  Future<bool> isNameTaken(String name, {int? excludeId}) async {
    _refreshItemsFromPrefs();
    final key = normalizeName(name);
    if (key.isEmpty) return false;
    return _items.any(
      (c) =>
          !c.isDeleted &&
          normalizeName(c.name) == key &&
          (excludeId == null || c.id != excludeId),
    );
  }

  @override
  Future<List<FundCategory>> listForSelect() async {
    return _items.where((c) => !c.isDeleted).toList()
      ..sort((a, b) => a.name.compareTo(b.name));
  }

  @override
  Future<FundCategory> create(FundCategory item) async {
    _refreshItemsFromPrefs();
    if (await isNameTaken(item.name)) {
      throw StateError('Направление «${item.name.trim()}» уже существует');
    }
    final created = FundCategory(id: _nextId++, name: item.name.trim());
    _items.add(created);
    await _save();
    return created;
  }

  @override
  Future<FundCategory> update(FundCategory item) async {
    _refreshItemsFromPrefs();
    final i = _items.indexWhere((c) => c.id == item.id);
    if (i == -1) throw StateError('Направление ${item.id} не найдено');
    if (await isNameTaken(item.name, excludeId: item.id)) {
      throw StateError('Направление «${item.name.trim()}» уже существует');
    }
    _items[i] = item.copyWith(name: item.name.trim());
    await _save();
    return item;
  }

  @override
  Future<void> softDelete(int id) async {
    final linked = await countLinkedProjects(id);
    if (linked > 0) {
      throw StateError(
        'Нельзя удалить: к направлению привязано проектов: $linked',
      );
    }
    final i = _items.indexWhere((c) => c.id == id);
    if (i == -1) throw StateError('Направление $id не найдено');
    _items[i] = _items[i].copyWith(deletedAt: DateTime.now());
    await _save();
  }

  @override
  Future<void> hardDelete(int id) async {
    final linked = await countLinkedProjects(id);
    if (linked > 0) {
      throw StateError(
        'Нельзя удалить: к направлению привязано проектов: $linked',
      );
    }
    _items.removeWhere((c) => c.id == id);
    await _save();
  }

  @override
  Future<void> restore(int id) async {
    final i = _items.indexWhere((c) => c.id == id);
    if (i == -1) throw StateError('Направление $id не найдено');
    _items[i] = _items[i].copyWith(clearDeletedAt: true);
    await _save();
  }

  @override
  Future<int> deleteMany(List<int> ids) async {
    var count = 0;
    for (final id in ids) {
      try {
        await softDelete(id);
        count++;
      } on StateError {
        // пропускаем заблокированные
      }
    }
    return count;
  }

  @override
  Future<int> countLinkedProjects(int categoryId) async {
    return _projects.countByCategoryId(categoryId);
  }
}
