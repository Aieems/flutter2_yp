import 'package:flutter/material.dart';

import 'constrained_dialog.dart';

Future<bool> confirmSoftDelete(BuildContext context, String label) async {
  final ok = await showConstrainedDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Удалить запись?'),
      content: Text('«$label» будет скрыт (логическое удаление).'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Отмена'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text('Удалить'),
        ),
      ],
    ),
  );
  return ok ?? false;
}

Future<bool> confirmBulkDelete(BuildContext context, int count) async {
  final ok = await showConstrainedDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Удалить выбранные?'),
      content: Text('Будет выполнено логическое удаление записей: $count'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Отмена'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text('Удалить'),
        ),
      ],
    ),
  );
  return ok ?? false;
}

Future<bool> confirmHardDelete(BuildContext context, String label) async {
  final ok = await showConstrainedDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Удалить навсегда?'),
      content: Text('«$label» будет удалён без возможности восстановления.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Отмена'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, true),
          style: FilledButton.styleFrom(backgroundColor: Colors.red),
          child: const Text('Стереть'),
        ),
      ],
    ),
  );
  return ok ?? false;
}
