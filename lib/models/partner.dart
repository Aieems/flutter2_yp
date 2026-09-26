class Partner {
  final int id;
  final String lastName;
  final String firstName;
  final String country;
  final int birthYear;
  final DateTime? deletedAt;

  const Partner({
    required this.id,
    required this.lastName,
    required this.firstName,
    required this.country,
    required this.birthYear,
    this.deletedAt,
  });

  bool get isDeleted => deletedAt != null;

  String get displayName => '$lastName $firstName'.trim();

  Partner copyWith({
    String? lastName,
    String? firstName,
    String? country,
    int? birthYear,
    DateTime? deletedAt,
    bool clearDeletedAt = false,
  }) {
    return Partner(
      id: id,
      lastName: lastName ?? this.lastName,
      firstName: firstName ?? this.firstName,
      country: country ?? this.country,
      birthYear: birthYear ?? this.birthYear,
      deletedAt: clearDeletedAt ? null : (deletedAt ?? this.deletedAt),
    );
  }
}
