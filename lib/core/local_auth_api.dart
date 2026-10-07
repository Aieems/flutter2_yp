import '../models/app_role.dart';
import '../models/app_user.dart';
import 'api_exceptions.dart';

class _SeedUser {
  const _SeedUser(this.username, this.password, this.role, this.name);

  final String username;
  final String password;
  final AppRole role;
  final String name;
}

/// Учебный вход без сервера (режим USE_API=false).
class LocalAuthApi {
  static const _users = [
    _SeedUser('volunteer1', 'VolunteeR1!', AppRole.volunteer, 'Иван Волонтёр'),
    _SeedUser('coord1', 'Coordinat0r!', AppRole.coordinator, 'Мария Координатор'),
    _SeedUser('admin', 'Admin123!', AppRole.admin, 'Администратор'),
  ];

  int _nextId = 100;

  Future<AuthTokens> login(String username, String password) async {
    _SeedUser? row;
    for (final u in _users) {
      if (u.username == username && u.password == password) {
        row = u;
        break;
      }
    }
    if (row == null) {
      throw const UnauthorizedException('Неверный логин или пароль.');
    }
    final user = AppUser(
      id: _users.indexOf(row) + 1,
      username: row.username,
      displayName: row.name,
      role: row.role,
    );
    return AuthTokens(
      accessToken: 'local-access-${user.id}',
      refreshToken: 'local-refresh-${user.id}',
      user: user,
    );
  }

  Future<AuthTokens> register({
    required String username,
    required String password,
    required String displayName,
  }) async {
    if (_users.any((u) => u.username == username)) {
      throw ValidationException('Ошибка регистрации', {
        'username': 'Имя пользователя уже занято',
      });
    }
    final id = _nextId++;
    final user = AppUser(
      id: id,
      username: username,
      displayName: displayName,
      role: AppRole.volunteer,
    );
    return AuthTokens(
      accessToken: 'local-access-$id',
      refreshToken: 'local-refresh-$id',
      user: user,
    );
  }

  Future<AuthTokens> refresh(String refreshToken) async {
    if (!refreshToken.startsWith('local-refresh-')) {
      throw const UnauthorizedException('Сессия истекла.');
    }
    final id = int.tryParse(refreshToken.replaceFirst('local-refresh-', ''));
    if (id == null) throw const UnauthorizedException('Сессия истекла.');
    return AuthTokens(
      accessToken: 'local-access-$id',
      refreshToken: refreshToken,
      user: await meFromAccessToken('local-access-$id'),
    );
  }

  Future<AppUser> meFromAccessToken(String? accessToken) async {
    if (accessToken == null || !accessToken.startsWith('local-access-')) {
      throw const UnauthorizedException();
    }
    final id = int.parse(accessToken.replaceFirst('local-access-', ''));
    if (id >= 1 && id <= _users.length) {
      final row = _users[id - 1];
      return AppUser(
        id: id,
        username: row.username,
        displayName: row.name,
        role: row.role,
      );
    }
    return AppUser(
      id: id,
      username: 'user$id',
      displayName: 'Пользователь $id',
      role: AppRole.volunteer,
    );
  }

  Future<List<AppUser>> listUsers() async => [
        for (var i = 0; i < _users.length; i++)
          AppUser(
            id: i + 1,
            username: _users[i].username,
            displayName: _users[i].name,
            role: _users[i].role,
          ),
      ];

  Future<AppUser> updateUserRole(int id, String role) async {
    throw const ForbiddenException('Смена ролей доступна только с API-сервером.');
  }

  Future<Map<String, int>> stats() async => {
        'projects': 12,
        'partners': 8,
        'volunteers': 4,
        'categories': 5,
      };
}
