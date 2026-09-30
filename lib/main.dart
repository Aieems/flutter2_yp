import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'bootstrap/app_repositories.dart';
import 'repositories/category_repository.dart';
import 'repositories/partner_repository.dart';
import 'repositories/project_repository.dart';
import 'repositories/tag_repository.dart';
import 'repositories/volunteer_repository.dart';
import 'state/partner_list_notifier.dart';
import 'state/project_list_notifier.dart';
import 'state/simple_entity_notifiers.dart';
import 'state/storage_message_notifier.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  usePathUrlStrategy();
  final prefs = await SharedPreferences.getInstance();
  final storageMessages = StorageMessageNotifier();
  final repos = await AppRepositories.create(
    prefs,
    onStorageReset: storageMessages.show,
  );

  runApp(
    MultiProvider(
      providers: [
        Provider<ProjectRepository>.value(value: repos.projects),
        Provider<PartnerRepository>.value(value: repos.partners),
        Provider<CategoryRepository>.value(value: repos.categories),
        Provider<TagRepository>.value(value: repos.tags),
        Provider<VolunteerRepository>.value(value: repos.volunteers),
        ChangeNotifierProvider.value(value: storageMessages),
        ChangeNotifierProvider(
          create: (context) =>
              ProjectListNotifier(context.read<ProjectRepository>()),
        ),
        ChangeNotifierProvider(
          create: (context) =>
              PartnerListNotifier(context.read<PartnerRepository>()),
        ),
        ChangeNotifierProvider(
          create: (context) =>
              CategoryListNotifier(context.read<CategoryRepository>()),
        ),
        ChangeNotifierProvider(
          create: (context) => TagListNotifier(context.read<TagRepository>()),
        ),
        ChangeNotifierProvider(
          create: (context) =>
              VolunteerListNotifier(context.read<VolunteerRepository>()),
        ),
      ],
      child: const CharityFundApp(),
    ),
  );
}
