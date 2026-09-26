import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../screens/partner_detail_screen.dart';
import '../screens/partner_list_screen.dart';
import '../screens/project_detail_screen.dart';
import '../screens/project_list_screen.dart';
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
          path: '/partners/:id',
          builder: (context, state) {
            final id = int.parse(state.pathParameters['id']!);
            return PartnerDetailScreen(partnerId: id);
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
              if (i == 0) context.go('/projects');
              if (i == 1) context.go('/partners');
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
            ],
          ),
          const VerticalDivider(width: 1),
          Expanded(child: child),
        ],
      ),
    );
  }
}
