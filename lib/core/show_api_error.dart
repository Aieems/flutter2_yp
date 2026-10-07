import 'package:flutter/material.dart';

import 'api_exceptions.dart';

void showApiError(BuildContext context, Object error) {
  final message = switch (error) {
    ForbiddenException e => e.message,
    UnauthorizedException e => e.message,
    ValidationException e => e.message,
    ConflictException e => e.message,
    ApiException e => e.message,
    _ => 'Не удалось выполнить операцию.',
  };
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}
