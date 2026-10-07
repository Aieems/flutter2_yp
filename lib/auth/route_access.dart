import '../models/app_role.dart';

/// Клиентская проверка доступа к маршруту (удобство UI, не защита API).
class RouteAccess {
  static bool isPublicPath(String path) {
    return path == '/login' || path == '/register';
  }

  static AppRole? minRoleForPath(String path) {
    if (path.startsWith('/admin')) return AppRole.admin;
    if (path.startsWith('/categories') ||
        path.startsWith('/tags') ||
        path.startsWith('/volunteers')) {
      return AppRole.coordinator;
    }
    if (path.endsWith('/new') || path.contains('/edit')) {
      return AppRole.coordinator;
    }
    if (path.startsWith('/partners')) {
      return AppRole.volunteer;
    }
    if (path.startsWith('/projects')) {
      return AppRole.volunteer;
    }
    return AppRole.volunteer;
  }

  static bool canAccessPath(AppRole? role, String path) {
    if (isPublicPath(path) || path == '/forbidden') return true;
    if (role == null) return false;
    final required = minRoleForPath(path);
    if (required == null) return true;
    return role.satisfies(required);
  }

  static bool canManageEntities(AppRole role) =>
      role.satisfies(AppRole.coordinator);

  static bool canAdminister(AppRole role) => role.satisfies(AppRole.admin);

  static bool showNavSection(AppRole role, String section) {
    switch (section) {
      case 'projects':
      case 'partners':
        return true;
      case 'categories':
      case 'tags':
      case 'volunteers':
        return canManageEntities(role);
      case 'admin':
        return canAdminister(role);
      default:
        return false;
    }
  }
}
