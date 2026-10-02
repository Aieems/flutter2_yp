import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../repositories/api/api_category_repository.dart';
import '../repositories/api/api_partner_repository.dart';
import '../repositories/api/api_project_repository.dart';
import '../repositories/api/api_tag_repository.dart';
import '../repositories/api/api_volunteer_repository.dart';
import '../repositories/category_repository.dart';
import '../repositories/partner_repository.dart';
import '../repositories/persistent_category_repository.dart';
import '../repositories/persistent_partner_repository.dart';
import '../repositories/persistent_project_repository.dart';
import '../repositories/persistent_tag_repository.dart';
import '../repositories/persistent_volunteer_repository.dart';
import '../repositories/project_repository.dart';
import '../repositories/tag_repository.dart';
import '../repositories/volunteer_repository.dart';

class AppRepositories {
  AppRepositories({
    required this.projects,
    required this.partners,
    required this.categories,
    required this.tags,
    required this.volunteers,
  });

  final ProjectRepository projects;
  final PartnerRepository partners;
  final CategoryRepository categories;
  final TagRepository tags;
  final VolunteerRepository volunteers;

  static Future<AppRepositories> create(
    SharedPreferences prefs, {
    void Function(String message)? onStorageReset,
  }) async {
    final projects = PersistentProjectRepository(
      prefs,
      onStorageReset: onStorageReset,
    );
    final partners = PersistentPartnerRepository(
      prefs,
      projects,
      onStorageReset: onStorageReset,
    );
    final categories = PersistentCategoryRepository(
      prefs,
      projects,
      onStorageReset: onStorageReset,
    );
    final tags = PersistentTagRepository(
      prefs,
      onStorageReset: onStorageReset,
    );
    final volunteers = PersistentVolunteerRepository(
      prefs,
      onStorageReset: onStorageReset,
    );
    return AppRepositories(
      projects: projects,
      partners: partners,
      categories: categories,
      tags: tags,
      volunteers: volunteers,
    );
  }

  /// Репозитории ПР4 — только HTTP, без SharedPreferences.
  factory AppRepositories.createApi(Dio dio) {
    final projects = ApiProjectRepository(dio);
    final partners = ApiPartnerRepository(dio, projects);
    final categories = ApiCategoryRepository(dio, projects);
    final tags = ApiTagRepository(dio);
    final volunteers = ApiVolunteerRepository(dio);
    return AppRepositories(
      projects: projects,
      partners: partners,
      categories: categories,
      tags: tags,
      volunteers: volunteers,
    );
  }
}
