import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_2/screens/auth/login_screen.dart';

void main() {
  testWidgets('форма входа не отправляется с пустыми полями', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: LoginScreen()));
    await tester.tap(find.text('Войти'));
    await tester.pump();
    expect(find.text('Укажите логин'), findsOneWidget);
    expect(find.text('Укажите пароль'), findsOneWidget);
  });
}
