enum AppRole {
  volunteer(1, 'volunteer', 'Волонтёр'),
  coordinator(2, 'coordinator', 'Координатор'),
  admin(3, 'admin', 'Администратор');

  const AppRole(this.level, this.apiValue, this.label);

  final int level;
  final String apiValue;
  final String label;

  static AppRole fromApi(String? value) {
    return AppRole.values.firstWhere(
      (r) => r.apiValue == value,
      orElse: () => AppRole.volunteer,
    );
  }

  bool satisfies(AppRole required) => level >= required.level;
}
