import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/fund_tag.dart';
import '../repositories/category_repository.dart';
import '../repositories/tag_repository.dart';
import '../widgets/delete_dialogs.dart';

class TagDetailScreen extends StatefulWidget {
  const TagDetailScreen({super.key, required this.tagId});

  final int tagId;

  @override
  State<TagDetailScreen> createState() => _TagDetailScreenState();
}

class _TagDetailScreenState extends State<TagDetailScreen> {
  FundTag? _item;
  String _categoryName = '—';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final repo = context.read<TagRepository>();
    _item = await repo.findById(widget.tagId);
    if (_item != null) {
      final cat =
          await context.read<CategoryRepository>().findById(_item!.categoryId);
      _categoryName = cat?.name ?? '—';
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    final t = _item;
    if (t == null) {
      return const Scaffold(body: Center(child: Text('Не найдено')));
    }
    final repo = context.read<TagRepository>();

    return Scaffold(
      appBar: AppBar(
        title: Text(t.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => context.push('/tags/${t.id}/edit'),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Направление: $_categoryName'),
            if (t.isDeleted)
              Text(
                'Запись удалена',
                style: TextStyle(color: Colors.red.shade700),
              ),
            const Spacer(),
            Wrap(
              spacing: 8,
              children: [
                if (t.isDeleted)
                  FilledButton.icon(
                    onPressed: () async {
                      await repo.restore(t.id);
                      await _load();
                    },
                    icon: const Icon(Icons.restore),
                    label: const Text('Восстановить'),
                  )
                else
                  FilledButton.icon(
                    onPressed: () async {
                      if (await confirmSoftDelete(context, t.name)) {
                        await repo.softDelete(t.id);
                        if (context.mounted) context.pop();
                      }
                    },
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('Логическое удаление'),
                  ),
                OutlinedButton.icon(
                  onPressed: () async {
                    if (await confirmHardDelete(context, t.name)) {
                      await repo.hardDelete(t.id);
                      if (context.mounted) context.pop();
                    }
                  },
                  icon: const Icon(Icons.delete_forever),
                  label: const Text('Удалить навсегда'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
