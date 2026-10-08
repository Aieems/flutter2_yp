import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/app_role.dart';
import '../models/app_user.dart';
import 'api_exceptions.dart';
import 'supabase_errors.dart';

class SupabaseAuthApi {
  SupabaseClient get _client => Supabase.instance.client;

  Future<AuthTokens> login(String username, String password) =>
      guardSupabase(() async {
        final response = await _client.auth.signInWithPassword(
          email: emailForFundUsername(username),
          password: password,
        );
        return _tokensFromSession(response.session!, usernameHint: username);
      });

  Future<AuthTokens> register({
    required String username,
    required String password,
    required String displayName,
  }) => guardSupabase(() async {
        final response = await _client.auth.signUp(
          email: emailForFundUsername(username),
          password: password,
          data: {
            'username': username.trim(),
            'display_name': displayName.trim(),
          },
        );
        final session = response.session;
        if (session == null) {
          throw const UnauthorizedException(
            'Регистрация создана. Отключите подтверждение email в Supabase '
            'или подтвердите письмо, затем войдите.',
          );
        }
        return _tokensFromSession(session, usernameHint: username);
      });

  Future<AuthTokens> refresh(String refreshToken) => guardSupabase(() async {
        final response = await _client.auth.refreshSession(refreshToken);
        final session = response.session;
        if (session == null) {
          throw const UnauthorizedException('Сессия истекла.');
        }
        return _tokensFromSession(session);
      });

  Future<void> restoreSession(String accessToken, String refreshToken) =>
      guardSupabase(() async {
        await _client.auth.setSession(refreshToken);
      });

  Future<AppUser> me() => guardSupabase(() async {
        final uid = _client.auth.currentUser?.id;
        if (uid == null) {
          throw const UnauthorizedException();
        }
        return _profileToUser(await _fetchProfile(uid));
      });

  Future<List<AppUser>> listUsers() => guardSupabase(() async {
        final rows = await _client.from('profiles').select();
        var i = 1;
        return rows.map((row) {
          final u = _profileToUser(Map<String, dynamic>.from(row as Map));
          return AppUser(
            id: i++,
            username: u.username,
            displayName: u.displayName,
            role: u.role,
            authUserId: u.authUserId,
          );
        }).toList();
      });

  Future<AppUser> updateUserRole(String authUserId, String role) =>
      guardSupabase(() async {
        final row = await _client
            .from('profiles')
            .update({'role': role})
            .eq('id', authUserId)
            .select()
            .single();
        return _profileToUser(Map<String, dynamic>.from(row));
      });

  Future<Map<String, int>> stats() => guardSupabase(() async {
        Future<int> count(String table) async {
          final rows = await _client
              .from(table)
              .select('id')
              .filter('deleted_at', 'is', null);
          return rows.length;
        }

        return {
          'projects': await count('projects'),
          'partners': await count('partners'),
          'volunteers': await count('volunteers'),
          'categories': await count('categories'),
        };
      });

  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  String? get currentAccessToken =>
      _client.auth.currentSession?.accessToken;

  Future<Map<String, dynamic>> _fetchProfile(String uid) async {
    final row = await _client
        .from('profiles')
        .select()
        .eq('id', uid)
        .maybeSingle();
    if (row == null) {
      throw const UnauthorizedException('Профиль не найден.');
    }
    return Map<String, dynamic>.from(row);
  }

  AppUser _profileToUser(Map<String, dynamic> row) {
    final authId = row['id'] as String;
    return AppUser(
      id: authId.hashCode.abs(),
      authUserId: authId,
      username: row['username'] as String,
      displayName: row['display_name'] as String? ?? row['username'] as String,
      role: AppRole.fromApi(row['role'] as String?),
    );
  }

  Future<AuthTokens> _tokensFromSession(
    Session session, {
    String? usernameHint,
  }) async {
    final uid = session.user.id;
    AppUser user;
    try {
      user = _profileToUser(await _fetchProfile(uid));
    } catch (_) {
      user = AppUser(
        id: 0,
        authUserId: uid,
        username: usernameHint ?? session.user.email?.split('@').first ?? 'user',
        displayName: usernameHint ?? 'Пользователь',
        role: AppRole.volunteer,
      );
    }
    return AuthTokens(
      accessToken: session.accessToken,
      refreshToken: session.refreshToken ?? '',
      user: user,
    );
  }
}
