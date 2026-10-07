import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../auth/route_access.dart';
import '../core/breakpoints.dart';
import '../models/app_role.dart';
import '../state/auth_notifier.dart';
import 'responsive_content.dart';

class AdaptiveAppShell extends StatelessWidget {
  const AdaptiveAppShell({super.key, required this.child});

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

  List<NavigationDestination> _bottomDestinations(AppRole role) => [
    if (RouteAccess.showNavSection(role, 'projects'))
      const NavigationDestination(
        icon: Icon(Icons.volunteer_activism_outlined),
        selectedIcon: Icon(Icons.volunteer_activism),
        label: 'Проекты',
      ),
    if (RouteAccess.showNavSection(role, 'partners'))
      const NavigationDestination(
        icon: Icon(Icons.handshake_outlined),
        selectedIcon: Icon(Icons.handshake),
        label: 'Партнёры',
      ),
    if (RouteAccess.showNavSection(role, 'categories'))
      const NavigationDestination(
        icon: Icon(Icons.category_outlined),
        selectedIcon: Icon(Icons.category),
        label: 'Направления',
      ),
    if (RouteAccess.showNavSection(role, 'tags'))
      const NavigationDestination(
        icon: Icon(Icons.label_outlined),
        selectedIcon: Icon(Icons.label),
        label: 'Теги',
      ),
    if (RouteAccess.showNavSection(role, 'volunteers'))
      const NavigationDestination(
        icon: Icon(Icons.people_outline),
        selectedIcon: Icon(Icons.people),
        label: 'Волонтёры',
      ),
  ];

  List<NavigationRailDestination> _railDestinations(AppRole role) => [
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
  ];

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthNotifier>();
    final role = auth.user!.role;
    final index = _selectedIndex(context, role);
    final paths = _navPaths(role);
    final useBottom = AppBreakpoints.useBottomNavigation(context);
    final w = AppBreakpoints.widthOf(context);

    void goNav(int i) {
      if (i >= 0 && i < paths.length) context.go(paths[i]);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Благотворительный фонд'),
        actions: [
          if (w >= AppBreakpoints.tablet)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Center(
                child: Text(
                  '${auth.user!.displayName} · ${role.label}',
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          if (RouteAccess.canAdminister(role))
            IconButton(
              tooltip: 'Пользователи и роли',
              onPressed: () => context.go('/admin/users'),
              icon: const Icon(Icons.admin_panel_settings_outlined),
            ),
          if (RouteAccess.canAdminister(role))
            IconButton(
              tooltip: 'Статистика фонда',
              onPressed: () => context.go('/admin/stats'),
              icon: const Icon(Icons.insights_outlined),
            ),
          IconButton(
            tooltip: 'Перечитать профиль из localStorage',
            icon: const Icon(Icons.refresh),
            onPressed: () => auth.reloadUiProfileFromStorage(),
          ),
          IconButton(
            tooltip: 'Выход из системы',
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await auth.logout();
              if (context.mounted) context.go('/login');
            },
          ),
        ],
      ),
      body: ResponsiveContent(
        child: Row(
          children: [
            if (index != null && !useBottom)
              NavigationRail(
                selectedIndex: index,
                onDestinationSelected: goNav,
                labelType: AppBreakpoints.showAllRailLabels(context)
                    ? NavigationRailLabelType.all
                    : NavigationRailLabelType.selected,
                destinations: _railDestinations(role),
              ),
            if (index != null && !useBottom) const VerticalDivider(width: 1),
            Expanded(child: child),
          ],
        ),
      ),
      bottomNavigationBar: index != null && useBottom
          ? NavigationBar(
              selectedIndex: index,
              onDestinationSelected: goNav,
              destinations: _bottomDestinations(role),
            )
          : null,
    );
  }
}
