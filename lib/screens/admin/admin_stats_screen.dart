import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/auth_notifier.dart';

class AdminStatsScreen extends StatelessWidget {
  const AdminStatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Статистика фонда')),
      body: FutureBuilder<Map<String, int>>(
        future: context.read<AuthNotifier>().fetchStats(),
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(child: Text('${snap.error}'));
          }
          final stats = snap.data!;
          final labels = {
            'projects': 'Проекты',
            'partners': 'Партнёры',
            'volunteers': 'Волонтёры',
            'categories': 'Направления',
          };
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              for (final e in stats.entries)
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.analytics_outlined),
                    title: Text(labels[e.key] ?? e.key),
                    trailing: Text(
                      '${e.value}',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
