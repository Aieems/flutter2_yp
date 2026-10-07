import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

typedef FromJson<T> = T Function(Map<String, dynamic> json);
typedef ToJson<T> = Map<String, dynamic> Function(T item);

class JsonListStorage<T> {
  JsonListStorage({
    required SharedPreferences prefs,
    required this.storageKey,
    required this.fromJson,
    required this.toJson,
    required this.seed,
    this.onReset,
  }) : _prefs = prefs;

  final SharedPreferences _prefs;
  final String storageKey;
  final FromJson<T> fromJson;
  final ToJson<T> toJson;
  final List<T> Function() seed;
  final void Function(String message)? onReset;

  List<T> load() {
    final raw = _prefs.getString(storageKey);
    if (raw == null) {
      final initial = seed();
      persist(initial);
      return [...initial];
    }
    try {
      final list = jsonDecode(raw) as List;
      return list.map((e) => fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      final initial = seed();
      persist(initial);
      onReset?.call(
        'Данные $storageKey повреждены или устарели — загружен начальный набор.',
      );
      return [...initial];
    }
  }

  Future<void> persist(List<T> items) async {
    final encoded = jsonEncode(items.map(toJson).toList());
    await _prefs.setString(storageKey, encoded);
  }

  /// Reads the latest list from disk without seeding on empty key (for sync).
  List<T>? decodeFromPrefs() {
    final raw = _prefs.getString(storageKey);
    if (raw == null) return null;
    try {
      final list = jsonDecode(raw) as List;
      return list.map((e) => fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return null;
    }
  }
}
