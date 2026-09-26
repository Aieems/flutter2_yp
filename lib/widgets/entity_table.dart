import 'package:flutter/material.dart';

class TableColumnSpec<T> {
  final String label;
  final String? sortField;
  final bool numeric;
  final Widget Function(T item) build;

  const TableColumnSpec({
    required this.label,
    required this.build,
    this.sortField,
    this.numeric = false,
  });
}

class EntityTable<T> extends StatelessWidget {
  const EntityTable({
    super.key,
    required this.columns,
    required this.items,
    required this.idOf,
    this.selected = const {},
    this.onToggleSelect,
    this.sortField,
    this.sortAscending = true,
    this.onSort,
    this.actions,
  });

  final List<TableColumnSpec<T>> columns;
  final List<T> items;
  final int Function(T item) idOf;
  final Set<int> selected;
  final ValueChanged<int>? onToggleSelect;
  final String? sortField;
  final bool sortAscending;
  final void Function(String field)? onSort;
  final List<Widget> Function(T item)? actions;

  @override
  Widget build(BuildContext context) {
    final selectEnabled = onToggleSelect != null;

    return LayoutBuilder(
      builder: (context, constraints) {
        return Scrollbar(
          thumbVisibility: true,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: BoxConstraints(minWidth: constraints.maxWidth),
              child: SingleChildScrollView(
                child: DataTable(
                  sortColumnIndex: _sortColumnIndex(),
                  sortAscending: sortAscending,
                  columns: [
                    if (selectEnabled)
                      const DataColumn(label: Text('')),
                    ...columns.map((col) {
                      return DataColumn(
                        numeric: col.numeric,
                        onSort: col.sortField != null && onSort != null
                            ? (_, __) => onSort!(col.sortField!)
                            : null,
                        label: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(col.label),
                            if (col.sortField != null &&
                                col.sortField == sortField)
                              Icon(
                                sortAscending
                                    ? Icons.arrow_upward
                                    : Icons.arrow_downward,
                                size: 16,
                              ),
                          ],
                        ),
                      );
                    }),
                    if (actions != null) const DataColumn(label: Text('')),
                  ],
                  rows: items.map((item) {
                    final id = idOf(item);
                    return DataRow(
                      selected: selected.contains(id),
                      cells: [
                        if (selectEnabled)
                          DataCell(
                            Checkbox(
                              value: selected.contains(id),
                              onChanged: (_) => onToggleSelect!(id),
                            ),
                          ),
                        ...columns.map((col) => DataCell(col.build(item))),
                        if (actions != null)
                          DataCell(Row(children: actions!(item))),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  int? _sortColumnIndex() {
    if (sortField == null) return null;
    final index = columns.indexWhere((c) => c.sortField == sortField);
    if (index == -1) return null;
    return onToggleSelect != null ? index + 1 : index;
  }
}
