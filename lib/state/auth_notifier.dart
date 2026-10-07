import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/api_exceptions.dart';
import '../core/auth_api.dart';
import '../core/local_auth_api.dart';
import '../models/app_role.dart';
import '../models/app_user.dart';

class AuthNotifier extends ChangeNotifier {
  static const kAccess = 'auth_access_token';
  static const kRefresh = 'auth_refresh_token';
  static const kSessionStarted = 'auth_session_started_ms';
  static const kLastActivity = 'auth_last_activity_ms';

  /// Снимок профиля для UI (роль на клиенте; сервер берёт роль из токена).
  static const kUiProfile = 'auth_ui_profile';

  AuthNotifier({
    required SharedPreferences prefs,
    AuthApi? authApi,
    LocalAuthApi? localAuthApi,
  }) : _prefs = prefs,
       _authApi = authApi,
       _localAuthApi = localAuthApi ?? LocalAuthApi();

  final SharedPreferences _prefs;
  final AuthApi? _authApi;
  final LocalAuthApi _localAuthApi;

  AppUser? _user;
  AppUser? _uiUser;
  String? _accessToken;
  bool _restoreDone = false;
  bool _refreshing = false;

  AppUser? get user => _uiUser ?? _user;
  String? get accessToken => _accessToken;
  bool get isAuthenticated => _user != null;
  bool get restoreDone => _restoreDone;

  bool has(AppRole role) {
    final u = user;
    return u != null && u.role.satisfies(role);
  }

  Duration get maxSessionDuration => const Duration(hours: 8);

  Future<void> restore() async {
    final access = _prefs.getString(kAccess);
    final refresh = _prefs.getString(kRefresh);
    if (access == null) {
      _restoreDone = true;
      notifyListeners();
      return;
    }
    _accessToken = access;
    if (await _sessionExpiredByMaxDuration()) {
      await logout();
      _restoreDone = true;
      notifyListeners();
      return;
    }
    try {
      _user = await _me();
      await _loadUiProfile();
      if (_uiUser == null && _user != null) {
        await _saveUiProfile(_user!);
      }
    } on UnauthorizedException {
      if (refresh != null) {
        try {
          await _refreshWith(refresh);
        } catch (_) {
          await logout();
        }
      } else {
        await logout();
      }
    } catch (_) {
      // Сервер недоступен — сессию не сбрасываем.
    }
    _restoreDone = true;
    notifyListeners();
  }

  Future<void> login(String username, String password) async {
    final result = _authApi != null
        ? await _authApi!.login(username, password)
        : await _localAuthApi.login(username, password);
    await _applyTokens(result);
  }

  Future<void> register({
    required String username,
    required String password,
    required String displayName,
  }) async {
    final result = _authApi != null
        ? await _authApi!.register(
            username: username,
            password: password,
            displayName: displayName,
          )
        : await _localAuthApi.register(
            username: username,
            password: password,
            displayName: displayName,
          );
    await _applyTokens(result);
  }

  Future<void> logout() async {
    _user = null;
    _uiUser = null;
    _accessToken = null;
    await _prefs.remove(kAccess);
    await _prefs.remove(kRefresh);
    await _prefs.remove(kSessionStarted);
    await _prefs.remove(kLastActivity);
    await _prefs.remove(kUiProfile);
    notifyListeners();
  }

  Future<void> refreshTokens() async {
    if (_refreshing) return;
    _refreshing = true;
    try {
      final refresh = _prefs.getString(kRefresh);
      if (refresh == null) {
        await logout();
        return;
      }
      await _refreshWith(refresh);
    } finally {
      _refreshing = false;
    }
  }

  Future<void> touchActivity() async {
    if (!isAuthenticated) return;
    await _prefs.setInt(kLastActivity, DateTime.now().millisecondsSinceEpoch);
  }

  Future<bool> inactiveTooLong(Duration timeout) async {
    if (!isAuthenticated) return false;
    final last = _prefs.getInt(kLastActivity);
    if (last == null) return false;
    return DateTime.now().millisecondsSinceEpoch - last >
        timeout.inMilliseconds;
  }

  Future<void> _applyTokens(AuthTokens result) async {
    _accessToken = result.accessToken;
    _user = result.user;
    await _saveUiProfile(result.user);
    final now = DateTime.now().millisecondsSinceEpoch;
    await _prefs.setString(kAccess, result.accessToken);
    await _prefs.setString(kRefresh, result.refreshToken);
    await _prefs.setInt(kSessionStarted, now);
    await _prefs.setInt(kLastActivity, now);
    notifyListeners();
  }

  Future<void> _refreshWith(String refreshToken) async {
    final result = _authApi != null
        ? await _authApi!.refresh(refreshToken)
        : await _localAuthApi.refresh(refreshToken);
    await _applyTokens(result);
  }

  Future<AppUser> _me() async {
    if (_authApi != null) {
      return _authApi!.me();
    }
    return _localAuthApi.meFromAccessToken(_accessToken);
  }

  Future<bool> _sessionExpiredByMaxDuration() async {
    final started = _prefs.getInt(kSessionStarted);
    if (started == null) return false;
    return DateTime.now().millisecondsSinceEpoch - started >
        maxSessionDuration.inMilliseconds;
  }

  Future<bool> checkMaxSessionAndLogoutIfNeeded() async {
    if (!isAuthenticated) return false;
    if (await _sessionExpiredByMaxDuration()) {
      await logout();
      return true;
    }
    return false;
  }

  AuthApi? get authApi => _authApi;

  Future<List<AppUser>> listUsers() async {
    if (_authApi != null) return _authApi!.listUsers();
    return _localAuthApi.listUsers();
  }

  Future<AppUser> updateUserRole(int id, AppRole role) async {
    if (_authApi != null) {
      return _authApi!.updateUserRole(id, role.apiValue);
    }
    return _localAuthApi.updateUserRole(id, role.apiValue);
  }

  Future<Map<String, int>> fetchStats() async {
    if (_authApi != null) return _authApi!.stats();
    return _localAuthApi.stats();
  }

  Future<void> _saveUiProfile(AppUser user) async {
    _uiUser = user;
    await _prefs.setString(
      kUiProfile,
      jsonEncode({
        'id': user.id,
        'username': user.username,
        'displayName': user.displayName,
        'role': user.role.apiValue,
      }),
    );
  }

  Future<void> _loadUiProfile() async {
    final raw = _prefs.getString(kUiProfile);
    if (raw == null) return;
    try {
      _uiUser = AppUser.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      _uiUser = null;
    }
  }

  /// После правки `auth_ui_profile` в DevTools — перечитать роль для интерфейса.
  Future<void> reloadUiProfileFromStorage() async {
    await _loadUiProfile();
    notifyListeners();
  }
}
