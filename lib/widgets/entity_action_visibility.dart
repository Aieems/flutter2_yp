import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/app_role.dart';
import '../state/auth_notifier.dart';

/// Удобные флаги для скрытия кнопок изменения данных (волонтёр — только просмотр).
class EntityActionVisibility {
  EntityActionVisibility._(this.canManage, this.canAdmin);

  final bool canManage;
  final bool canAdmin;

  static EntityActionVisibility of(BuildContext context) {
    final auth = context.watch<AuthNotifier>();
    return EntityActionVisibility._(
      auth.has(AppRole.coordinator),
      auth.has(AppRole.admin),
    );
  }
}
