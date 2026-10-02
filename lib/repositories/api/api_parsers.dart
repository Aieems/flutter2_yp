import '../../models/fund_category.dart';
import '../../models/fund_tag.dart';
import '../../models/page_result.dart';
import '../../models/partner.dart';
import '../../models/project.dart';
import '../../models/volunteer.dart';
import '../../models/volunteer_card.dart';

PageResult<T> parsePage<T>(
  Map<String, dynamic> data,
  T Function(Map<String, dynamic>) fromJson,
) {
  final itemsRaw = data['items'];
  final items = itemsRaw is List
      ? itemsRaw
          .whereType<Map>()
          .map((e) => fromJson(e.cast<String, dynamic>()))
          .toList()
      : <T>[];
  return PageResult(
    items: items,
    page: data['page'] as int? ?? 1,
    size: data['size'] as int? ?? items.length,
    total: data['total'] as int? ?? items.length,
  );
}

Project projectFromApi(Map<String, dynamic> json) {
  final partnerIds = _ids(json, 'partnerIds', 'partners');
  final tagIds = _ids(json, 'tagIds', 'tags');
  return Project(
    id: json['id'] as int? ?? 0,
    title: json['title'] as String? ?? '',
    code: json['code'] as String? ?? '',
    year: json['year'] as int? ?? 0,
    goalAmount: json['goalAmount'] as int? ?? 0,
    categoryId: json['categoryId'] as int? ?? 0,
    partnerIds: partnerIds,
    tagIds: tagIds,
    volunteersTotal: json['volunteersTotal'] as int? ?? 0,
    volunteersActive: json['volunteersActive'] as int? ?? 0,
    deletedAt: json['deletedAt'] == null
        ? null
        : DateTime.tryParse(json['deletedAt'] as String),
  );
}

List<int> _ids(Map<String, dynamic> json, String idsKey, String objectsKey) {
  if (json[idsKey] is List) {
    return (json[idsKey] as List).map((e) => e as int).toList();
  }
  if (json[objectsKey] is List) {
    return (json[objectsKey] as List)
        .whereType<Map>()
        .map((e) => e['id'] as int)
        .toList();
  }
  return const [];
}

Map<String, dynamic> projectToApiBody(Project project) => {
      'title': project.title,
      'code': project.code,
      'year': project.year,
      'goalAmount': project.goalAmount,
      'categoryId': project.categoryId,
      'partnerIds': project.partnerIds,
      'tagIds': project.tagIds,
      'volunteersTotal': project.volunteersTotal,
      'volunteersActive': project.volunteersActive,
    };

FundCategory categoryFromApi(Map<String, dynamic> json) => FundCategory(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      deletedAt: json['deletedAt'] == null
          ? null
          : DateTime.tryParse(json['deletedAt'] as String),
    );

FundTag tagFromApi(Map<String, dynamic> json) => FundTag(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      categoryId: json['categoryId'] as int? ?? 0,
      deletedAt: json['deletedAt'] == null
          ? null
          : DateTime.tryParse(json['deletedAt'] as String),
    );

Map<String, dynamic> tagToApiBody(FundTag tag) => {
      'name': tag.name,
      'categoryId': tag.categoryId,
    };

Partner partnerFromApi(Map<String, dynamic> json) => Partner(
      id: json['id'] as int? ?? 0,
      lastName: json['lastName'] as String? ?? '',
      firstName: json['firstName'] as String? ?? '',
      country: json['country'] as String? ?? '',
      birthYear: json['birthYear'] as int? ?? 0,
      deletedAt: json['deletedAt'] == null
          ? null
          : DateTime.tryParse(json['deletedAt'] as String),
    );

Volunteer volunteerFromApi(Map<String, dynamic> json) {
  final cardRaw = json['card'];
  final cardMap = cardRaw is Map
      ? cardRaw.cast<String, dynamic>()
      : const <String, dynamic>{};
  return Volunteer(
    id: json['id'] as int? ?? 0,
    firstName: json['firstName'] as String? ?? '',
    lastName: json['lastName'] as String? ?? '',
    email: json['email'] as String? ?? '',
    card: VolunteerCard(
      cardNumber: cardMap['cardNumber'] as String? ?? '',
      issuedAt: DateTime.tryParse(cardMap['issuedAt'] as String? ?? '') ??
          DateTime.now(),
      expiresAt: DateTime.tryParse(cardMap['expiresAt'] as String? ?? '') ??
          DateTime.now().add(const Duration(days: 365)),
    ),
    deletedAt: json['deletedAt'] == null
        ? null
        : DateTime.tryParse(json['deletedAt'] as String),
  );
}

Map<String, dynamic> volunteerToApiBody(Volunteer v) => {
      'firstName': v.firstName,
      'lastName': v.lastName,
      'email': v.email,
      'card': {
        'cardNumber': v.card.cardNumber,
        'issuedAt': v.card.issuedAt.toIso8601String(),
        'expiresAt': v.card.expiresAt.toIso8601String(),
      },
    };

String projectSortToApi(String field) => field;
