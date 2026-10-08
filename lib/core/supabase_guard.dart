import 'package:supabase_flutter/supabase_flutter.dart';

import 'api_exceptions.dart';

/// Технический email для входа по «логину» (Supabase требует email).
String supabaseEmailForUsername(String username) {
  final u = username.trim().toLowerCase();
  return '$u@fund.local';
}

Future<T> guardSupabase<T>(Future<T> Function() action) async {
  try {
    return await action();
  } on AuthException catch (e) {
    final msg = e.message.toLowerCase();
    if (msg.contains('invalid') || msg.contains('credentials')) {
      throw const UnauthorizedException('Неверный логин или пароль.');
    }
    throw UnauthorizedException(e.message);
  } on PostgrestException catch (e) {
    if (e.code == '42501' ||
        e.message.contains('permission') ||
        e.message.contains('policy')) {
      throw const ForbiddenException();
    }
    if (e.code == '23505') {
      throw ValidationException('Ошибка валидации', {
        'field': e.message,
      });
    }
    throw ServerException(e.message);
  } catch (e) {
    if (e is ApiException) rethrow;
    throw ServerException('Ошибка Supabase: $e');
  }
}
