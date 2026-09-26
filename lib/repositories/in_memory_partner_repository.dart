import '../data/seed_partners.dart';
import '../models/page_result.dart';
import '../models/partner.dart';
import '../models/partner_query.dart';
import 'partner_repository.dart';

class InMemoryPartnerRepository implements PartnerRepository {
  final List<Partner> _partners = [...seedPartners];
  int _nextId = seedPartners.length + 1;

  @override
  Future<PageResult<Partner>> find(PartnerQuery q) async {
    await Future.delayed(const Duration(milliseconds: 250));
    var rows =
        _partners.where((p) => q.includeDeleted || !p.isDeleted).toList();
    if (q.search.trim().isNotEmpty) {
      final needle = q.search.trim().toLowerCase();
      rows = rows
          .where(
            (p) =>
                p.lastName.toLowerCase().contains(needle) ||
                p.country.toLowerCase().contains(needle),
          )
          .toList();
    }
    rows.sort((a, b) {
      final result = switch (q.sortField) {
        'country' => a.country.toLowerCase().compareTo(b.country.toLowerCase()),
        'birthYear' => a.birthYear.compareTo(b.birthYear),
        _ => a.lastName.toLowerCase().compareTo(b.lastName.toLowerCase()),
      };
      return q.sortAscending ? result : -result;
    });
    final total = rows.length;
    final from = (q.page - 1) * q.size;
    final to = (from + q.size) > total ? total : (from + q.size);
    final items = from >= total ? <Partner>[] : rows.sublist(from, to);
    return PageResult(
      items: items,
      page: q.page,
      size: q.size,
      total: total,
    );
  }

  @override
  Future<Partner?> findById(int id) async {
    await Future.delayed(const Duration(milliseconds: 100));
    try {
      return _partners.firstWhere((p) => p.id == id);
    } on StateError {
      return null;
    }
  }

  @override
  Future<Partner> create(Partner partner) async {
    final created = Partner(
      id: _nextId++,
      lastName: partner.lastName,
      firstName: partner.firstName,
      country: partner.country,
      birthYear: partner.birthYear,
    );
    _partners.add(created);
    return created;
  }

  @override
  Future<Partner> update(Partner partner) async {
    final i = _partners.indexWhere((p) => p.id == partner.id);
    if (i == -1) throw StateError('Партнёр ${partner.id} не найден');
    _partners[i] = partner;
    return partner;
  }

  @override
  Future<void> softDelete(int id) async {
    final i = _partners.indexWhere((p) => p.id == id);
    if (i == -1) throw StateError('Партнёр $id не найден');
    _partners[i] = _partners[i].copyWith(deletedAt: DateTime.now());
  }

  @override
  Future<void> hardDelete(int id) async {
    _partners.removeWhere((p) => p.id == id);
  }

  @override
  Future<void> restore(int id) async {
    final i = _partners.indexWhere((p) => p.id == id);
    if (i == -1) throw StateError('Партнёр $id не найден');
    _partners[i] = _partners[i].copyWith(clearDeletedAt: true);
  }

  @override
  Future<int> deleteMany(List<int> ids) async {
    var count = 0;
    for (final id in ids) {
      final i = _partners.indexWhere((p) => p.id == id && !p.isDeleted);
      if (i != -1) {
        _partners[i] = _partners[i].copyWith(deletedAt: DateTime.now());
        count++;
      }
    }
    return count;
  }
}
