import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/partner_query.dart';
import '../models/project_query.dart';
import '../models/simple_list_query.dart';
import '../state/load_status.dart';
import '../state/partner_list_notifier.dart';
import '../state/project_list_notifier.dart';
import '../state/simple_entity_notifiers.dart';
import 'query_params.dart';

class ProjectQuerySync extends StatefulWidget {
  const ProjectQuerySync({super.key, required this.uri, required this.child});

  final Uri uri;
  final Widget child;

  @override
  State<ProjectQuerySync> createState() => _ProjectQuerySyncState();
}

class _ProjectQuerySyncState extends State<ProjectQuerySync> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _apply());
  }

  @override
  void didUpdateWidget(ProjectQuerySync oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.uri != widget.uri) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _apply());
    }
  }

  void _apply() {
    if (!mounted) return;
    final parsed = projectQueryFromUri(widget.uri.queryParameters);
    final notifier = context.read<ProjectListNotifier>();
    if (_equal(notifier.query, parsed)) {
      if (notifier.status == LoadStatus.idle) {
        notifier.load();
      }
      return;
    }
    notifier.applyQuery(parsed);
  }

  bool _equal(ProjectQuery a, ProjectQuery b) {
    return a.search == b.search &&
        a.tagId == b.tagId &&
        a.categoryId == b.categoryId &&
        a.yearFrom == b.yearFrom &&
        a.yearTo == b.yearTo &&
        a.sortField == b.sortField &&
        a.sortAscending == b.sortAscending &&
        a.page == b.page &&
        a.size == b.size &&
        a.includeDeleted == b.includeDeleted;
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

class PartnerQuerySync extends StatefulWidget {
  const PartnerQuerySync({super.key, required this.uri, required this.child});

  final Uri uri;
  final Widget child;

  @override
  State<PartnerQuerySync> createState() => _PartnerQuerySyncState();
}

class _PartnerQuerySyncState extends State<PartnerQuerySync> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _apply());
  }

  @override
  void didUpdateWidget(PartnerQuerySync oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.uri != widget.uri) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _apply());
    }
  }

  void _apply() {
    if (!mounted) return;
    final parsed = partnerQueryFromUri(widget.uri.queryParameters);
    final notifier = context.read<PartnerListNotifier>();
    if (_equal(notifier.query, parsed)) {
      if (notifier.status == LoadStatus.idle) {
        notifier.load();
      }
      return;
    }
    notifier.applyQuery(parsed);
  }

  bool _equal(PartnerQuery a, PartnerQuery b) {
    return a.search == b.search &&
        a.sortField == b.sortField &&
        a.sortAscending == b.sortAscending &&
        a.page == b.page &&
        a.size == b.size &&
        a.includeDeleted == b.includeDeleted;
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

class CategoryQuerySync extends StatefulWidget {
  const CategoryQuerySync({super.key, required this.uri, required this.child});

  final Uri uri;
  final Widget child;

  @override
  State<CategoryQuerySync> createState() => _CategoryQuerySyncState();
}

class _CategoryQuerySyncState extends State<CategoryQuerySync> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _apply());
  }

  @override
  void didUpdateWidget(CategoryQuerySync oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.uri != widget.uri) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _apply());
    }
  }

  void _apply() {
    if (!mounted) return;
    final parsed = simpleListQueryFromUri(
      widget.uri.queryParameters,
      defaultSortField: 'name',
    );
    final notifier = context.read<CategoryListNotifier>();
    if (_equalSimple(notifier.query, parsed)) {
      if (notifier.status == LoadStatus.idle) notifier.load();
      return;
    }
    notifier.applyQuery(parsed);
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

class TagQuerySync extends StatefulWidget {
  const TagQuerySync({super.key, required this.uri, required this.child});

  final Uri uri;
  final Widget child;

  @override
  State<TagQuerySync> createState() => _TagQuerySyncState();
}

class _TagQuerySyncState extends State<TagQuerySync> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _apply());
  }

  @override
  void didUpdateWidget(TagQuerySync oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.uri != widget.uri) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _apply());
    }
  }

  void _apply() {
    if (!mounted) return;
    final parsed = simpleListQueryFromUri(
      widget.uri.queryParameters,
      defaultSortField: 'name',
    );
    final notifier = context.read<TagListNotifier>();
    if (_equalSimple(notifier.query, parsed)) {
      if (notifier.status == LoadStatus.idle) notifier.load();
      return;
    }
    notifier.applyQuery(parsed);
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

class VolunteerQuerySync extends StatefulWidget {
  const VolunteerQuerySync({super.key, required this.uri, required this.child});

  final Uri uri;
  final Widget child;

  @override
  State<VolunteerQuerySync> createState() => _VolunteerQuerySyncState();
}

class _VolunteerQuerySyncState extends State<VolunteerQuerySync> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _apply());
  }

  @override
  void didUpdateWidget(VolunteerQuerySync oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.uri != widget.uri) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _apply());
    }
  }

  void _apply() {
    if (!mounted) return;
    final parsed = simpleListQueryFromUri(
      widget.uri.queryParameters,
      defaultSortField: 'lastName',
    );
    final notifier = context.read<VolunteerListNotifier>();
    if (_equalSimple(notifier.query, parsed)) {
      if (notifier.status == LoadStatus.idle) notifier.load();
      return;
    }
    notifier.applyQuery(parsed);
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

bool _equalSimple(SimpleListQuery a, SimpleListQuery b) {
  return a.search == b.search &&
      a.categoryId == b.categoryId &&
      a.sortField == b.sortField &&
      a.sortAscending == b.sortAscending &&
      a.page == b.page &&
      a.size == b.size &&
      a.includeDeleted == b.includeDeleted;
}
