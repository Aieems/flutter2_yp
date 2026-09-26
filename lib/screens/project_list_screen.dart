import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../data/reference_data.dart';
import '../models/project.dart';
import '../models/project_query.dart';
import '../routing/query_params.dart';
import '../state/project_list_notifier.dart';
import '../widgets/async_list_body.dart';
import '../widgets/debounced_search_field.dart';
import '../widgets/delete_dialogs.dart';
import '../widgets/entity_table.dart';
import '../widgets/pagination_bar.dart';

class ProjectListScreen extends StatefulWidget {
  const ProjectListScreen({super.key});

  @override
  State<ProjectListScreen> createState() => _ProjectListScreenState();
}

class _ProjectListScreenState extends State<ProjectListScreen> {
  bool _filtersExpanded = false;

  void _pushQuery(ProjectQuery q) {
    final uri = Uri(
      path: '/projects',
      queryParameters: projectQueryToParams(q),
    );
    context.go(uri.toString());
  }

  @override
  Widget build(BuildContext context) {
    final notifier = context.watch<ProjectListNotifier>();
    final q = notifier.query;
    final width = MediaQuery.sizeOf(context).width;
    final useCards = width < 600;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Проекты фонда'),
        actions: [
          if (notifier.hasSelection)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Center(
                child: Text('Выбрано: ${notifier.selected.length}'),
              ),
            ),
          if (notifier.hasSelection)
            IconButton(
              tooltip: 'Удалить выбранные',
              icon: const Icon(Icons.delete_sweep),
              onPressed: () async {
                if (await confirmBulkDelete(
                  context,
                  notifier.selected.length,
                )) {
                  await notifier.deleteSelected();
                  _pushQuery(notifier.query);
                }
              },
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DebouncedSearchField(
              initialValue: q.search,
              hint: 'Название или код проекта',
              onChanged: (text) =>
                  _pushQuery(q.copyWith(search: text)),
            ),
            const SizedBox(height: 12),
            ExpansionTile(
              title: const Text('Фильтры'),
              initiallyExpanded: _filtersExpanded,
              onExpansionChanged: (v) => setState(() => _filtersExpanded = v),
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final rawW = constraints.maxWidth;
                      final maxW = rawW.isFinite
                          ? rawW
                          : MediaQuery.sizeOf(context).width - 48;
                      final fieldW = maxW < 520 ? maxW : (maxW - 12) / 2;
                      return Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          SizedBox(
                            width: fieldW,
                            child: DropdownButtonFormField<int?>(
                              isExpanded: true,
                              value: q.tagId,
                              decoration: const InputDecoration(
                                labelText: 'Тег',
                                border: OutlineInputBorder(),
                                isDense: true,
                              ),
                              items: [
                                const DropdownMenuItem(
                                  value: null,
                                  child: Text('Все'),
                                ),
                                ...tags.map(
                                  (t) => DropdownMenuItem(
                                    value: t.id,
                                    child: Text(
                                      t.name,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ),
                              ],
                              onChanged: (v) =>
                                  _pushQuery(q.copyWith(tagId: v)),
                            ),
                          ),
                          SizedBox(
                            width: fieldW,
                            child: DropdownButtonFormField<int?>(
                              isExpanded: true,
                              value: q.categoryId,
                              decoration: const InputDecoration(
                                labelText: 'Направление',
                                border: OutlineInputBorder(),
                                isDense: true,
                              ),
                              items: [
                                const DropdownMenuItem(
                                  value: null,
                                  child: Text('Все'),
                                ),
                                ...categories.map(
                                  (c) => DropdownMenuItem(
                                    value: c.id,
                                    child: Text(
                                      c.name,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ),
                              ],
                              onChanged: (v) =>
                                  _pushQuery(q.copyWith(categoryId: v)),
                            ),
                          ),
                          SizedBox(
                            width: maxW < 520 ? maxW : 120,
                            child: TextFormField(
                              key: ValueKey('yf-${q.yearFrom}'),
                              initialValue: q.yearFrom?.toString() ?? '',
                              decoration: const InputDecoration(
                                labelText: 'Год от',
                                border: OutlineInputBorder(),
                                isDense: true,
                              ),
                              keyboardType: TextInputType.number,
                              onFieldSubmitted: (v) {
                                final n = int.tryParse(v.trim());
                                _pushQuery(q.copyWith(yearFrom: n));
                              },
                            ),
                          ),
                          SizedBox(
                            width: maxW < 520 ? maxW : 120,
                            child: TextFormField(
                              key: ValueKey('yt-${q.yearTo}'),
                              initialValue: q.yearTo?.toString() ?? '',
                              decoration: const InputDecoration(
                                labelText: 'Год до',
                                border: OutlineInputBorder(),
                                isDense: true,
                              ),
                              keyboardType: TextInputType.number,
                              onFieldSubmitted: (v) {
                                final n = int.tryParse(v.trim());
                                _pushQuery(q.copyWith(yearTo: n));
                              },
                            ),
                          ),
                          SizedBox(
                            width: maxW,
                            child: SwitchListTile(
                              contentPadding: EdgeInsets.zero,
                              title: const Text('Показывать удалённые'),
                              value: q.includeDeleted,
                              onChanged: (v) =>
                                  _pushQuery(q.copyWith(includeDeleted: v)),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Expanded(
              child: AsyncListBody(
                status: notifier.status,
                error: notifier.error,
                isEmpty: notifier.result.items.isEmpty,
                onRetry: notifier.load,
                child: useCards
                    ? _ProjectCardList(
                        projects: notifier.result.items,
                        selected: notifier.selected,
                        onToggle: notifier.toggleSelection,
                        onOpen: (p) => context.go('/projects/${p.id}'),
                        onDelete: (p) async {
                          if (await confirmSoftDelete(context, p.title)) {
                            await notifier.softDeleteOne(p.id);
                            _pushQuery(notifier.query);
                          }
                        },
                      )
                    : EntityTable<Project>(
                        items: notifier.result.items,
                        idOf: (p) => p.id,
                        selected: notifier.selected,
                        onToggleSelect: notifier.toggleSelection,
                        sortField: q.sortField,
                        sortAscending: q.sortAscending,
                        onSort: (field) => _pushQuery(
                          q.copyWith(
                            sortField: field,
                            sortAscending: field == q.sortField
                                ? !q.sortAscending
                                : true,
                          ),
                        ),
                        columns: [
                          TableColumnSpec(
                            label: 'Название',
                            sortField: 'title',
                            build: (p) => Text(p.title),
                          ),
                          TableColumnSpec(
                            label: 'Год',
                            sortField: 'year',
                            numeric: true,
                            build: (p) => Text('${p.year}'),
                          ),
                          TableColumnSpec(
                            label: 'Цель, ₽',
                            sortField: 'goalAmount',
                            numeric: true,
                            build: (p) => Text('${p.goalAmount}'),
                          ),
                        ],
                        actions: (p) => [
                          IconButton(
                            icon: const Icon(Icons.visibility),
                            onPressed: () => context.go('/projects/${p.id}'),
                          ),
                          if (p.isDeleted)
                            IconButton(
                              tooltip: 'Восстановить',
                              icon: const Icon(Icons.restore),
                              onPressed: () async {
                                await notifier.restoreOne(p.id);
                                _pushQuery(notifier.query);
                              },
                            )
                          else
                            IconButton(
                              icon: const Icon(Icons.delete_outline),
                              onPressed: () async {
                                if (await confirmSoftDelete(context, p.title)) {
                                  await notifier.softDeleteOne(p.id);
                                  _pushQuery(notifier.query);
                                }
                              },
                            ),
                        ],
                      ),
              ),
            ),
            PaginationBar(
              result: notifier.result,
              onPage: (page) => _pushQuery(q.copyWith(page: page)),
              onSize: (size) => _pushQuery(q.copyWith(size: size)),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProjectCardList extends StatelessWidget {
  const _ProjectCardList({
    required this.projects,
    required this.selected,
    required this.onToggle,
    required this.onOpen,
    required this.onDelete,
  });

  final List<Project> projects;
  final Set<int> selected;
  final ValueChanged<int> onToggle;
  final ValueChanged<Project> onOpen;
  final ValueChanged<Project> onDelete;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: projects.length,
      itemBuilder: (context, i) {
        final p = projects[i];
        return Card(
          child: ListTile(
            leading: Checkbox(
              value: selected.contains(p.id),
              onChanged: (_) => onToggle(p.id),
            ),
            title: Text(p.title),
            subtitle: Text('${p.code} · ${p.year} · ${p.goalAmount} ₽'),
            trailing: IconButton(
              icon: const Icon(Icons.chevron_right),
              onPressed: () => onOpen(p),
            ),
            onTap: () => onOpen(p),
            onLongPress: () => onDelete(p),
          ),
        );
      },
    );
  }
}
