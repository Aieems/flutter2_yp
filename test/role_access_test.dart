import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_2/auth/route_access.dart';
import 'package:flutter_2/models/app_role.dart';

void main() {
  group('RouteAccess', () {
    test('волонтёр видит проекты и партнёров', () {
      expect(RouteAccess.canAccessPath(AppRole.volunteer, '/projects'), isTrue);
      expect(RouteAccess.canAccessPath(AppRole.volunteer, '/partners/1'), isTrue);
    });

    test('волонтёр не попадает в справочники и формы', () {
      expect(RouteAccess.canAccessPath(AppRole.volunteer, '/categories'), isFalse);
      expect(RouteAccess.canAccessPath(AppRole.volunteer, '/projects/new'), isFalse);
      expect(RouteAccess.canAccessPath(AppRole.volunteer, '/volunteers'), isFalse);
    });

    test('координатор управляет сущностями, но не админкой', () {
      expect(RouteAccess.canAccessPath(AppRole.coordinator, '/tags/new'), isTrue);
      expect(RouteAccess.canAccessPath(AppRole.coordinator, '/admin/users'), isFalse);
      expect(RouteAccess.canAccessPath(AppRole.coordinator, '/admin/stats'), isFalse);
    });

    test('администратор видит админ-разделы', () {
      expect(RouteAccess.canAccessPath(AppRole.admin, '/admin/users'), isTrue);
      expect(RouteAccess.canAccessPath(AppRole.admin, '/admin/stats'), isTrue);
    });

    test('иерархия ролей для операций', () {
      expect(RouteAccess.canManageEntities(AppRole.volunteer), isFalse);
      expect(RouteAccess.canManageEntities(AppRole.coordinator), isTrue);
      expect(RouteAccess.canAdminister(AppRole.coordinator), isFalse);
      expect(RouteAccess.canAdminister(AppRole.admin), isTrue);
    });
  });
}
