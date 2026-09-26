import '../data/seed_projects.dart';
import '../models/page_result.dart';
import '../models/project.dart';
import '../models/project_query.dart';
import 'project_repository.dart';

class InMemoryProjectRepository implements ProjectRepository {
  final List<Project> _projects = [...seedProjects];
  int _nextId = seedProjects.length + 1;

  @override
  Future<PageResult<Project>> find(ProjectQuery q) async {
    await Future.delayed(const Duration(milliseconds: 250));
    var rows =
        _projects.where((p) => q.includeDeleted || !p.isDeleted).toList();
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
    try {
      return _projects.firstWhere((p) => p.id == id);
    } on StateError {
      return null;
    }
  }

  @override
  Future<Project> create(Project project) async {
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
    _projects.add(created);
    return created;
  }

  @override
  Future<Project> update(Project project) async {
    final i = _projects.indexWhere((p) => p.id == project.id);
    if (i == -1) throw StateError('Проект ${project.id} не найден');
    _projects[i] = project;
    return project;
  }

  @override
  Future<void> softDelete(int id) async {
    final i = _projects.indexWhere((p) => p.id == id);
    if (i == -1) throw StateError('Проект $id не найден');
    _projects[i] = _projects[i].copyWith(deletedAt: DateTime.now());
  }

  @override
  Future<void> hardDelete(int id) async {
    _projects.removeWhere((p) => p.id == id);
  }

  @override
  Future<void> restore(int id) async {
    final i = _projects.indexWhere((p) => p.id == id);
    if (i == -1) throw StateError('Проект $id не найден');
    _projects[i] = _projects[i].copyWith(clearDeletedAt: true);
  }

  @override
  Future<int> deleteMany(List<int> ids) async {
    var count = 0;
    for (final id in ids) {
      final i = _projects.indexWhere((p) => p.id == id && !p.isDeleted);
      if (i != -1) {
        _projects[i] = _projects[i].copyWith(deletedAt: DateTime.now());
        count++;
      }
    }
    return count;
  }
}
