import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'repositories/in_memory_partner_repository.dart';
import 'repositories/in_memory_project_repository.dart';
import 'repositories/partner_repository.dart';
import 'repositories/project_repository.dart';
import 'state/partner_list_notifier.dart';
import 'state/project_list_notifier.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  usePathUrlStrategy();
  runApp(
    MultiProvider(
      providers: [
        Provider<ProjectRepository>(
          create: (_) => InMemoryProjectRepository(),
        ),
        Provider<PartnerRepository>(
          create: (_) => InMemoryPartnerRepository(),
        ),
        ChangeNotifierProvider(
          create: (context) =>
              ProjectListNotifier(context.read<ProjectRepository>()),
        ),
        ChangeNotifierProvider(
          create: (context) =>
              PartnerListNotifier(context.read<PartnerRepository>()),
        ),
      ],
      child: const CharityFundApp(),
    ),
  );
}
