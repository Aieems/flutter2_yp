import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

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
import 'query_sync.dart';

final appRouter = GoRouter(
  initialLocation: '/projects',
  routes: [
    ShellRoute(
      builder: (context, state, child) => _AppShell(child: child),
      routes: [
        GoRoute(
          path: '/projects',
          builder: (context, state) => ProjectQuerySync(
            uri: state.uri,
            child: const ProjectListScreen(),
          ),
        ),
        GoRoute(
          path: '/projects/new',
          builder: (context, state) => const ProjectFormScreen(),
        ),
        GoRoute(
          path: '/projects/:id/edit',
          builder: (context, state) {
            final id = int.parse(state.pathParameters['id']!);
            return ProjectFormScreen(id: id);
          },
        ),
        GoRoute(
          path: '/projects/:id',
          builder: (context, state) {
            final id = int.parse(state.pathParameters['id']!);
            return ProjectDetailScreen(projectId: id);
          },
        ),
        GoRoute(
          path: '/partners',
          builder: (context, state) => PartnerQuerySync(
            uri: state.uri,
            child: const PartnerListScreen(),
          ),
        ),
        GoRoute(
          path: '/partners/new',
          builder: (context, state) => const PartnerFormScreen(),
        ),
        GoRoute(
          path: '/partners/:id/edit',
          builder: (context, state) {
            final id = int.parse(state.pathParameters['id']!);
            return PartnerFormScreen(id: id);
          },
        ),
        GoRoute(
          path: '/partners/:id',
          builder: (context, state) {
            final id = int.parse(state.pathParameters['id']!);
            return PartnerDetailScreen(partnerId: id);
          },
        ),
        GoRoute(
          path: '/categories',
          builder: (context, state) => CategoryQuerySync(
            uri: state.uri,
            child: const CategoryListScreen(),
          ),
        ),
        GoRoute(
          path: '/categories/new',
          builder: (context, state) => const CategoryFormScreen(),
        ),
        GoRoute(
          path: '/categories/:id/edit',
          builder: (context, state) {
            final id = int.parse(state.pathParameters['id']!);
            return CategoryFormScreen(id: id);
          },
        ),
        GoRoute(
          path: '/categories/:id',
          builder: (context, state) {
            final id = int.parse(state.pathParameters['id']!);
            return CategoryDetailScreen(categoryId: id);
          },
        ),
        GoRoute(
          path: '/tags',
          builder: (context, state) => TagQuerySync(
            uri: state.uri,
            child: const TagListScreen(),
          ),
        ),
        GoRoute(
          path: '/tags/new',
          builder: (context, state) => const TagFormScreen(),
        ),
        GoRoute(
          path: '/tags/:id/edit',
          builder: (context, state) {
            final id = int.parse(state.pathParameters['id']!);
            return TagFormScreen(id: id);
          },
        ),
        GoRoute(
          path: '/tags/:id',
          builder: (context, state) {
            final id = int.parse(state.pathParameters['id']!);
            return TagDetailScreen(tagId: id);
          },
        ),
        GoRoute(
          path: '/volunteers',
          builder: (context, state) => VolunteerQuerySync(
            uri: state.uri,
            child: const VolunteerListScreen(),
          ),
        ),
        GoRoute(
          path: '/volunteers/new',
          builder: (context, state) => const VolunteerFormScreen(),
        ),
        GoRoute(
          path: '/volunteers/:id/edit',
          builder: (context, state) {
            final id = int.parse(state.pathParameters['id']!);
            return VolunteerFormScreen(id: id);
          },
        ),
        GoRoute(
          path: '/volunteers/:id',
          builder: (context, state) {
            final id = int.parse(state.pathParameters['id']!);
            return VolunteerDetailScreen(volunteerId: id);
          },
        ),
      ],
    ),
  ],
);

class _AppShell extends StatelessWidget {
  const _AppShell({required this.child});

  final Widget child;

  int _selectedIndex(BuildContext context) {
    final path = GoRouterState.of(context).uri.path;
    if (path.startsWith('/partners')) return 1;
    if (path.startsWith('/categories')) return 2;
    if (path.startsWith('/tags')) return 3;
    if (path.startsWith('/volunteers')) return 4;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final index = _selectedIndex(context);
    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: index,
            onDestinationSelected: (i) {
              switch (i) {
                case 0:
                  context.go('/projects');
                case 1:
                  context.go('/partners');
                case 2:
                  context.go('/categories');
                case 3:
                  context.go('/tags');
                case 4:
                  context.go('/volunteers');
              }
            },
            labelType: NavigationRailLabelType.all,
            destinations: const [
              NavigationRailDestination(
                icon: Icon(Icons.volunteer_activism_outlined),
                selectedIcon: Icon(Icons.volunteer_activism),
                label: Text('Проекты'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.handshake_outlined),
                selectedIcon: Icon(Icons.handshake),
                label: Text('Партнёры'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.category_outlined),
                selectedIcon: Icon(Icons.category),
                label: Text('Направления'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.label_outlined),
                selectedIcon: Icon(Icons.label),
                label: Text('Теги'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.people_outline),
                selectedIcon: Icon(Icons.people),
                label: Text('Волонтёры'),
              ),
            ],
          ),
          const VerticalDivider(width: 1),
          Expanded(child: child),
        ],
      ),
    );
  }
}
