import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import 'api_exceptions.dart';
import 'config.dart';

Dio buildDio({String? Function()? tokenProvider, bool enableReadRetry = true}) {
  final dio = Dio(
    BaseOptions(
      baseUrl: apiBaseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 15),
      headers: {'Content-Type': 'application/json'},
      validateStatus: (status) => status != null && status < 500,
    ),
  );

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        final token = tokenProvider?.call();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        if (kDebugMode) {
          debugPrint('[API] → ${options.method} ${options.uri}');
        }
        return handler.next(options);
      },
      onResponse: (response, handler) {
        if (kDebugMode) {
          debugPrint(
            '[API] ← ${response.statusCode} ${response.requestOptions.uri}',
          );
        }
        final status = response.statusCode ?? 0;
        if (status >= 400) {
          return handler.reject(
            DioException(
              requestOptions: response.requestOptions,
              response: response,
              type: DioExceptionType.badResponse,
              error: mapHttpError(status, response.data),
            ),
            true,
          );
        }
        return handler.next(response);
      },
      onError: (error, handler) {
        if (kDebugMode) {
          debugPrint('[API] сбой ${error.requestOptions.uri}: ${error.type}');
        }
        return handler.next(error);
      },
    ),
  );

  if (enableReadRetry) {
    dio.interceptors.add(_ReadRetryInterceptor(dio));
  }
  return dio;
}

class _ReadRetryInterceptor extends Interceptor {
  _ReadRetryInterceptor(this._dio);

  final Dio _dio;

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final opts = err.requestOptions;
    final method = opts.method.toUpperCase();
    if (method != 'GET') {
      return handler.next(err);
    }
    if (err.type != DioExceptionType.connectionError &&
        err.type != DioExceptionType.connectionTimeout &&
        err.type != DioExceptionType.receiveTimeout) {
      return handler.next(err);
    }

    final extra = opts.extra;
    final attempt = (extra['_retryAttempt'] as int?) ?? 0;
    if (attempt >= 3) {
      return handler.next(err);
    }

    final delayMs = 300 * (attempt + 1);
    await Future<void>.delayed(Duration(milliseconds: delayMs));

    try {
      final nextExtra = Map<String, dynamic>.from(extra)
        ..['_retryAttempt'] = attempt + 1;
      final response = await _dio.fetch<dynamic>(
        opts.copyWith(extra: nextExtra),
      );
      return handler.resolve(response);
    } on DioException catch (e) {
      return handler.next(e);
    }
  }
}
