class FundTag {
  final int id;
  final String name;
  final int categoryId;
  final DateTime? deletedAt;

  const FundTag({
    required this.id,
    required this.name,
    required this.categoryId,
    this.deletedAt,
  });

  bool get isDeleted => deletedAt != null;

  FundTag copyWith({
    String? name,
    int? categoryId,
    DateTime? deletedAt,
    bool clearDeletedAt = false,
  }) {
    return FundTag(
      id: id,
      name: name ?? this.name,
      categoryId: categoryId ?? this.categoryId,
      deletedAt: clearDeletedAt ? null : (deletedAt ?? this.deletedAt),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'categoryId': categoryId,
        'deletedAt': deletedAt?.toIso8601String(),
      };

  factory FundTag.fromJson(Map<String, dynamic> json) => FundTag(
        id: json['id'] as int? ?? 0,
        name: json['name'] as String? ?? '',
        categoryId: json['categoryId'] as int? ?? 0,
        deletedAt: json['deletedAt'] == null
            ? null
            : DateTime.tryParse(json['deletedAt'] as String),
      );
}
