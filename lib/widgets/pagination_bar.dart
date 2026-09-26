import 'package:flutter/material.dart';

import '../models/page_result.dart';

class PaginationBar extends StatelessWidget {
  const PaginationBar({
    super.key,
    required this.result,
    required this.onPage,
    required this.onSize,
  });

  final PageResult<dynamic> result;
  final ValueChanged<int> onPage;
  final ValueChanged<int> onSize;

  static const sizes = [10, 25, 50];

  @override
  Widget build(BuildContext context) {
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 8,
      runSpacing: 8,
      children: [
        Text(
          'Страница ${result.page} из ${result.totalPages} · всего ${result.total}',
        ),
        IconButton(
          tooltip: 'Первая',
          onPressed: result.hasPrevious ? () => onPage(1) : null,
          icon: const Icon(Icons.first_page),
        ),
        IconButton(
          tooltip: 'Предыдущая',
          onPressed: result.hasPrevious ? () => onPage(result.page - 1) : null,
          icon: const Icon(Icons.chevron_left),
        ),
        IconButton(
          tooltip: 'Следующая',
          onPressed: result.hasNext ? () => onPage(result.page + 1) : null,
          icon: const Icon(Icons.chevron_right),
        ),
        IconButton(
          tooltip: 'Последняя',
          onPressed: result.hasNext ? () => onPage(result.totalPages) : null,
          icon: const Icon(Icons.last_page),
        ),
        DropdownButton<int>(
          value: result.size,
          items: sizes
              .map((s) => DropdownMenuItem(value: s, child: Text('$s / стр.')))
              .toList(),
          onChanged: (v) {
            if (v != null) onSize(v);
          },
        ),
      ],
    );
  }
}
