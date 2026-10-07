import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../auth/route_access.dart';
import '../models/app_role.dart';
import '../screens/admin/admin_screens_deferred.dart';
import '../screens/auth/forbidden_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/category_detail_screen.dart';
import '../screens/category_list_screen.dart';
import '../screens/tag_detail_screen.dart';
import '../screens/forms/category_form_screen.dart';
import '../screens/forms/partner_form_screen.dart';
import '../screens/forms/project_form_screen.dart';
import '../screens/forms/tag_form_screen.dart';
import '../screens/forms/volunteer_form_screen.dart';
import '../screens/partner_detail_screen.dart';
import '../screens/partner_list_screen.dart';
import '../screens/project_detail_screen.dart';
import '../screens/project_list_screen.dart';
import '../screens/tag_list_screen.dart';
import '../screens/volunteer_detail_screen.dart';
import '../screens/volunteer_list_screen.dart';
import '../state/auth_notifier.dart';
import '../widgets/adaptive_app_shell.dart';
import 'query_sync.dart';

GoRouter buildAppRouter(AuthNotifier auth) {
  String? globalRedirect(BuildContext context, GoRouterState state) {
    final loggedIn = auth.isAuthenticated;
    final target = state.matchedLocation;
    if (RouteAccess.isPublicPath(target)) {
      if (loggedIn) return '/projects';
      return null;
    }
    if (!loggedIn) {
      return '/login?from=${Uri.encodeComponent(state.uri.toString())}';
    }
    if (!RouteAccess.canAccessPath(auth.user?.role, target)) {
      return '/forbidden';
    }
    return null;
  }

  return GoRouter(
    refreshListenable: auth,
    initialLocation: '/projects',
    redirect: globalRedirect,
    routes: [
      GoRoute(path: '/login', builder: (c, s) => const LoginScreen()),
      GoRoute(path: '/register', builder: (c, s) => const RegisterScreen()),
      GoRoute(path: '/forbidden', builder: (c, s) => const ForbiddenScreen()),
      ShellRoute(
        builder: (context, state, child) => AdaptiveAppShell(child: child),
        routes: [
          GoRoute(
            path: '/projects',
            builder: (context, state) => ProjectQuerySync(
              uri: state.uri,
              child: const ProjectListScreen(),
            ),
            routes: [
              GoRoute(
                path: 'new',
                redirect: (c, s) =>
                    auth.has(AppRole.coordinator) ? null : '/forbidden',
                builder: (c, s) => const ProjectFormScreen(),
              ),
              GoRoute(
                path: ':id',
                builder: (c, s) {
                  final id = int.parse(s.pathParameters['id']!);
                  return ProjectDetailScreen(projectId: id);
                },
                routes: [
                  GoRoute(
                    path: 'edit',
                    redirect: (c, s) =>
                        auth.has(AppRole.coordinator) ? null : '/forbidden',
                    builder: (c, s) {
                      final id = int.parse(s.pathParameters['id']!);
                      return ProjectFormScreen(id: id);
                    },
                  ),
                ],
              ),
            ],
          ),
          GoRoute(
            path: '/partners',
            builder: (context, state) => PartnerQuerySync(
              uri: state.uri,
              child: const PartnerListScreen(),
            ),
            routes: [
              GoRoute(
                path: 'new',
                redirect: (c, s) =>
                    auth.has(AppRole.coordinator) ? null : '/forbidden',
                builder: (c, s) => const PartnerFormScreen(),
              ),
              GoRoute(
                path: ':id',
                builder: (c, s) {
                  final id = int.parse(s.pathParameters['id']!);
                  return PartnerDetailScreen(partnerId: id);
                },
                routes: [
                  GoRoute(
                    path: 'edit',
                    redirect: (c, s) =>
                        auth.has(AppRole.coordinator) ? null : '/forbidden',
                    builder: (c, s) {
                      final id = int.parse(s.pathParameters['id']!);
                      return PartnerFormScreen(id: id);
                    },
                  ),
                ],
              ),
            ],
          ),
          GoRoute(
            path: '/categories',
            redirect: (c, s) =>
                auth.has(AppRole.coordinator) ? null : '/forbidden',
            builder: (context, state) => CategoryQuerySync(
              uri: state.uri,
              child: const CategoryListScreen(),
            ),
            routes: [
              GoRoute(
                path: 'new',
                builder: (c, s) => const CategoryFormScreen(),
              ),
              GoRoute(
                path: ':id',
                builder: (c, s) {
                  final id = int.parse(s.pathParameters['id']!);
                  return CategoryDetailScreen(categoryId: id);
                },
                routes: [
                  GoRoute(
                    path: 'edit',
                    builder: (c, s) {
                      final id = int.parse(s.pathParameters['id']!);
                      return CategoryFormScreen(id: id);
                    },
                  ),
                ],
              ),
            ],
          ),
          GoRoute(
            path: '/tags',
            redirect: (c, s) =>
                auth.has(AppRole.coordinator) ? null : '/forbidden',
            builder: (context, state) =>
                TagQuerySync(uri: state.uri, child: const TagListScreen()),
            routes: [
              GoRoute(path: 'new', builder: (c, s) => const TagFormScreen()),
              GoRoute(
                path: ':id',
                builder: (c, s) {
                  final id = int.parse(s.pathParameters['id']!);
                  return TagDetailScreen(tagId: id);
                },
                routes: [
                  GoRoute(
                    path: 'edit',
                    builder: (c, s) {
                      final id = int.parse(s.pathParameters['id']!);
                      return TagFormScreen(id: id);
                    },
                  ),
                ],
              ),
            ],
          ),
          GoRoute(
            path: '/volunteers',
            redirect: (c, s) =>
                auth.has(AppRole.coordinator) ? null : '/forbidden',
            builder: (context, state) => VolunteerQuerySync(
              uri: state.uri,
              child: const VolunteerListScreen(),
            ),
            routes: [
              GoRoute(
                path: 'new',
                builder: (c, s) => const VolunteerFormScreen(),
              ),
              GoRoute(
                path: ':id',
                builder: (c, s) {
                  final id = int.parse(s.pathParameters['id']!);
                  return VolunteerDetailScreen(volunteerId: id);
                },
                routes: [
                  GoRoute(
                    path: 'edit',
                    builder: (c, s) {
                      final id = int.parse(s.pathParameters['id']!);
                      return VolunteerFormScreen(id: id);
                    },
                  ),
                ],
              ),
            ],
          ),
          GoRoute(
            path: '/admin/users',
            redirect: (c, s) => auth.has(AppRole.admin) ? null : '/forbidden',
            builder: (c, s) => const DeferredAdminUsersScreen(),
          ),
          GoRoute(
            path: '/admin/stats',
            redirect: (c, s) => auth.has(AppRole.admin) ? null : '/forbidden',
            builder: (c, s) => const DeferredAdminStatsScreen(),
          ),
        ],
      ),
    ],
  );
}
