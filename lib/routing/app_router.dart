import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../auth/route_access.dart';
import '../models/app_role.dart';
import '../screens/admin/admin_stats_screen.dart';
import '../screens/admin/admin_users_screen.dart';
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
        builder: (context, state, child) => _AppShell(child: child),
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
            builder: (context, state) => TagQuerySync(
              uri: state.uri,
              child: const TagListScreen(),
            ),
            routes: [
              GoRoute(
                path: 'new',
                builder: (c, s) => const TagFormScreen(),
              ),
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
            builder: (c, s) => const AdminUsersScreen(),
          ),
          GoRoute(
            path: '/admin/stats',
            redirect: (c, s) => auth.has(AppRole.admin) ? null : '/forbidden',
            builder: (c, s) => const AdminStatsScreen(),
          ),
        ],
      ),
    ],
  );
}

class _AppShell extends StatelessWidget {
  const _AppShell({required this.child});

  final Widget child;

  List<String> _navPaths(AppRole role) => [
        if (RouteAccess.showNavSection(role, 'projects')) '/projects',
        if (RouteAccess.showNavSection(role, 'partners')) '/partners',
        if (RouteAccess.showNavSection(role, 'categories')) '/categories',
        if (RouteAccess.showNavSection(role, 'tags')) '/tags',
        if (RouteAccess.showNavSection(role, 'volunteers')) '/volunteers',
      ];

  int? _selectedIndex(BuildContext context, AppRole role) {
    final path = GoRouterState.of(context).uri.path;
    if (path.startsWith('/admin')) return null;
    final paths = _navPaths(role);
    for (var i = 0; i < paths.length; i++) {
      if (path.startsWith(paths[i])) return i;
    }
    return paths.isEmpty ? null : 0;
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthNotifier>();
    final role = auth.user!.role;
    final index = _selectedIndex(context, role);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Благотворительный фонд'),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Center(
              child: Text('${auth.user!.displayName} · ${role.label}'),
            ),
          ),
          if (RouteAccess.canAdminister(role))
            IconButton(
              tooltip: 'Пользователи',
              icon: const Icon(Icons.admin_panel_settings_outlined),
              onPressed: () => context.go('/admin/users'),
            ),
          if (RouteAccess.canAdminister(role))
            IconButton(
              tooltip: 'Статистика',
              icon: const Icon(Icons.insights_outlined),
              onPressed: () => context.go('/admin/stats'),
            ),
          IconButton(
            tooltip: 'Перечитать профиль из localStorage (после правки в DevTools)',
            icon: const Icon(Icons.refresh),
            onPressed: () => auth.reloadUiProfileFromStorage(),
          ),
          IconButton(
            tooltip: 'Выход',
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await auth.logout();
              if (context.mounted) context.go('/login');
            },
          ),
        ],
      ),
      body: Row(
        children: [
          if (index != null)
            NavigationRail(
              selectedIndex: index,
              onDestinationSelected: (i) {
                final paths = _navPaths(role);
                if (i >= 0 && i < paths.length) context.go(paths[i]);
              },
              labelType: NavigationRailLabelType.all,
              destinations: [
                if (RouteAccess.showNavSection(role, 'projects'))
                  const NavigationRailDestination(
                    icon: Icon(Icons.volunteer_activism_outlined),
                    selectedIcon: Icon(Icons.volunteer_activism),
                    label: Text('Проекты'),
                  ),
                if (RouteAccess.showNavSection(role, 'partners'))
                  const NavigationRailDestination(
                    icon: Icon(Icons.handshake_outlined),
                    selectedIcon: Icon(Icons.handshake),
                    label: Text('Партнёры'),
                  ),
                if (RouteAccess.showNavSection(role, 'categories'))
                  const NavigationRailDestination(
                    icon: Icon(Icons.category_outlined),
                    selectedIcon: Icon(Icons.category),
                    label: Text('Направления'),
                  ),
                if (RouteAccess.showNavSection(role, 'tags'))
                  const NavigationRailDestination(
                    icon: Icon(Icons.label_outlined),
                    selectedIcon: Icon(Icons.label),
                    label: Text('Теги'),
                  ),
                if (RouteAccess.showNavSection(role, 'volunteers'))
                  const NavigationRailDestination(
                    icon: Icon(Icons.people_outline),
                    selectedIcon: Icon(Icons.people),
                    label: Text('Волонтёры'),
                  ),
              ],
            ),
          if (index != null) const VerticalDivider(width: 1),
          Expanded(child: child),
        ],
      ),
    );
  }
}
