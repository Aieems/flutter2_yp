import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/api_exceptions.dart';
import '../core/auth_api.dart';
import '../core/local_auth_api.dart';
import '../core/supabase_auth_api.dart';
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
    SupabaseAuthApi? supabaseAuth,
    LocalAuthApi? localAuthApi,
  }) : _prefs = prefs,
       _authApi = authApi,
       _supabaseAuth = supabaseAuth,
       _localAuthApi = localAuthApi ?? LocalAuthApi();

  final SharedPreferences _prefs;
  final AuthApi? _authApi;
  final SupabaseAuthApi? _supabaseAuth;
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
      if (_supabaseAuth != null && refresh != null) {
        await _supabaseAuth!.restoreSession(access, refresh);
      }
      _user = await _me();
      _accessToken = _supabaseAuth?.currentAccessToken ?? _accessToken;
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
    final result = await _loginBackend(username, password);
    await _applyTokens(result);
  }

  Future<AuthTokens> _loginBackend(String username, String password) async {
    final supa = _supabaseAuth;
    if (supa != null) return supa.login(username, password);
    final api = _authApi;
    if (api != null) return api.login(username, password);
    return _localAuthApi.login(username, password);
  }

  Future<void> register({
    required String username,
    required String password,
    required String displayName,
  }) async {
    final supa = _supabaseAuth;
    final AuthTokens result;
    if (supa != null) {
      result = await supa.register(
        username: username,
        password: password,
        displayName: displayName,
      );
    } else {
      final api = _authApi;
      result = api != null
          ? await api.register(
              username: username,
              password: password,
              displayName: displayName,
            )
          : await _localAuthApi.register(
              username: username,
              password: password,
              displayName: displayName,
            );
    }
    await _applyTokens(result);
  }

  Future<void> logout() async {
    await _supabaseAuth?.signOut();
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
    final supa = _supabaseAuth;
    final AuthTokens result;
    if (supa != null) {
      result = await supa.refresh(refreshToken);
    } else {
      final api = _authApi;
      result = api != null
          ? await api.refresh(refreshToken)
          : await _localAuthApi.refresh(refreshToken);
    }
    await _applyTokens(result);
  }

  Future<AppUser> _me() async {
    final supa = _supabaseAuth;
    if (supa != null) return supa.me();
    final api = _authApi;
    if (api != null) return api.me();
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
    final supa = _supabaseAuth;
    if (supa != null) return supa.listUsers();
    final api = _authApi;
    if (api != null) return api.listUsers();
    return _localAuthApi.listUsers();
  }

  Future<AppUser> updateUserRole(int id, AppRole role) async {
    final api = _authApi;
    if (api != null) return api.updateUserRole(id, role.apiValue);
    return _localAuthApi.updateUserRole(id, role.apiValue);
  }

  Future<AppUser> updateUserRoleFor(AppUser target, AppRole role) async {
    final authId = target.authUserId;
    final supa = _supabaseAuth;
    if (supa != null && authId != null) {
      return supa.updateUserRole(authId, role.apiValue);
    }
    return updateUserRole(target.id, role);
  }

  Future<Map<String, int>> fetchStats() async {
    final supa = _supabaseAuth;
    if (supa != null) return supa.stats();
    final api = _authApi;
    if (api != null) return api.stats();
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
        if (user.authUserId != null) 'authUserId': user.authUserId,
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
