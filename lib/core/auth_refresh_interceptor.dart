import 'package:dio/dio.dart';

import '../state/auth_notifier.dart';

/// Обновление access-токена при 401 (кроме /auth/).
class AuthRefreshInterceptor extends Interceptor {
  AuthRefreshInterceptor({required AuthNotifier auth, required Dio dio})
    : _auth = auth,
      _dio = dio;

  final AuthNotifier _auth;
  final Dio _dio;

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final status = err.response?.statusCode;
    final path = err.requestOptions.path;
    if (status != 401 || path.contains('/auth/')) {
      return handler.next(err);
    }
    if (err.requestOptions.extra['_authRetry'] == true) {
      await _auth.logout();
      return handler.next(err);
    }
    try {
      await _auth.refreshTokens();
      final token = _auth.accessToken;
      if (token == null) {
        await _auth.logout();
        return handler.next(err);
      }
      final options = err.requestOptions;
      options.headers['Authorization'] = 'Bearer $token';
      options.extra['_authRetry'] = true;
      final response = await _dio.fetch<dynamic>(options);
      return handler.resolve(response);
    } catch (_) {
      await _auth.logout();
      return handler.next(err);
    }
  }
}
