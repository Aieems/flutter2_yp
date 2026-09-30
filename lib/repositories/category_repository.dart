import '../models/fund_category.dart';
import '../models/page_result.dart';
import '../models/simple_list_query.dart';

abstract interface class CategoryRepository {
  Future<PageResult<FundCategory>> find(SimpleListQuery query);
  Future<FundCategory?> findById(int id);
  Future<FundCategory?> findByName(String name);
  Future<bool> isNameTaken(String name, {int? excludeId});
  Future<List<FundCategory>> listForSelect();
  Future<FundCategory> create(FundCategory item);
  Future<FundCategory> update(FundCategory item);
  Future<void> softDelete(int id);
  Future<void> hardDelete(int id);
  Future<void> restore(int id);
  Future<int> deleteMany(List<int> ids);
  Future<int> countLinkedProjects(int categoryId);
}
