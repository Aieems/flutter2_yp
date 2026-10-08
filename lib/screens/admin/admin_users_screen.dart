import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/show_api_error.dart';
import '../../models/app_role.dart';
import '../../models/app_user.dart';
import '../../state/auth_notifier.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  late Future<List<AppUser>> _future;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    _future = context.read<AuthNotifier>().listUsers();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Пользователи и роли')),
      body: FutureBuilder<List<AppUser>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(child: Text('${snap.error}'));
          }
          final users = snap.data!;
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: users.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final u = users[i];
              return ListTile(
                title: Text(u.displayName),
                subtitle: Text('@${u.username} · ${u.role.label}'),
                trailing: DropdownButton<AppRole>(
                  value: u.role,
                  items: AppRole.values
                      .map(
                        (r) => DropdownMenuItem(value: r, child: Text(r.label)),
                      )
                      .toList(),
                  onChanged: (role) async {
                    if (role == null || role == u.role) return;
                    try {
                      await context.read<AuthNotifier>().updateUserRoleFor(
                        u,
                        role,
                      );
                      setState(_reload);
                    } catch (e) {
                      if (context.mounted) showApiError(context, e);
                    }
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
