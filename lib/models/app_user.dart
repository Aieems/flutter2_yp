import 'app_role.dart';

class AppUser {
  const AppUser({
    required this.id,
    required this.username,
    required this.displayName,
    required this.role,
    this.authUserId,
  });

  final int id;
  final String username;
  final String displayName;
  final AppRole role;

  /// UUID в Supabase Auth / profiles (для смены роли админом).
  final String? authUserId;

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id'] as int,
      username: json['username'] as String,
      displayName:
          (json['displayName'] as String?) ?? json['username'] as String,
      role: AppRole.fromApi(json['role'] as String?),
      authUserId: json['authUserId'] as String?,
    );
  }
}

class AuthTokens {
  const AuthTokens({
    required this.accessToken,
    required this.refreshToken,
    required this.user,
  });

  final String accessToken;
  final String refreshToken;
  final AppUser user;
}
