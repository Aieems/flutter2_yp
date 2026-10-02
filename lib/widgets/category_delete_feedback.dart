import 'package:flutter/material.dart';

import '../core/api_exceptions.dart';
import '../repositories/category_repository.dart';

Future<void> tryDeleteCategory(
  BuildContext context, {
  required CategoryRepository repository,
  required int categoryId,
  required String categoryName,
  required Future<void> Function() onSuccess,
}) async {
  try {
    await repository.softDelete(categoryId);
    await onSuccess();
  } on ConflictException catch (e) {
    if (!context.mounted) return;
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Удаление невозможно'),
        content: Text(e.message),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Понятно'),
          ),
        ],
      ),
    );
  } on StateError catch (e) {
    if (!context.mounted) return;
    if (e.message.contains('привязано') ||
        e.message.contains('Нельзя удалить')) {
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Удаление невозможно'),
          content: Text(e.message),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Понятно'),
            ),
          ],
        ),
      );
      return;
    }
    rethrow;
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e is ApiException ? e.message : '$e')),
      );
    }
  }
}
