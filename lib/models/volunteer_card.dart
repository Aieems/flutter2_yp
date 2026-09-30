class VolunteerCard {
  final String cardNumber;
  final DateTime issuedAt;
  final DateTime expiresAt;

  const VolunteerCard({
    required this.cardNumber,
    required this.issuedAt,
    required this.expiresAt,
  });

  VolunteerCard copyWith({
    String? cardNumber,
    DateTime? issuedAt,
    DateTime? expiresAt,
  }) {
    return VolunteerCard(
      cardNumber: cardNumber ?? this.cardNumber,
      issuedAt: issuedAt ?? this.issuedAt,
      expiresAt: expiresAt ?? this.expiresAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'cardNumber': cardNumber,
        'issuedAt': issuedAt.toIso8601String(),
        'expiresAt': expiresAt.toIso8601String(),
      };

  factory VolunteerCard.fromJson(Map<String, dynamic> json) => VolunteerCard(
        cardNumber: json['cardNumber'] as String? ?? '',
        issuedAt: DateTime.tryParse(json['issuedAt'] as String? ?? '') ??
            DateTime.now(),
        expiresAt: DateTime.tryParse(json['expiresAt'] as String? ?? '') ??
            DateTime.now().add(const Duration(days: 365)),
      );
}
