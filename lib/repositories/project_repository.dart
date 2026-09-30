import '../models/page_result.dart';
import '../models/project.dart';
import '../models/project_query.dart';

abstract interface class ProjectRepository {
  Future<PageResult<Project>> find(ProjectQuery query);
  Future<Project?> findById(int id);
  Future<Project?> findByCode(String code);
  Future<Project> create(Project project);
  Future<Project> update(Project project);
  Future<void> softDelete(int id);
  Future<void> hardDelete(int id);
  Future<void> restore(int id);
  Future<int> deleteMany(List<int> ids);
  Future<bool> isCodeTaken(String code, {int? excludeId});
  Future<int> countByCategoryId(int categoryId);
  Future<List<Project>> listAll({bool includeDeleted = false});
}
