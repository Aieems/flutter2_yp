import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/fund_category.dart';
import '../repositories/category_repository.dart';
import '../widgets/category_delete_feedback.dart';
import '../core/show_api_error.dart';
import '../models/app_role.dart';
import '../widgets/delete_dialogs.dart';
import '../widgets/role_gate.dart';

class CategoryDetailScreen extends StatefulWidget {
  const CategoryDetailScreen({super.key, required this.categoryId});

  final int categoryId;

  @override
  State<CategoryDetailScreen> createState() => _CategoryDetailScreenState();
}

class _CategoryDetailScreenState extends State<CategoryDetailScreen> {
  FundCategory? _item;
  int _linkedProjects = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final repo = context.read<CategoryRepository>();
    _item = await repo.findById(widget.categoryId);
    _linkedProjects = await repo.countLinkedProjects(widget.categoryId);
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final c = _item;
    if (c == null) {
      return const Scaffold(body: Center(child: Text('Не найдено')));
    }
    final repo = context.read<CategoryRepository>();

    return Scaffold(
      appBar: AppBar(
        title: Text(c.name),
        actions: [
          RoleGate(
            minRole: AppRole.coordinator,
            builder: (context) => IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => context.push('/categories/${c.id}/edit'),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Связанных проектов (книг): $_linkedProjects'),
            if (_linkedProjects > 0 && !c.isDeleted)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Удаление издательства недоступно, пока есть связанные проекты.',
                  style: TextStyle(color: Colors.orange.shade900),
                ),
              ),
            if (c.isDeleted)
              Text(
                'Запись удалена',
                style: TextStyle(color: Colors.red.shade700),
              ),
            const Spacer(),
            Wrap(
              spacing: 8,
              children: [
                RoleGate(
                  minRole: AppRole.admin,
                  builder: (context) => c.isDeleted
                      ? FilledButton.icon(
                          onPressed: () async {
                            try {
                              await repo.restore(c.id);
                              await _load();
                            } catch (e) {
                              if (context.mounted) showApiError(context, e);
                            }
                          },
                          icon: const Icon(Icons.restore),
                          label: const Text('Восстановить'),
                        )
                      : const SizedBox.shrink(),
                ),
                RoleGate(
                  minRole: AppRole.coordinator,
                  builder: (context) {
                    if (c.isDeleted) return const SizedBox.shrink();
                    if (_linkedProjects == 0) {
                      return FilledButton.icon(
                        onPressed: () async {
                          if (!await confirmSoftDelete(context, c.name)) return;
                          await tryDeleteCategory(
                            context,
                            repository: repo,
                            categoryId: c.id,
                            categoryName: c.name,
                            onSuccess: () async {
                              if (context.mounted) context.pop();
                            },
                          );
                        },
                        icon: const Icon(Icons.delete_outline),
                        label: const Text('Логическое удаление'),
                      );
                    }
                    return FilledButton.icon(
                      onPressed: () => tryDeleteCategory(
                        context,
                        repository: repo,
                        categoryId: c.id,
                        categoryName: c.name,
                        onSuccess: () async {},
                      ),
                      icon: const Icon(Icons.block),
                      label: Text('Удалить (связей: $_linkedProjects)'),
                    );
                  },
                ),
                RoleGate(
                  minRole: AppRole.admin,
                  builder: (context) => _linkedProjects == 0
                      ? OutlinedButton.icon(
                          onPressed: () async {
                            if (await confirmHardDelete(context, c.name)) {
                              try {
                                await repo.hardDelete(c.id);
                                if (context.mounted) context.pop();
                              } catch (e) {
                                if (context.mounted) showApiError(context, e);
                              }
                            }
                          },
                          icon: const Icon(Icons.delete_forever),
                          label: const Text('Удалить навсегда'),
                        )
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
