class Project {
  final int id;
  final String title;
  final String code;
  final int year;
  final int goalAmount;
  final int categoryId;
  final List<int> partnerIds;
  final List<int> tagIds;
  final int volunteersTotal;
  final int volunteersActive;
  final DateTime? deletedAt;

  const Project({
    required this.id,
    required this.title,
    required this.code,
    required this.year,
    required this.goalAmount,
    required this.categoryId,
    required this.partnerIds,
    required this.tagIds,
    required this.volunteersTotal,
    required this.volunteersActive,
    this.deletedAt,
  });

  bool get isDeleted => deletedAt != null;

  Project copyWith({
    String? title,
    String? code,
    int? year,
    int? goalAmount,
    int? categoryId,
    List<int>? partnerIds,
    List<int>? tagIds,
    int? volunteersTotal,
    int? volunteersActive,
    DateTime? deletedAt,
    bool clearDeletedAt = false,
  }) {
    return Project(
      id: id,
      title: title ?? this.title,
      code: code ?? this.code,
      year: year ?? this.year,
      goalAmount: goalAmount ?? this.goalAmount,
      categoryId: categoryId ?? this.categoryId,
      partnerIds: partnerIds ?? this.partnerIds,
      tagIds: tagIds ?? this.tagIds,
      volunteersTotal: volunteersTotal ?? this.volunteersTotal,
      volunteersActive: volunteersActive ?? this.volunteersActive,
      deletedAt: clearDeletedAt ? null : (deletedAt ?? this.deletedAt),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'code': code,
    'year': year,
    'goalAmount': goalAmount,
    'categoryId': categoryId,
    'partnerIds': partnerIds,
    'tagIds': tagIds,
    'volunteersTotal': volunteersTotal,
    'volunteersActive': volunteersActive,
    'deletedAt': deletedAt?.toIso8601String(),
  };

  factory Project.fromJson(Map<String, dynamic> json) => Project(
    id: json['id'] as int? ?? 0,
    title: json['title'] as String? ?? '',
    code: (json['code'] as String?)?.trim().isNotEmpty == true
        ? (json['code'] as String).trim()
        : (json['isbn'] as String?)?.trim() ?? '',
    year: json['year'] as int? ?? 0,
    goalAmount: json['goalAmount'] as int? ?? 0,
    categoryId: json['categoryId'] as int? ?? 0,
    partnerIds:
        (json['partnerIds'] as List?)?.map((e) => e as int).toList() ??
        const [],
    tagIds:
        (json['tagIds'] as List?)?.map((e) => e as int).toList() ?? const [],
    volunteersTotal: json['volunteersTotal'] as int? ?? 0,
    volunteersActive: json['volunteersActive'] as int? ?? 0,
    deletedAt: json['deletedAt'] == null
        ? null
        : DateTime.tryParse(json['deletedAt'] as String),
  );
}
