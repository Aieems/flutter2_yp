import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/fund_category.dart';
import '../models/fund_tag.dart';
import '../models/simple_list_query.dart';
import '../repositories/category_repository.dart';
import '../routing/query_params.dart';
import '../state/simple_entity_notifiers.dart';
import '../widgets/async_list_body.dart';
import '../widgets/debounced_search_field.dart';
import '../widgets/delete_dialogs.dart';
import '../widgets/entity_table.dart';
import '../widgets/pagination_bar.dart';

class TagListScreen extends StatefulWidget {
  const TagListScreen({super.key});

  @override
  State<TagListScreen> createState() => _TagListScreenState();
}

class _TagListScreenState extends State<TagListScreen> {
  List<FundCategory> _categories = [];
  bool _catsLoaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_catsLoaded) {
      _catsLoaded = true;
      _loadCategories();
    }
  }

  Future<void> _loadCategories() async {
    final cats = await context.read<CategoryRepository>().listForSelect();
    if (mounted) setState(() => _categories = cats);
  }

  void _pushQuery(SimpleListQuery q) {
    final uri = Uri(
      path: '/tags',
      queryParameters: simpleListQueryToParams(q),
    );
    context.go(uri.toString());
  }

  @override
  Widget build(BuildContext context) {
    final notifier = context.watch<TagListNotifier>();
    final q = notifier.query;
    final useCards = MediaQuery.sizeOf(context).width < 600;
    final categoryNames = {for (final c in _categories) c.id: c.name};

    return Scaffold(
      appBar: AppBar(
        title: const Text('Теги проектов'),
        actions: [
          if (notifier.hasSelection)
            Center(child: Text('Выбрано: ${notifier.selected.length}  ')),
          if (notifier.hasSelection)
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
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () async {
              await context.push('/tags/new');
              if (context.mounted) await notifier.load();
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            DebouncedSearchField(
              initialValue: q.search,
              hint: 'Поиск',
              onChanged: (t) => _pushQuery(q.copyWith(search: t)),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<int?>(
              value: q.categoryId,
              decoration: const InputDecoration(
                labelText: 'Направление',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              items: [
                const DropdownMenuItem(value: null, child: Text('Все')),
                ..._categories.map(
                  (c) => DropdownMenuItem(value: c.id, child: Text(c.name)),
                ),
              ],
              onChanged: (v) => _pushQuery(q.copyWith(categoryId: v)),
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
                          final t = notifier.result.items[i];
                          return Card(
                            child: ListTile(
                              leading: Checkbox(
                                value: notifier.selected.contains(t.id),
                                onChanged: (_) =>
                                    notifier.toggleSelection(t.id),
                              ),
                              title: Text(t.name),
                              subtitle: Text(
                                categoryNames[t.categoryId] ?? '',
                              ),
                              onTap: () => context.go('/tags/${t.id}'),
                            ),
                          );
                        },
                      )
                    : EntityTable<FundTag>(
                        items: notifier.result.items,
                        idOf: (t) => t.id,
                        selected: notifier.selected,
                        onToggleSelect: notifier.toggleSelection,
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
                            build: (t) => Text(t.name),
                          ),
                          TableColumnSpec(
                            label: 'Направление',
                            sortField: 'categoryId',
                            numeric: true,
                            build: (t) => Text(
                              categoryNames[t.categoryId] ?? '${t.categoryId}',
                            ),
                          ),
                        ],
                        actions: (t) => [
                          IconButton(
                            icon: const Icon(Icons.edit),
                            onPressed: () => context.push('/tags/${t.id}/edit'),
                          ),
                          IconButton(
                            icon: const Icon(Icons.visibility),
                            onPressed: () => context.go('/tags/${t.id}'),
                          ),
                          if (t.isDeleted)
                            IconButton(
                              icon: const Icon(Icons.restore),
                              onPressed: () async {
                                await notifier.restoreOne(t.id);
                                _pushQuery(notifier.query);
                              },
                            )
                          else
                            IconButton(
                              icon: const Icon(Icons.delete_outline),
                              onPressed: () async {
                                if (await confirmSoftDelete(context, t.name)) {
                                  await notifier.softDeleteOne(t.id);
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
              onPage: (p) => _pushQuery(q.copyWith(page: p)),
              onSize: (s) => _pushQuery(q.copyWith(size: s)),
            ),
          ],
        ),
      ),
    );
  }
}
