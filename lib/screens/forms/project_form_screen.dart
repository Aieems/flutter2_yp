import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/api_exceptions.dart';
import '../../models/fund_category.dart';
import '../../models/fund_tag.dart';
import '../../models/partner.dart';
import '../../models/project.dart';
import '../../repositories/category_repository.dart';
import '../../repositories/partner_repository.dart';
import '../../repositories/project_repository.dart';
import '../../repositories/tag_repository.dart';
import '../../validation/form_validators.dart';
import '../../widgets/entity_form_shell.dart';
import '../../widgets/multi_id_form_field.dart';

class ProjectFormScreen extends StatefulWidget {
  const ProjectFormScreen({super.key, this.id});

  final int? id;

  bool get isEditing => id != null;

  @override
  State<ProjectFormScreen> createState() => _ProjectFormScreenState();
}

class _ProjectFormScreenState extends State<ProjectFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _codeCtrl = TextEditingController();
  final _yearCtrl = TextEditingController();
  final _goalCtrl = TextEditingController();
  final _volTotalCtrl = TextEditingController();
  final _volActiveCtrl = TextEditingController();

  int? _categoryId;
  List<int> _partnerIds = [];
  List<int> _tagIds = [];
  List<FundCategory> _categories = [];
  List<FundTag> _tagOptions = [];
  List<Partner> _partnerOptions = [];
  bool _loading = true;
  bool _dirty = false;
  String? _codeServerError;

  @override
  void initState() {
    super.initState();
    for (final c in [
      _titleCtrl,
      _codeCtrl,
      _yearCtrl,
      _goalCtrl,
      _volTotalCtrl,
      _volActiveCtrl,
    ]) {
      c.addListener(_markDirty);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _init());
  }

  void _markDirty() {
    if (!_dirty) setState(() => _dirty = true);
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _codeCtrl.dispose();
    _yearCtrl.dispose();
    _goalCtrl.dispose();
    _volTotalCtrl.dispose();
    _volActiveCtrl.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    await _loadRelationOptions();
    if (widget.isEditing) {
      final repo = context.read<ProjectRepository>();
      final p = await repo.findById(widget.id!);
      if (p != null && mounted) {
        _titleCtrl.text = p.title;
        _codeCtrl.text = p.code;
        _yearCtrl.text = '${p.year}';
        _goalCtrl.text = '${p.goalAmount}';
        _volTotalCtrl.text = '${p.volunteersTotal}';
        _volActiveCtrl.text = '${p.volunteersActive}';
        _categoryId = p.categoryId;
        _partnerIds = [...p.partnerIds];
        _tagIds = [...p.tagIds];
        await _loadRelationOptions();
      }
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _loadRelationOptions() async {
    _categories = await context.read<CategoryRepository>().listForSelect();
    _tagOptions = await context.read<TagRepository>().listForSelect(
      categoryId: _categoryId,
    );
    _partnerOptions = await context.read<PartnerRepository>().listForSelect(
      categoryId: _categoryId,
    );
    _tagIds = _tagIds
        .where((id) => _tagOptions.any((t) => t.id == id))
        .toList();
    _partnerIds = _partnerIds
        .where((id) => _partnerOptions.any((p) => p.id == id))
        .toList();
    if (mounted) setState(() {});
  }

  Future<void> _onCategoryChanged(int? v) async {
    setState(() {
      _categoryId = v;
      _dirty = true;
    });
    await _loadRelationOptions();
  }

  void _notifyIsbnDuplicate(String message) {
    _showIsbnError(message);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
  }

  Future<void> _save() async {
    setState(() => _codeServerError = null);
    if (!_formKey.currentState!.validate()) return;

    final repo = context.read<ProjectRepository>();
    final code = _codeCtrl.text.trim();

    final project = Project(
      id: widget.id ?? 0,
      title: _titleCtrl.text.trim(),
      code: code,
      year: int.parse(_yearCtrl.text.trim()),
      goalAmount: int.parse(_goalCtrl.text.trim()),
      categoryId: _categoryId!,
      partnerIds: _partnerIds,
      tagIds: _tagIds,
      volunteersTotal: int.parse(_volTotalCtrl.text.trim()),
      volunteersActive: int.parse(_volActiveCtrl.text.trim()),
    );

    try {
      if (widget.isEditing) {
        await repo.update(project);
      } else {
        await repo.create(project);
      }
      if (!mounted) return;
      setState(() => _dirty = false);
      context.pop();
    } on ValidationException catch (e) {
      final isbnMsg = e.errors['code'] ?? e.errors['isbn'];
      if (isbnMsg != null) {
        _notifyIsbnDuplicate(isbnMsg);
      } else {
        _showSnackBar(e.message);
      }
      _formKey.currentState?.validate();
    } on ConflictException catch (e) {
      _showSnackBar(e.message);
    } on ApiException catch (e) {
      _showSnackBar(e.message);
    } on StateError catch (e) {
      if (e.message.contains('ISBN') || e.message.contains('код проекта')) {
        _notifyIsbnDuplicate(e.message);
        return;
      }
      rethrow;
    }
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  void _showIsbnError(String message) {
    setState(() => _codeServerError = message);
    _formKey.currentState?.validate();
  }

  @override
  Widget build(BuildContext context) {
    return EntityFormShell(
      title: widget.isEditing ? 'Редактирование проекта' : 'Новый проект',
      formKey: _formKey,
      isDirty: _dirty,
      onSave: _save,
      loading: _loading,
      children: [
        TextFormField(
          controller: _titleCtrl,
          decoration: const InputDecoration(
            labelText: 'Название',
            border: OutlineInputBorder(),
          ),
          validator: (v) =>
              FormValidators.length(v, min: 2, max: 120, label: 'Название'),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _codeCtrl,
          onChanged: (_) {
            if (_codeServerError != null) {
              setState(() => _codeServerError = null);
            }
          },
          decoration: InputDecoration(
            labelText: 'ISBN (код проекта)',
            border: const OutlineInputBorder(),
            helperText: 'Должен быть уникальным',
          ),
          validator: (v) {
            final base = FormValidators.projectCode(v);
            if (base != null) return base;
            if (_codeServerError != null) return _codeServerError;
            return null;
          },
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: 160,
          child: TextFormField(
            controller: _yearCtrl,
            decoration: const InputDecoration(
              labelText: 'Год запуска',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
            validator: FormValidators.year,
          ),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _goalCtrl,
          decoration: const InputDecoration(
            labelText: 'Цель сбора, ₽',
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.number,
          validator: (v) => FormValidators.positiveInt(v, label: 'Сумма'),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<int>(
          value: _categoryId,
          decoration: const InputDecoration(
            labelText: 'Направление',
            border: OutlineInputBorder(),
          ),
          items: _categories
              .map((c) => DropdownMenuItem(value: c.id, child: Text(c.name)))
              .toList(),
          onChanged: _onCategoryChanged,
          validator: (v) => v == null ? 'Выберите направление' : null,
        ),
        const SizedBox(height: 12),
        MultiIdFormField(
          key: ValueKey('tags-$_categoryId-${_tagOptions.length}'),
          initialValue: _tagIds,
          label: 'Теги',
          options: _tagOptions.map((t) => MultiIdOption(t.id, t.name)).toList(),
          onChanged: (v) => setState(() {
            _tagIds = v;
            _dirty = true;
          }),
          validator: (v) =>
              (v == null || v.isEmpty) ? 'Выберите хотя бы один тег' : null,
        ),
        const SizedBox(height: 12),
        MultiIdFormField(
          key: ValueKey('partners-$_categoryId-${_partnerOptions.length}'),
          initialValue: _partnerIds,
          label: 'Партнёры',
          options: _partnerOptions
              .map((p) => MultiIdOption(p.id, p.displayName))
              .toList(),
          onChanged: (v) => setState(() {
            _partnerIds = v;
            _dirty = true;
          }),
          validator: (v) => (v == null || v.isEmpty)
              ? 'Выберите хотя бы одного партнёра'
              : null,
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _volTotalCtrl,
          decoration: const InputDecoration(
            labelText: 'Волонтёров всего',
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.number,
          validator: (v) => FormValidators.positiveInt(v, label: 'Количество'),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _volActiveCtrl,
          decoration: const InputDecoration(
            labelText: 'Активных волонтёров',
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.number,
          validator: (v) {
            final base = FormValidators.positiveInt(v, label: 'Количество');
            if (base != null) return base;
            final active = int.tryParse(v!.trim()) ?? 0;
            final total = int.tryParse(_volTotalCtrl.text.trim()) ?? 0;
            if (active > total) return 'Не больше общего числа';
            return null;
          },
        ),
      ],
    );
  }
}
