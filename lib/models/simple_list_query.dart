class SimpleListQuery {
  final String search;
  final int? categoryId;
  final String sortField;
  final bool sortAscending;
  final int page;
  final int size;
  final bool includeDeleted;

  const SimpleListQuery({
    this.search = '',
    this.categoryId,
    this.sortField = 'name',
    this.sortAscending = true,
    this.page = 1,
    this.size = 10,
    this.includeDeleted = false,
  });

  SimpleListQuery copyWith({
    String? search,
    Object? categoryId = _unset,
    String? sortField,
    bool? sortAscending,
    int? page,
    int? size,
    bool? includeDeleted,
  }) {
    return SimpleListQuery(
      search: search ?? this.search,
      categoryId:
          categoryId == _unset ? this.categoryId : categoryId as int?,
      sortField: sortField ?? this.sortField,
      sortAscending: sortAscending ?? this.sortAscending,
      page: page ?? 1,
      size: size ?? this.size,
      includeDeleted: includeDeleted ?? this.includeDeleted,
    );
  }

  static const _unset = Object();
}
