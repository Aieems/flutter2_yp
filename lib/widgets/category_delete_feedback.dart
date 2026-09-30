import 'package:flutter/material.dart';

import '../repositories/category_repository.dart';

Future<void> tryDeleteCategory(
  BuildContext context, {
  required CategoryRepository repository,
  required int categoryId,
  required String categoryName,
  required Future<void> Function() onSuccess,
}) async {
  final linked = await repository.countLinkedProjects(categoryId);
  if (linked > 0) {
    if (!context.mounted) return;
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Удаление невозможно'),
        content: Text(
          'Издательство (направление) «$categoryName» нельзя удалить: '
          'с ним связано проектов (книг): $linked.',
        ),
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

  try {
    await repository.softDelete(categoryId);
    await onSuccess();
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$e')),
      );
    }
  }
}
