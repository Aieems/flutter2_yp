import 'package:flutter/material.dart';

import 'routing/app_router.dart';

class CharityFundApp extends StatelessWidget {
  const CharityFundApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'Благотворительный фонд',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      routerConfig: appRouter,
    );
  }
}
