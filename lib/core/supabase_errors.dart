import 'package:supabase_flutter/supabase_flutter.dart';

import 'api_exceptions.dart';

Future<T> guardSupabase<T>(Future<T> Function() action) async {
  try {
    return await action();
  } on AuthException catch (e) {
    final msg = e.message.toLowerCase();
    if (msg.contains('invalid login') || msg.contains('invalid credentials')) {
      throw const UnauthorizedException('Неверный логин или пароль.');
    }
    if (msg.contains('email not confirmed')) {
      throw const UnauthorizedException(
        'Подтвердите email в Supabase (Authentication → Providers → Email).',
      );
    }
    throw UnauthorizedException(e.message);
  } on PostgrestException catch (e) {
    if (e.code == '42501' || e.message.contains('permission')) {
      throw const ForbiddenException();
    }
    if (e.code == '23505') {
      throw ValidationException('Ошибка валидации', {
        'field': e.message,
      });
    }
    throw ServerException(e.message);
  } on ApiException {
    rethrow;
  } catch (e) {
    throw NetworkException('Supabase: $e');
  }
}

String emailForFundUsername(String username) {
  final u = username.trim().toLowerCase();
  return '$u@fund.local';
}
