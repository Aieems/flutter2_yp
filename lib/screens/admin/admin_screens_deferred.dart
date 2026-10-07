import 'package:flutter/material.dart';

import 'admin_stats_screen.dart' deferred as admin_stats;
import 'admin_users_screen.dart' deferred as admin_users;

class DeferredAdminUsersScreen extends StatefulWidget {
  const DeferredAdminUsersScreen({super.key});

  @override
  State<DeferredAdminUsersScreen> createState() =>
      _DeferredAdminUsersScreenState();
}

class _DeferredAdminUsersScreenState extends State<DeferredAdminUsersScreen> {
  late final Future<void> _load;

  @override
  void initState() {
    super.initState();
    _load = admin_users.loadLibrary();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _load,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        return admin_users.AdminUsersScreen();
      },
    );
  }
}

class DeferredAdminStatsScreen extends StatefulWidget {
  const DeferredAdminStatsScreen({super.key});

  @override
  State<DeferredAdminStatsScreen> createState() =>
      _DeferredAdminStatsScreenState();
}

class _DeferredAdminStatsScreenState extends State<DeferredAdminStatsScreen> {
  late final Future<void> _load;

  @override
  void initState() {
    super.initState();
    _load = admin_stats.loadLibrary();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _load,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        return admin_stats.AdminStatsScreen();
      },
    );
  }
}
