import 'package:flutter/foundation.dart';

import '../models/page_result.dart';
import '../models/project.dart';
import '../models/project_query.dart';
import '../repositories/project_repository.dart';
import 'load_status.dart';

class ProjectListNotifier extends ChangeNotifier {
  ProjectListNotifier(this._repository);

  final ProjectRepository _repository;

  ProjectQuery _query = const ProjectQuery();
  PageResult<Project> _result = PageResult.empty();
  LoadStatus _status = LoadStatus.idle;
  String? _error;
  final Set<int> _selected = {};

  ProjectQuery get query => _query;
  PageResult<Project> get result => _result;
  LoadStatus get status => _status;
  String? get error => _error;
  Set<int> get selected => Set.unmodifiable(_selected);
  bool get hasSelection => _selected.isNotEmpty;

  Future<void> load() async {
    _status = LoadStatus.loading;
    _error = null;
    notifyListeners();
    try {
      _result = await _repository.find(_query);
      _status = LoadStatus.success;
    } catch (e) {
      _error = 'Не удалось загрузить список: $e';
      _status = LoadStatus.error;
    }
    notifyListeners();
  }

  Future<void> applyQuery(ProjectQuery next) async {
    _query = next;
    _selected.clear();
    await load();
  }

  void toggleSelection(int id) {
    if (_selected.contains(id)) {
      _selected.remove(id);
    } else {
      _selected.add(id);
    }
    notifyListeners();
  }

  Future<void> deleteSelected() async {
    await _repository.deleteMany(_selected.toList());
    _selected.clear();
    await load();
  }

  Future<void> softDeleteOne(int id) async {
    await _repository.softDelete(id);
    await load();
  }

  Future<void> hardDeleteOne(int id) async {
    await _repository.hardDelete(id);
    await load();
  }

  Future<void> restoreOne(int id) async {
    await _repository.restore(id);
    await load();
  }
}
