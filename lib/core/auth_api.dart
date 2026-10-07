import 'package:dio/dio.dart';

import '../models/app_user.dart';
import 'api_exceptions.dart';

class AuthApi {
  AuthApi(this._dio);

  final Dio _dio;

  Future<AuthTokens> login(String username, String password) => guard(() async {
        final response = await _dio.post<Map<String, dynamic>>(
          '/auth/login',
          data: {'username': username, 'password': password},
        );
        return _parseAuthResponse(response.data!);
      });

  Future<AuthTokens> register({
    required String username,
    required String password,
    required String displayName,
  }) =>
      guard(() async {
        final response = await _dio.post<Map<String, dynamic>>(
          '/auth/register',
          data: {
            'username': username,
            'password': password,
            'displayName': displayName,
          },
        );
        return _parseAuthResponse(response.data!);
      });

  Future<AuthTokens> refresh(String refreshToken) => guard(() async {
        final response = await _dio.post<Map<String, dynamic>>(
          '/auth/refresh',
          data: {'refreshToken': refreshToken},
        );
        return _parseAuthResponse(response.data!);
      });

  Future<AppUser> me() => guard(() async {
        final response = await _dio.get<Map<String, dynamic>>('/auth/me');
        return AppUser.fromJson(response.data!);
      });

  Future<List<AppUser>> listUsers() => guard(() async {
        final response = await _dio.get<List<dynamic>>('/admin/users');
        return (response.data ?? [])
            .map((e) => AppUser.fromJson(e as Map<String, dynamic>))
            .toList();
      });

  Future<AppUser> updateUserRole(int id, String role) => guard(() async {
        final response = await _dio.patch<Map<String, dynamic>>(
          '/admin/users/$id',
          data: {'role': role},
        );
        return AppUser.fromJson(response.data!);
      });

  Future<Map<String, int>> stats() => guard(() async {
        final response = await _dio.get<Map<String, dynamic>>('/admin/stats');
        return response.data!.map((k, v) => MapEntry(k, (v as num).toInt()));
      });

  AuthTokens _parseAuthResponse(Map<String, dynamic> data) {
    return AuthTokens(
      accessToken: data['accessToken'] as String,
      refreshToken: data['refreshToken'] as String,
      user: AppUser.fromJson(data['user'] as Map<String, dynamic>),
    );
  }
}
