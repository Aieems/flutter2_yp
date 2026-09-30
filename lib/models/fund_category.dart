class FundCategory {
  final int id;
  final String name;
  final DateTime? deletedAt;

  const FundCategory({
    required this.id,
    required this.name,
    this.deletedAt,
  });

  bool get isDeleted => deletedAt != null;

  FundCategory copyWith({
    String? name,
    DateTime? deletedAt,
    bool clearDeletedAt = false,
  }) {
    return FundCategory(
      id: id,
      name: name ?? this.name,
      deletedAt: clearDeletedAt ? null : (deletedAt ?? this.deletedAt),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'deletedAt': deletedAt?.toIso8601String(),
      };

  factory FundCategory.fromJson(Map<String, dynamic> json) => FundCategory(
        id: json['id'] as int? ?? 0,
        name: json['name'] as String? ?? '',
        deletedAt: json['deletedAt'] == null
            ? null
            : DateTime.tryParse(json['deletedAt'] as String),
      );
}
