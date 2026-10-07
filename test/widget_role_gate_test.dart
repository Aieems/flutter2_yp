import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_2/models/app_role.dart';
import 'package:flutter_2/state/auth_notifier.dart';
import 'package:flutter_2/widgets/role_gate.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('RoleGate скрывает виджет при недостаточной роли', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final auth = AuthNotifier(prefs: prefs);
    await auth.login('volunteer1', 'VolunteeR1!');

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: auth,
        child: MaterialApp(
          home: RoleGate(
            minRole: AppRole.admin,
            builder: (context) => const Text('admin-only'),
            fallback: const Text('hidden'),
          ),
        ),
      ),
    );

    expect(find.text('admin-only'), findsNothing);
    expect(find.text('hidden'), findsOneWidget);
  });
}
