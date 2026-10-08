import '../../models/page_result.dart';

PageResult<T> paginateInMemory<T>({
  required List<T> all,
  required int page,
  required int size,
}) {
  final safeSize = size <= 0 ? 10 : size;
  final safePage = page <= 0 ? 1 : page;
  final start = (safePage - 1) * safeSize;
  if (start >= all.length) {
    return PageResult(items: const [], page: safePage, size: safeSize, total: all.length);
  }
  final end = (start + safeSize).clamp(0, all.length);
  return PageResult(
    items: all.sublist(start, end),
    page: safePage,
    size: safeSize,
    total: all.length,
  );
}
