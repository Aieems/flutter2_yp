import 'package:dio/dio.dart';

import '../models/page_result.dart';
import '../models/partner.dart';
import '../models/partner_query.dart';

abstract interface class PartnerRepository {
  Future<PageResult<Partner>> find(
    PartnerQuery query, {
    CancelToken? cancelToken,
  });
  Future<Partner?> findById(int id);
  Future<Partner> create(Partner partner);
  Future<Partner> update(Partner partner);
  Future<void> softDelete(int id);
  Future<void> hardDelete(int id);
  Future<void> restore(int id);
  Future<int> deleteMany(List<int> ids);
  Future<List<Partner>> listForSelect({int? categoryId});
}
