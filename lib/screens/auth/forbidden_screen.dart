import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ForbiddenScreen extends StatelessWidget {
  const ForbiddenScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Доступ запрещён')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.lock_outline, size: 64, color: Colors.orange.shade700),
            const SizedBox(height: 16),
            const Text(
              'У вашей роли нет доступа к этому разделу.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Клиент скрывает кнопки для удобства; окончательное решение — на сервере (403).',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () => context.go('/projects'),
              child: const Text('На главную'),
            ),
          ],
        ),
      ),
    );
  }
}
