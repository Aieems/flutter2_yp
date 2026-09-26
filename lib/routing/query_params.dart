import '../models/partner_query.dart';
import '../models/project_query.dart';

ProjectQuery projectQueryFromUri(Map<String, String> params) {
  final sortRaw = params['sort'];
  var sortField = 'title';
  var sortAscending = true;
  if (sortRaw != null && sortRaw.contains(',')) {
    final parts = sortRaw.split(',');
    sortField = parts[0];
    sortAscending = parts.length < 2 || parts[1] != 'desc';
  }
  return ProjectQuery(
    search: params['search'] ?? '',
    tagId: _parseInt(params['genreId'] ?? params['tagId']),
    categoryId: _parseInt(params['publisherId'] ?? params['categoryId']),
    yearFrom: _parseInt(params['yearFrom']),
    yearTo: _parseInt(params['yearTo']),
    sortField: sortField,
    sortAscending: sortAscending,
    page: _parseInt(params['page']) ?? 1,
    size: _parseInt(params['size']) ?? 10,
    includeDeleted: params['includeDeleted'] == 'true',
  );
}

Map<String, String> projectQueryToParams(ProjectQuery q) {
  final map = <String, String>{
    if (q.search.isNotEmpty) 'search': q.search,
    if (q.tagId != null) 'genreId': '${q.tagId}',
    if (q.categoryId != null) 'publisherId': '${q.categoryId}',
    if (q.yearFrom != null) 'yearFrom': '${q.yearFrom}',
    if (q.yearTo != null) 'yearTo': '${q.yearTo}',
    'sort': q.sortAscending ? '${q.sortField},asc' : '${q.sortField},desc',
    'page': '${q.page}',
    'size': '${q.size}',
    if (q.includeDeleted) 'includeDeleted': 'true',
  };
  return map;
}

PartnerQuery partnerQueryFromUri(Map<String, String> params) {
  final sortRaw = params['sort'];
  var sortField = 'lastName';
  var sortAscending = true;
  if (sortRaw != null && sortRaw.contains(',')) {
    final parts = sortRaw.split(',');
    sortField = parts[0];
    sortAscending = parts.length < 2 || parts[1] != 'desc';
  }
  return PartnerQuery(
    search: params['search'] ?? '',
    sortField: sortField,
    sortAscending: sortAscending,
    page: _parseInt(params['page']) ?? 1,
    size: _parseInt(params['size']) ?? 10,
    includeDeleted: params['includeDeleted'] == 'true',
  );
}

Map<String, String> partnerQueryToParams(PartnerQuery q) {
  return {
    if (q.search.isNotEmpty) 'search': q.search,
    'sort': q.sortAscending ? '${q.sortField},asc' : '${q.sortField},desc',
    'page': '${q.page}',
    'size': '${q.size}',
    if (q.includeDeleted) 'includeDeleted': 'true',
  };
}

int? _parseInt(String? value) {
  if (value == null || value.isEmpty) return null;
  return int.tryParse(value);
}
