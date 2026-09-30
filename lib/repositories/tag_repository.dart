import '../models/fund_tag.dart';
import '../models/page_result.dart';
import '../models/simple_list_query.dart';

abstract interface class TagRepository {
  Future<PageResult<FundTag>> find(SimpleListQuery query);
  Future<FundTag?> findById(int id);
  Future<List<FundTag>> listForSelect({int? categoryId});
  Future<FundTag> create(FundTag item);
  Future<FundTag> update(FundTag item);
  Future<void> softDelete(int id);
  Future<void> hardDelete(int id);
  Future<void> restore(int id);
  Future<int> deleteMany(List<int> ids);
}
