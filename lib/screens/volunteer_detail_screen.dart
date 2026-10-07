import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/volunteer.dart';
import '../repositories/volunteer_repository.dart';
import '../core/show_api_error.dart';
import '../models/app_role.dart';
import '../widgets/delete_dialogs.dart';
import '../widgets/role_gate.dart';

class VolunteerDetailScreen extends StatefulWidget {
  const VolunteerDetailScreen({super.key, required this.volunteerId});

  final int volunteerId;

  @override
  State<VolunteerDetailScreen> createState() => _VolunteerDetailScreenState();
}

class _VolunteerDetailScreenState extends State<VolunteerDetailScreen> {
  Volunteer? _volunteer;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    _volunteer = await context.read<VolunteerRepository>().findById(
      widget.volunteerId,
    );
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final v = _volunteer;
    if (v == null) {
      return const Scaffold(body: Center(child: Text('Не найден')));
    }
    final repo = context.read<VolunteerRepository>();

    return Scaffold(
      appBar: AppBar(
        title: Text(v.displayName),
        actions: [
          RoleGate(
            minRole: AppRole.coordinator,
            builder: (context) => IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => context.push('/volunteers/${v.id}/edit'),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Email: ${v.email}'),
            const SizedBox(height: 8),
            Text('Билет: ${v.card.cardNumber}'),
            Text(
              'Выдан: ${v.card.issuedAt.toIso8601String().split('T').first}',
            ),
            Text(
              'Действует до: ${v.card.expiresAt.toIso8601String().split('T').first}',
            ),
            const Spacer(),
            Wrap(
              spacing: 8,
              children: [
                RoleGate(
                  minRole: AppRole.admin,
                  builder: (context) => v.isDeleted
                      ? FilledButton.icon(
                          onPressed: () async {
                            try {
                              await repo.restore(v.id);
                              await _load();
                            } catch (e) {
                              if (context.mounted) showApiError(context, e);
                            }
                          },
                          icon: const Icon(Icons.restore),
                          label: const Text('Восстановить'),
                        )
                      : const SizedBox.shrink(),
                ),
                RoleGate(
                  minRole: AppRole.coordinator,
                  builder: (context) => !v.isDeleted
                      ? FilledButton.icon(
                          onPressed: () async {
                            if (await confirmSoftDelete(
                              context,
                              v.displayName,
                            )) {
                              try {
                                await repo.softDelete(v.id);
                                if (context.mounted) context.pop();
                              } catch (e) {
                                if (context.mounted) showApiError(context, e);
                              }
                            }
                          },
                          icon: const Icon(Icons.delete_outline),
                          label: const Text('Логическое удаление'),
                        )
                      : const SizedBox.shrink(),
                ),
                RoleGate(
                  minRole: AppRole.admin,
                  builder: (context) => OutlinedButton.icon(
                    onPressed: () async {
                      if (await confirmHardDelete(context, v.displayName)) {
                        try {
                          await repo.hardDelete(v.id);
                          if (context.mounted) context.pop();
                        } catch (e) {
                          if (context.mounted) showApiError(context, e);
                        }
                      }
                    },
                    icon: const Icon(Icons.delete_forever),
                    label: const Text('Удалить навсегда'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
