import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_2/state/load_status.dart';
import 'package:flutter_2/widgets/async_list_body.dart';

void main() {
  Widget wrap(Widget child) {
    return MaterialApp(home: Scaffold(body: child));
  }

  testWidgets('показывает индикатор загрузки', (tester) async {
    await tester.pumpWidget(
      wrap(
        AsyncListBody(
          status: LoadStatus.loading,
          error: null,
          isEmpty: false,
          onRetry: () {},
          child: const Text('data'),
        ),
      ),
    );
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('показывает пустой результат', (tester) async {
    await tester.pumpWidget(
      wrap(
        AsyncListBody(
          status: LoadStatus.success,
          error: null,
          isEmpty: true,
          onRetry: () {},
          child: const Text('data'),
        ),
      ),
    );
    expect(find.text('Ничего не найдено'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('показывает ошибку и кнопку повтора', (tester) async {
    var retried = false;
    await tester.pumpWidget(
      wrap(
        AsyncListBody(
          status: LoadStatus.error,
          error: 'Сервер недоступен',
          isEmpty: false,
          onRetry: () => retried = true,
          child: const Text('data'),
        ),
      ),
    );
    expect(find.text('Сервер недоступен'), findsOneWidget);
    await tester.tap(find.text('Повторить'));
    expect(retried, isTrue);
  });
}
