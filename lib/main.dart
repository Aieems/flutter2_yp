import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';
import 'bootstrap/app_repositories.dart';
import 'core/api_client.dart';
import 'core/auth_api.dart';
import 'core/auth_refresh_interceptor.dart';
import 'core/config.dart';
import 'core/supabase_auth_api.dart';
import 'repositories/category_repository.dart';
import 'repositories/partner_repository.dart';
import 'repositories/project_repository.dart';
import 'repositories/tag_repository.dart';
import 'repositories/volunteer_repository.dart';
import 'routing/app_router.dart';
import 'state/auth_notifier.dart';
import 'state/partner_list_notifier.dart';
import 'state/project_list_notifier.dart';
import 'state/simple_entity_notifiers.dart';
import 'state/storage_message_notifier.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  usePathUrlStrategy();

  if (useSupabaseBackend) {
    if (supabaseUrl.isEmpty || supabaseAnonKey.isEmpty) {
      throw StateError(
        'Задайте SUPABASE_URL и SUPABASE_ANON_KEY (--dart-define).',
      );
    }
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
    );
  }

  final prefs = await SharedPreferences.getInstance();
  final storageMessages = StorageMessageNotifier();

  late final AuthNotifier auth;
  final SupabaseAuthApi? supabaseAuth;
  Dio? dio;

  if (useSupabaseBackend) {
    supabaseAuth = SupabaseAuthApi();
    auth = AuthNotifier(prefs: prefs, supabaseAuth: supabaseAuth);
  } else {
    dio = buildDio(tokenProvider: () => auth.accessToken);
    auth = AuthNotifier(
      prefs: prefs,
      authApi: useApiRepositories ? AuthApi(dio) : null,
    );
    dio.interceptors.add(AuthRefreshInterceptor(auth: auth, dio: dio));
    supabaseAuth = null;
  }

  final AppRepositories repos;
  if (useSupabaseBackend) {
    repos = AppRepositories.createSupabase();
  } else if (useApiRepositories) {
    repos = AppRepositories.createApi(dio!);
  } else {
    repos = await AppRepositories.create(
      prefs,
      onStorageReset: storageMessages.show,
    );
  }

  await auth.restore();

  if (await auth.inactiveTooLong(const Duration(minutes: 3))) {
    await auth.logout();
  }

  final router = buildAppRouter(auth);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: auth),
        if (dio != null) Provider<Dio>.value(value: dio),
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
      child: CharityFundApp(router: router),
    ),
  );
}
