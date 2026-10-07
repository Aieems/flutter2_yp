import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/simple_list_query.dart';
import '../models/volunteer.dart';
import '../routing/query_params.dart';
import '../state/simple_entity_notifiers.dart';
import '../widgets/async_list_body.dart';
import '../widgets/debounced_search_field.dart';
import '../widgets/delete_dialogs.dart';
import '../widgets/entity_table.dart';
import '../models/app_role.dart';
import '../core/breakpoints.dart';
import '../widgets/entity_action_visibility.dart';
import '../widgets/pagination_bar.dart';
import '../widgets/role_gate.dart';

class VolunteerListScreen extends StatefulWidget {
  const VolunteerListScreen({super.key});

  @override
  State<VolunteerListScreen> createState() => _VolunteerListScreenState();
}

class _VolunteerListScreenState extends State<VolunteerListScreen> {
  void _pushQuery(SimpleListQuery q) {
    final uri = Uri(
      path: '/volunteers',
      queryParameters: simpleListQueryToParams(q),
    );
    context.go(uri.toString());
  }

  @override
  Widget build(BuildContext context) {
    final notifier = context.watch<VolunteerListNotifier>();
    final q = notifier.query;
    final useCards = !AppBreakpoints.useTableOnLists(context);
    final actionVis = EntityActionVisibility.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Волонтёры'),
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
                await context.push('/volunteers/new');
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
              hint: 'Фамилия или email',
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
                          final v = notifier.result.items[i];
                          return Card(
                            child: ListTile(
                              leading: actionVis.canManage
                                  ? Checkbox(
                                      value: notifier.selected.contains(v.id),
                                      onChanged: (_) =>
                                          notifier.toggleSelection(v.id),
                                    )
                                  : null,
                              title: Text(v.displayName),
                              subtitle: Text(v.email),
                              onTap: () => context.go('/volunteers/${v.id}'),
                            ),
                          );
                        },
                      )
                    : EntityTable<Volunteer>(
                        items: notifier.result.items,
                        idOf: (v) => v.id,
                        selected: notifier.selected,
                        onToggleSelect: actionVis.canManage
                            ? notifier.toggleSelection
                            : null,
                        sortField: q.sortField,
                        sortAscending: q.sortAscending,
                        onSort: (f) => _pushQuery(
                          q.copyWith(
                            sortField: f,
                            sortAscending: f == q.sortField
                                ? !q.sortAscending
                                : true,
                          ),
                        ),
                        columns: [
                          TableColumnSpec(
                            label: 'Фамилия',
                            sortField: 'lastName',
                            build: (v) => Text(v.displayName),
                          ),
                          TableColumnSpec(
                            label: 'Email',
                            sortField: 'email',
                            build: (v) => Text(v.email),
                          ),
                          TableColumnSpec(
                            label: 'Билет',
                            build: (v) => Text(v.card.cardNumber),
                          ),
                        ],
                        actions: (v) => [
                          if (actionVis.canManage)
                            IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: () =>
                                  context.push('/volunteers/${v.id}/edit'),
                            ),
                          IconButton(
                            icon: const Icon(Icons.visibility),
                            onPressed: () => context.go('/volunteers/${v.id}'),
                          ),
                          if (actionVis.canAdmin && v.isDeleted)
                            IconButton(
                              icon: const Icon(Icons.restore),
                              onPressed: () async {
                                await notifier.restoreOne(v.id);
                                _pushQuery(notifier.query);
                              },
                            )
                          else if (actionVis.canManage && !v.isDeleted)
                            IconButton(
                              icon: const Icon(Icons.delete_outline),
                              onPressed: () async {
                                if (await confirmSoftDelete(
                                  context,
                                  v.displayName,
                                )) {
                                  await notifier.softDeleteOne(v.id);
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
