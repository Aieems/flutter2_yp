import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'routing/app_router.dart';
import 'state/storage_message_notifier.dart';

final rootScaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

class CharityFundApp extends StatefulWidget {
  const CharityFundApp({super.key});

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

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      scaffoldMessengerKey: rootScaffoldMessengerKey,
      title: 'Благотворительный фонд',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      routerConfig: appRouter,
    );
  }
}
