import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'state/auth_notifier.dart';
import 'state/storage_message_notifier.dart';
import 'widgets/inactivity_watcher.dart';

final rootScaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

class CharityFundApp extends StatefulWidget {
  const CharityFundApp({super.key, required this.router});

  final GoRouter router;

  @override
  State<CharityFundApp> createState() => _CharityFundAppState();
}

class _CharityFundAppState extends State<CharityFundApp> {
  @override
  void initState() {
    super.initState();
    final storage = context.read<StorageMessageNotifier>();
    storage.addListener(_onStorageMessage);
    WidgetsBinding.instance.addPostFrameCallback((_) => _onStorageMessage());
  }

  @override
  void dispose() {
    context.read<StorageMessageNotifier>().removeListener(_onStorageMessage);
    super.dispose();
  }

  void _onStorageMessage() {
    final text = context.read<StorageMessageNotifier>().message;
    if (text == null) return;
    rootScaffoldMessengerKey.currentState?.showSnackBar(
      SnackBar(content: Text(text), duration: const Duration(seconds: 5)),
    );
    context.read<StorageMessageNotifier>().clear();
  }

  Future<void> _onInactivityTimeout(BuildContext context) async {
    final auth = context.read<AuthNotifier>();
    await auth.logout();
    if (context.mounted) {
      rootScaffoldMessengerKey.currentState?.showSnackBar(
        const SnackBar(content: Text('Сессия завершена из‑за неактивности.')),
      );
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthNotifier>();
    if (!auth.restoreDone) {
      return MaterialApp(
        home: Scaffold(
          body: Center(
            child: Text(
              'Загрузка…',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
        ),
      );
    }

    Widget app = MaterialApp.router(
      debugShowCheckedModeBanner: false,
      scaffoldMessengerKey: rootScaffoldMessengerKey,
      title: 'Благотворительный фонд',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      routerConfig: widget.router,
    );

    if (auth.isAuthenticated) {
      app = InactivityWatcher(
        timeout: const Duration(minutes: 3),
        warningBefore: const Duration(seconds: 30),
        onActivity: () {
          auth.touchActivity();
          auth.checkMaxSessionAndLogoutIfNeeded().then((loggedOut) {
            if (loggedOut && mounted) {
              rootScaffoldMessengerKey.currentState?.showSnackBar(
                const SnackBar(
                  content: Text(
                    'Сессия завершена: превышена максимальная длительность.',
                  ),
                ),
              );
              context.go('/login');
            }
          });
        },
        onTimeout: () => _onInactivityTimeout(context),
        child: app,
      );
    }

    return app;
  }
}
