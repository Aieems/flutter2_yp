import 'package:shared_preferences/shared_preferences.dart';

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
}
