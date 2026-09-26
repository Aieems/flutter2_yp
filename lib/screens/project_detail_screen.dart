import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../data/reference_data.dart';
import '../models/project.dart';
import '../repositories/project_repository.dart';
import '../widgets/delete_dialogs.dart';

class ProjectDetailScreen extends StatefulWidget {
  const ProjectDetailScreen({super.key, required this.projectId});

  final int projectId;

  @override
  State<ProjectDetailScreen> createState() => _ProjectDetailScreenState();
}

class _ProjectDetailScreenState extends State<ProjectDetailScreen> {
  Project? _project;
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
    } catch (e) {
      _error = '$e';
    }
    if (mounted) {
      setState(() => _loading = false);
    }
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
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Код: ${p.code}', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text('Год запуска: ${p.year}'),
            Text('Направление: ${categoryName(p.categoryId)}'),
            Text('Цель сбора: ${p.goalAmount} ₽'),
            Text('Волонтёры: ${p.volunteersActive} / ${p.volunteersTotal}'),
            Text('Теги: ${p.tagIds.map(tagName).join(', ')}'),
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
                if (p.isDeleted)
                  FilledButton.icon(
                    onPressed: () async {
                      await repo.restore(p.id);
                      await _load();
                    },
                    icon: const Icon(Icons.restore),
                    label: const Text('Восстановить'),
                  )
                else
                  FilledButton.icon(
                    onPressed: () async {
                      if (await confirmSoftDelete(context, p.title)) {
                        await repo.softDelete(p.id);
                        if (context.mounted) context.pop();
                      }
                    },
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('Логическое удаление'),
                  ),
                OutlinedButton.icon(
                  onPressed: () async {
                    if (await confirmHardDelete(context, p.title)) {
                      await repo.hardDelete(p.id);
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
