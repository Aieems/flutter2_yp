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
}
