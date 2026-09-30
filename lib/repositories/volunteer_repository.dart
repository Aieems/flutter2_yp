import '../models/page_result.dart';
import '../models/simple_list_query.dart';
import '../models/volunteer.dart';

abstract interface class VolunteerRepository {
  Future<PageResult<Volunteer>> find(SimpleListQuery query);
  Future<Volunteer?> findById(int id);
  Future<Volunteer> create(Volunteer item);
  Future<Volunteer> update(Volunteer item);
  Future<void> softDelete(int id);
  Future<void> hardDelete(int id);
  Future<void> restore(int id);
  Future<int> deleteMany(List<int> ids);
  Future<bool> isEmailTaken(String email, {int? excludeId});
}
