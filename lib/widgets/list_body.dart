import 'package:flutter/material.dart';

import '../state/load_status.dart';

class ListBody extends StatelessWidget {
  const ListBody({
    super.key,
    required this.status,
    required this.error,
    required this.isEmpty,
    required this.child,
    this.onRetry,
  });

  final LoadStatus status;
  final String? error;
  final bool isEmpty;
  final Widget child;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    if (status == LoadStatus.loading || status == LoadStatus.idle) {
      return const Center(child: CircularProgressIndicator());
    }
    if (status == LoadStatus.error) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.red.shade700),
            const SizedBox(height: 12),
            Text(error ?? 'Ошибка загрузки'),
            if (onRetry != null) ...[
              const SizedBox(height: 12),
              FilledButton(onPressed: onRetry, child: const Text('Повторить')),
            ],
          ],
        ),
      );
    }
    if (isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.inbox_outlined, size: 48, color: Colors.grey.shade600),
            const SizedBox(height: 12),
            const Text('Ничего не найдено'),
            const Text('Измените условия поиска или фильтры'),
          ],
        ),
      );
    }
    return child;
  }
}
