import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/project.dart';
import '../repositories/category_repository.dart';
import '../repositories/project_repository.dart';
import '../repositories/tag_repository.dart';
import '../core/show_api_error.dart';
import '../models/app_role.dart';
import '../widgets/delete_dialogs.dart';
import '../widgets/role_gate.dart';

class ProjectDetailScreen extends StatefulWidget {
  const ProjectDetailScreen({super.key, required this.projectId});

  final int projectId;

  @override
  State<ProjectDetailScreen> createState() => _ProjectDetailScreenState();
}

class _ProjectDetailScreenState extends State<ProjectDetailScreen> {
  Project? _project;
  String _categoryName = '—';
  List<String> _tagNames = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final repo = context.read<ProjectRepository>();
      _project = await repo.findById(widget.projectId);
      if (_project != null) {
        final cat = await context
            .read<CategoryRepository>()
            .findById(_project!.categoryId);
        _categoryName = cat?.name ?? '—';
        final allTags = await context.read<TagRepository>().listForSelect();
        _tagNames = allTags
            .where((t) => _project!.tagIds.contains(t.id))
            .map((t) => t.name)
            .toList();
      }
    } catch (e) {
      _error = '$e';
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Проект')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Проект')),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_error!),
              FilledButton(onPressed: _load, child: const Text('Повторить')),
            ],
          ),
        ),
      );
    }
    final p = _project;
    if (p == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Проект')),
        body: const Center(child: Text('Проект не найден')),
      );
    }

    final repo = context.read<ProjectRepository>();

    return Scaffold(
      appBar: AppBar(
        title: Text(p.title),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          RoleGate(
            minRole: AppRole.coordinator,
            builder: (context) => IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () async {
                await context.push('/projects/${p.id}/edit');
                if (mounted) await _load();
              },
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Код: ${p.code}', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text('Год запуска: ${p.year}'),
            Text('Направление: $_categoryName'),
            Text('Цель сбора: ${p.goalAmount} ₽'),
            Text('Волонтёры: ${p.volunteersActive} / ${p.volunteersTotal}'),
            Text('Теги: ${_tagNames.join(', ')}'),
            if (p.isDeleted)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Запись удалена',
                  style: TextStyle(color: Colors.red.shade700),
                ),
              ),
            const Spacer(),
            Wrap(
              spacing: 8,
              children: [
                RoleGate(
                  minRole: AppRole.admin,
                  builder: (context) => p.isDeleted
                      ? FilledButton.icon(
                          onPressed: () async {
                            try {
                              await repo.restore(p.id);
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
                  builder: (context) => !p.isDeleted
                      ? FilledButton.icon(
                          onPressed: () async {
                            if (await confirmSoftDelete(context, p.title)) {
                              try {
                                await repo.softDelete(p.id);
                                if (context.mounted) context.pop();
                              } catch (e) {
                                if (context.mounted) showApiError(context, e);
                              }
                            }
                          },
                          icon: const Icon(Icons.delete_outline),
                          label: const Text('Логическое удаление'),
                        )
                      : const SizedBox.shrink(),
                ),
                RoleGate(
                  minRole: AppRole.admin,
                  builder: (context) => OutlinedButton.icon(
                    onPressed: () async {
                      if (await confirmHardDelete(context, p.title)) {
                        try {
                          await repo.hardDelete(p.id);
                          if (context.mounted) context.pop();
                        } catch (e) {
                          if (context.mounted) showApiError(context, e);
                        }
                      }
                    },
                    icon: const Icon(Icons.delete_forever),
                    label: const Text('Удалить навсегда'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
