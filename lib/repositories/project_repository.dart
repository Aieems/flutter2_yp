import '../models/page_result.dart';
import '../models/project.dart';
import '../models/project_query.dart';

abstract interface class ProjectRepository {
  Future<PageResult<Project>> find(ProjectQuery query);
  Future<Project?> findById(int id);
  Future<Project> create(Project project);
  Future<Project> update(Project project);
  Future<void> softDelete(int id);
  Future<void> hardDelete(int id);
  Future<void> restore(int id);
  Future<int> deleteMany(List<int> ids);
}
