import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/app_role.dart';
import '../state/auth_notifier.dart';

class RoleGate extends StatelessWidget {
  const RoleGate({
    super.key,
    required this.minRole,
    required this.builder,
    this.fallback = const SizedBox.shrink(),
  });

  final AppRole minRole;
  final Widget Function(BuildContext context) builder;
  final Widget fallback;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthNotifier>();
    if (!auth.has(minRole)) return fallback;
    return builder(context);
  }
}
