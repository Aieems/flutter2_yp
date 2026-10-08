import '../../models/project.dart';

Map<String, dynamic> projectRowToApi(Map<String, dynamic> row) => {
  'id': row['id'],
  'title': row['title'],
  'code': row['code'],
  'year': row['year'],
  'goalAmount': row['goal_amount'],
  'categoryId': row['category_id'],
  'partnerIds': row['partner_ids'] ?? [],
  'tagIds': row['tag_ids'] ?? [],
  'volunteersTotal': row['volunteers_total'],
  'volunteersActive': row['volunteers_active'],
  'deletedAt': row['deleted_at'],
};

Map<String, dynamic> projectToRow(Project p) => {
  'title': p.title,
  'code': p.code,
  'year': p.year,
  'goal_amount': p.goalAmount,
  'category_id': p.categoryId,
  'partner_ids': p.partnerIds,
  'tag_ids': p.tagIds,
  'volunteers_total': p.volunteersTotal,
  'volunteers_active': p.volunteersActive,
};

Map<String, dynamic> categoryRowToApi(Map<String, dynamic> row) => {
  'id': row['id'],
  'name': row['name'],
  'deletedAt': row['deleted_at'],
};

Map<String, dynamic> partnerRowToApi(Map<String, dynamic> row) => {
  'id': row['id'],
  'lastName': row['last_name'],
  'firstName': row['first_name'],
  'country': row['country'],
  'birthYear': row['birth_year'],
  'deletedAt': row['deleted_at'],
};

Map<String, dynamic> tagRowToApi(Map<String, dynamic> row) => {
  'id': row['id'],
  'name': row['name'],
  'categoryId': row['category_id'],
  'deletedAt': row['deleted_at'],
};

Map<String, dynamic> volunteerRowToApi(Map<String, dynamic> row) => {
  'id': row['id'],
  'firstName': row['first_name'],
  'lastName': row['last_name'],
  'email': row['email'],
  'deletedAt': row['deleted_at'],
  'card': {
    'cardNumber': row['card_number'],
    'issuedAt': row['card_issued_at'],
    'expiresAt': row['card_expires_at'],
  },
};
