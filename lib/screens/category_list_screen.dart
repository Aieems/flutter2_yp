import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/fund_category.dart';
import '../models/simple_list_query.dart';
import '../repositories/category_repository.dart';
import '../routing/query_params.dart';
import '../state/simple_entity_notifiers.dart';
import '../widgets/async_list_body.dart';
import '../widgets/debounced_search_field.dart';
import '../widgets/category_delete_feedback.dart';
import '../widgets/delete_dialogs.dart';
import '../widgets/entity_table.dart';
import '../widgets/entity_action_visibility.dart';
import '../widgets/pagination_bar.dart';
import '../widgets/role_gate.dart';
import '../models/app_role.dart';

class CategoryListScreen extends StatefulWidget {
  const CategoryListScreen({super.key});

  @override
  State<CategoryListScreen> createState() => _CategoryListScreenState();
}

class _CategoryListScreenState extends State<CategoryListScreen> {
  void _pushQuery(SimpleListQuery q) {
    final uri = Uri(
      path: '/categories',
      queryParameters: simpleListQueryToParams(q),
    );
    context.go(uri.toString());
  }

  @override
  Widget build(BuildContext context) {
    final notifier = context.watch<CategoryListNotifier>();
    final q = notifier.query;
    final useCards = MediaQuery.sizeOf(context).width < 600;
    final actionVis = EntityActionVisibility.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Направления фонда'),
        actions: [
          if (actionVis.canManage && notifier.hasSelection)
            Center(child: Text('Выбрано: ${notifier.selected.length}  ')),
          if (actionVis.canManage && notifier.hasSelection)
            IconButton(
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
          RoleGate(
            minRole: AppRole.coordinator,
            builder: (context) => IconButton(
              icon: const Icon(Icons.add),
              onPressed: () async {
                await context.push('/categories/new');
                if (context.mounted) await notifier.load();
              },
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            DebouncedSearchField(
              initialValue: q.search,
              hint: 'Поиск по названию',
              onChanged: (t) => _pushQuery(q.copyWith(search: t)),
            ),
            SwitchListTile(
              title: const Text('Показывать удалённые'),
              value: q.includeDeleted,
              onChanged: (v) => _pushQuery(q.copyWith(includeDeleted: v)),
            ),
            Expanded(
              child: AsyncListBody(
                status: notifier.status,
                error: notifier.error,
                isEmpty: notifier.result.items.isEmpty,
                onRetry: notifier.load,
                child: useCards
                    ? ListView.builder(
                        itemCount: notifier.result.items.length,
                        itemBuilder: (context, i) {
                          final c = notifier.result.items[i];
                          return Card(
                            child: ListTile(
                              leading: actionVis.canManage
                                  ? Checkbox(
                                      value: notifier.selected.contains(c.id),
                                      onChanged: (_) =>
                                          notifier.toggleSelection(c.id),
                                    )
                                  : null,
                              title: Text(c.name),
                              onTap: () => context.go('/categories/${c.id}'),
                            ),
                          );
                        },
                      )
                    : EntityTable<FundCategory>(
                        items: notifier.result.items,
                        idOf: (c) => c.id,
                        selected: notifier.selected,
                        onToggleSelect: actionVis.canManage
                            ? notifier.toggleSelection
                            : null,
                        sortField: q.sortField,
                        sortAscending: q.sortAscending,
                        onSort: (f) => _pushQuery(
                          q.copyWith(
                            sortField: f,
                            sortAscending:
                                f == q.sortField ? !q.sortAscending : true,
                          ),
                        ),
                        columns: [
                          TableColumnSpec(
                            label: 'Название',
                            sortField: 'name',
                            build: (c) => Text(c.name),
                          ),
                        ],
                        actions: (c) => [
                          if (actionVis.canManage)
                            IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: () =>
                                  context.push('/categories/${c.id}/edit'),
                            ),
                          IconButton(
                            icon: const Icon(Icons.visibility),
                            onPressed: () => context.go('/categories/${c.id}'),
                          ),
                          if (actionVis.canAdmin && c.isDeleted)
                            IconButton(
                              icon: const Icon(Icons.restore),
                              onPressed: () async {
                                await notifier.restoreOne(c.id);
                                _pushQuery(notifier.query);
                              },
                            )
                          else if (actionVis.canManage && !c.isDeleted)
                            IconButton(
                              icon: const Icon(Icons.delete_outline),
                              onPressed: () async {
                                if (!await confirmSoftDelete(context, c.name)) {
                                  return;
                                }
                                await tryDeleteCategory(
                                  context,
                                  repository:
                                      context.read<CategoryRepository>(),
                                  categoryId: c.id,
                                  categoryName: c.name,
                                  onSuccess: () async {
                                    await notifier.load();
                                    _pushQuery(notifier.query);
                                  },
                                );
                              },
                            ),
                        ],
                      ),
              ),
            ),
            PaginationBar(
              result: notifier.result,
              onPage: (p) => _pushQuery(q.copyWith(page: p)),
              onSize: (s) => _pushQuery(q.copyWith(size: s)),
            ),
          ],
        ),
      ),
    );
  }
}
