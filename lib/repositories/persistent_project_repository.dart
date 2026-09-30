import 'package:shared_preferences/shared_preferences.dart';

import '../data/seed_projects.dart';
import '../utils/text_normalize.dart';
import '../models/page_result.dart';
import '../models/project.dart';
import '../models/project_query.dart';
import 'persistence/json_list_storage.dart';
import 'project_repository.dart';

class PersistentProjectRepository implements ProjectRepository {
  PersistentProjectRepository(
    SharedPreferences prefs, {
    void Function(String message)? onStorageReset,
  }) : _storage = JsonListStorage<Project>(
          prefs: prefs,
          storageKey: 'projects_v1',
          fromJson: Project.fromJson,
          toJson: (p) => p.toJson(),
          seed: () => [...seedProjects],
          onReset: onStorageReset,
        ) {
    _items = _storage.load();
    _nextId = _items.isEmpty
        ? 1
        : _items.map((p) => p.id).reduce((a, b) => a > b ? a : b) + 1;
  }

  final JsonListStorage<Project> _storage;
  late List<Project> _items;
  late int _nextId;

  Future<void> _save() => _storage.persist(_items);

  void _refreshItemsFromPrefs() {
    final decoded = _storage.decodeFromPrefs();
    if (decoded == null) return;
    _items = decoded;
    final maxId = _items.isEmpty
        ? 0
        : _items.map((p) => p.id).reduce((a, b) => a > b ? a : b);
    if (_nextId <= maxId) _nextId = maxId + 1;
  }

  @override
  Future<PageResult<Project>> find(ProjectQuery q) async {
    await Future.delayed(const Duration(milliseconds: 250));
    var rows = _items.where((p) => q.includeDeleted || !p.isDeleted).toList();
    if (q.search.trim() == '!!!error') {
      throw StateError('Демонстрация ошибки загрузки');
    }
    if (q.search.trim().isNotEmpty) {
      final needle = q.search.trim().toLowerCase();
      rows = rows
          .where(
            (p) =>
                p.title.toLowerCase().contains(needle) ||
                p.code.toLowerCase().contains(needle),
          )
          .toList();
    }
    if (q.tagId != null) {
      rows = rows.where((p) => p.tagIds.contains(q.tagId)).toList();
    }
    if (q.categoryId != null) {
      rows = rows.where((p) => p.categoryId == q.categoryId).toList();
    }
    if (q.yearFrom != null) {
      rows = rows.where((p) => p.year >= q.yearFrom!).toList();
    }
    if (q.yearTo != null) {
      rows = rows.where((p) => p.year <= q.yearTo!).toList();
    }
    rows.sort((a, b) {
      final result = switch (q.sortField) {
        'year' => a.year.compareTo(b.year),
        'goalAmount' => a.goalAmount.compareTo(b.goalAmount),
        _ => a.title.toLowerCase().compareTo(b.title.toLowerCase()),
      };
      return q.sortAscending ? result : -result;
    });
    final total = rows.length;
    final from = (q.page - 1) * q.size;
    final to = (from + q.size) > total ? total : (from + q.size);
    final items = from >= total ? <Project>[] : rows.sublist(from, to);
    return PageResult(
      items: items,
      page: q.page,
      size: q.size,
      total: total,
    );
  }

  @override
  Future<Project?> findById(int id) async {
    await Future.delayed(const Duration(milliseconds: 100));
    _refreshItemsFromPrefs();
    try {
      return _items.firstWhere((p) => p.id == id);
    } on StateError {
      return null;
    }
  }

  @override
  Future<Project?> findByCode(String code) async {
    _refreshItemsFromPrefs();
    final normalized = normalizeKey(code);
    if (normalized.isEmpty) return null;
    for (final p in _items) {
      if (normalizeKey(p.code) == normalized) return p;
    }
    return null;
  }

  @override
  Future<Project> create(Project project) async {
    _refreshItemsFromPrefs();
    if (await isCodeTaken(project.code)) {
      throw StateError(
        'ISBN (код проекта) «${project.code.trim()}» уже используется',
      );
    }
    final created = Project(
      id: _nextId++,
      title: project.title,
      code: project.code,
      year: project.year,
      goalAmount: project.goalAmount,
      categoryId: project.categoryId,
      partnerIds: project.partnerIds,
      tagIds: project.tagIds,
      volunteersTotal: project.volunteersTotal,
      volunteersActive: project.volunteersActive,
    );
    _items.add(created);
    await _save();
    return created;
  }

  @override
  Future<Project> update(Project project) async {
    _refreshItemsFromPrefs();
    final i = _items.indexWhere((p) => p.id == project.id);
    if (i == -1) throw StateError('Проект ${project.id} не найден');
    if (await isCodeTaken(project.code, excludeId: project.id)) {
      throw StateError(
        'ISBN (код проекта) «${project.code.trim()}» уже используется',
      );
    }
    _items[i] = project;
    await _save();
    return project;
  }

  @override
  Future<void> softDelete(int id) async {
    final i = _items.indexWhere((p) => p.id == id);
    if (i == -1) throw StateError('Проект $id не найден');
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
    if (i == -1) throw StateError('Проект $id не найден');
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
  Future<bool> isCodeTaken(String code, {int? excludeId}) async {
    _refreshItemsFromPrefs();
    final normalized = normalizeKey(code);
    if (normalized.isEmpty) return false;
    return _items.any(
      (p) =>
          normalizeKey(p.code) == normalized &&
          (excludeId == null || p.id != excludeId),
    );
  }

  @override
  Future<int> countByCategoryId(int categoryId) async {
    return _items
        .where((p) => p.categoryId == categoryId && !p.isDeleted)
        .length;
  }

  @override
  Future<List<Project>> listAll({bool includeDeleted = false}) async {
    return _items.where((p) => includeDeleted || !p.isDeleted).toList();
  }
}
