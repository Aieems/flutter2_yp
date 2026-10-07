import '../models/volunteer.dart';
import '../models/volunteer_card.dart';

List<Volunteer> buildSeedVolunteers() => [
  Volunteer(
    id: 1,
    lastName: 'Иванова',
    firstName: 'Мария',
    email: 'maria.ivanova@example.com',
    card: VolunteerCard(
      cardNumber: 'VL-1001',
      issuedAt: DateTime(2023, 1, 10),
      expiresAt: DateTime(2026, 1, 10),
    ),
  ),
  Volunteer(
    id: 2,
    lastName: 'Петров',
    firstName: 'Алексей',
    email: 'alex.petrov@example.com',
    card: VolunteerCard(
      cardNumber: 'VL-1002',
      issuedAt: DateTime(2022, 6, 1),
      expiresAt: DateTime(2025, 6, 1),
    ),
  ),
  Volunteer(
    id: 3,
    lastName: 'Сидорова',
    firstName: 'Елена',
    email: 'elena.s@example.com',
    card: VolunteerCard(
      cardNumber: 'VL-1003',
      issuedAt: DateTime(2024, 3, 15),
      expiresAt: DateTime(2027, 3, 15),
    ),
  ),
  Volunteer(
    id: 4,
    lastName: 'Козлов',
    firstName: 'Дмитрий',
    email: 'd.kozlov@example.com',
    card: VolunteerCard(
      cardNumber: 'VL-1004',
      issuedAt: DateTime(2021, 9, 20),
      expiresAt: DateTime(2024, 9, 20),
    ),
  ),
  Volunteer(
    id: 5,
    lastName: 'Нурова',
    firstName: 'Алина',
    email: 'a.nurova@example.com',
    card: VolunteerCard(
      cardNumber: 'VL-1005',
      issuedAt: DateTime(2023, 11, 5),
      expiresAt: DateTime(2026, 11, 5),
    ),
  ),
  Volunteer(
    id: 6,
    lastName: 'Белый',
    firstName: 'Олег',
    email: 'oleg.bely@example.com',
    card: VolunteerCard(
      cardNumber: 'VL-1006',
      issuedAt: DateTime(2020, 2, 28),
      expiresAt: DateTime(2025, 2, 28),
    ),
  ),
  Volunteer(
    id: 7,
    lastName: 'Громова',
    firstName: 'Светлана',
    email: 'svetlana.g@example.com',
    card: VolunteerCard(
      cardNumber: 'VL-1007',
      issuedAt: DateTime(2024, 8, 1),
      expiresAt: DateTime(2027, 8, 1),
    ),
  ),
  Volunteer(
    id: 8,
    lastName: 'Якупов',
    firstName: 'Руслан',
    email: 'ruslan.y@example.com',
    card: VolunteerCard(
      cardNumber: 'VL-1008',
      issuedAt: DateTime(2022, 12, 12),
      expiresAt: DateTime(2025, 12, 12),
    ),
  ),
];
