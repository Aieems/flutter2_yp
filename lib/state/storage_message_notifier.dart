import 'package:flutter/foundation.dart';

class StorageMessageNotifier extends ChangeNotifier {
  String? _message;

  String? get message => _message;

  void show(String text) {
    _message = text;
    notifyListeners();
  }

  void clear() {
    _message = null;
    notifyListeners();
  }
}
