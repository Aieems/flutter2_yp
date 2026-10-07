import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/partner.dart';
import '../models/partner_query.dart';
import '../routing/query_params.dart';
import '../state/partner_list_notifier.dart';
import '../widgets/async_list_body.dart';
import '../widgets/debounced_search_field.dart';
import '../widgets/delete_dialogs.dart';
import '../widgets/entity_table.dart';
import '../widgets/pagination_bar.dart';
import '../models/app_role.dart';
import '../core/breakpoints.dart';
import '../widgets/entity_action_visibility.dart';
import '../widgets/role_gate.dart';

class PartnerListScreen extends StatefulWidget {
  const PartnerListScreen({super.key});

  @override
  State<PartnerListScreen> createState() => _PartnerListScreenState();
}

class _PartnerListScreenState extends State<PartnerListScreen> {
  void _pushQuery(PartnerQuery q) {
    final uri = Uri(
      path: '/partners',
      queryParameters: partnerQueryToParams(q),
    );
    context.go(uri.toString());
  }

  @override
  Widget build(BuildContext context) {
    final notifier = context.watch<PartnerListNotifier>();
    final q = notifier.query;
    final useCards = !AppBreakpoints.useTableOnLists(context);
    final actionVis = EntityActionVisibility.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Партнёры фонда'),
        actions: [
          if (actionVis.canManage && notifier.hasSelection)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Center(
                child: Text('Выбрано: ${notifier.selected.length}'),
              ),
            ),
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
                await context.push('/partners/new');
                if (context.mounted) {
                  await context.read<PartnerListNotifier>().load();
                }
              },
            ),
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
              hint: 'Фамилия / название или страна',
              onChanged: (text) => _pushQuery(q.copyWith(search: text)),
            ),
            const SizedBox(height: 12),
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
                    ? _PartnerCardList(
                        partners: notifier.result.items,
                        selected: notifier.selected,
                        selectionEnabled: actionVis.canManage,
                        onToggle: notifier.toggleSelection,
                        onOpen: (p) => context.go('/partners/${p.id}'),
                      )
                    : EntityTable<Partner>(
                        items: notifier.result.items,
                        idOf: (p) => p.id,
                        selected: notifier.selected,
                        onToggleSelect: actionVis.canManage
                            ? notifier.toggleSelection
                            : null,
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
                            sortField: 'lastName',
                            build: (p) => Text(
                              p.displayName,
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                          TableColumnSpec(
                            label: 'Страна',
                            sortField: 'country',
                            build: (p) => Text(p.country),
                          ),
                          TableColumnSpec(
                            label: 'Год осн.',
                            sortField: 'birthYear',
                            numeric: true,
                            build: (p) => Text('${p.birthYear}'),
                          ),
                        ],
                        actions: (p) => [
                          if (actionVis.canManage)
                            IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: () =>
                                  context.push('/partners/${p.id}/edit'),
                            ),
                          IconButton(
                            icon: const Icon(Icons.visibility),
                            onPressed: () => context.go('/partners/${p.id}'),
                          ),
                          if (actionVis.canAdmin && p.isDeleted)
                            IconButton(
                              icon: const Icon(Icons.restore),
                              onPressed: () async {
                                await notifier.restoreOne(p.id);
                                _pushQuery(notifier.query);
                              },
                            )
                          else if (actionVis.canManage && !p.isDeleted)
                            IconButton(
                              icon: const Icon(Icons.delete_outline),
                              onPressed: () async {
                                if (await confirmSoftDelete(
                                  context,
                                  p.displayName,
                                )) {
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

class _PartnerCardList extends StatelessWidget {
  const _PartnerCardList({
    required this.partners,
    required this.selected,
    required this.selectionEnabled,
    required this.onToggle,
    required this.onOpen,
  });

  final List<Partner> partners;
  final Set<int> selected;
  final bool selectionEnabled;
  final ValueChanged<int> onToggle;
  final ValueChanged<Partner> onOpen;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: partners.length,
      itemBuilder: (context, i) {
        final p = partners[i];
        return Card(
          child: ListTile(
            leading: selectionEnabled
                ? Checkbox(
                    value: selected.contains(p.id),
                    onChanged: (_) => onToggle(p.id),
                  )
                : null,
            title: Text(p.displayName),
            subtitle: Text('${p.country} · ${p.birthYear}'),
            onTap: () => onOpen(p),
          ),
        );
      },
    );
  }
}
