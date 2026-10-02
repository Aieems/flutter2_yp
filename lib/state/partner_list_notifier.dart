import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../core/api_exceptions.dart';
import '../models/page_result.dart';
import '../models/partner.dart';
import '../models/partner_query.dart';
import '../repositories/partner_repository.dart';
import 'load_status.dart';

class PartnerListNotifier extends ChangeNotifier {
  PartnerListNotifier(this._repository);

  final PartnerRepository _repository;

  PartnerQuery _query = const PartnerQuery();
  PageResult<Partner> _result = PageResult.empty();
  LoadStatus _status = LoadStatus.idle;
  String? _error;
  final Set<int> _selected = {};
  CancelToken? _loadToken;

  PartnerQuery get query => _query;
  PageResult<Partner> get result => _result;
  LoadStatus get status => _status;
  String? get error => _error;
  Set<int> get selected => Set.unmodifiable(_selected);
  bool get hasSelection => _selected.isNotEmpty;

  Future<void> load() async {
    _loadToken?.cancel('новый запрос');
    final token = CancelToken();
    _loadToken = token;

    _status = LoadStatus.loading;
    _error = null;
    notifyListeners();
    try {
      _result = await _repository.find(_query, cancelToken: token);
      if (token.isCancelled) return;
      _status = LoadStatus.success;
    } catch (e) {
      if (isCancelledError(e) || token.isCancelled) return;
      _error = e is ApiException
          ? e.message
          : 'Не удалось загрузить список: $e';
      _status = LoadStatus.error;
    }
    notifyListeners();
  }

  Future<void> applyQuery(PartnerQuery next) async {
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
