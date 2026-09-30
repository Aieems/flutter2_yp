import 'volunteer_card.dart';

class Volunteer {
  final int id;
  final String firstName;
  final String lastName;
  final String email;
  final VolunteerCard card;
  final DateTime? deletedAt;

  const Volunteer({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.card,
    this.deletedAt,
  });

  bool get isDeleted => deletedAt != null;

  String get displayName => '$lastName $firstName'.trim();

  Volunteer copyWith({
    String? firstName,
    String? lastName,
    String? email,
    VolunteerCard? card,
    DateTime? deletedAt,
    bool clearDeletedAt = false,
  }) {
    return Volunteer(
      id: id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      card: card ?? this.card,
      deletedAt: clearDeletedAt ? null : (deletedAt ?? this.deletedAt),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'firstName': firstName,
        'lastName': lastName,
        'email': email,
        'card': card.toJson(),
        'deletedAt': deletedAt?.toIso8601String(),
      };

  factory Volunteer.fromJson(Map<String, dynamic> json) => Volunteer(
        id: json['id'] as int? ?? 0,
        firstName: json['firstName'] as String? ?? '',
        lastName: json['lastName'] as String? ?? '',
        email: json['email'] as String? ?? '',
        card: VolunteerCard.fromJson(
          (json['card'] as Map?)?.cast<String, dynamic>() ?? const {},
        ),
        deletedAt: json['deletedAt'] == null
            ? null
            : DateTime.tryParse(json['deletedAt'] as String),
      );
}
