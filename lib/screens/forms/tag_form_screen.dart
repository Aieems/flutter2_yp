import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../models/fund_category.dart';
import '../../models/fund_tag.dart';
import '../../repositories/category_repository.dart';
import '../../repositories/tag_repository.dart';
import '../../validation/form_validators.dart';
import '../../widgets/entity_form_shell.dart';

class TagFormScreen extends StatefulWidget {
  const TagFormScreen({super.key, this.id});

  final int? id;
  bool get isEditing => id != null;

  @override
  State<TagFormScreen> createState() => _TagFormScreenState();
}

class _TagFormScreenState extends State<TagFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  int? _categoryId;
  bool _loading = true;
  bool _dirty = false;
  List<FundCategory> _categories = [];

  @override
  void initState() {
    super.initState();
    _nameCtrl.addListener(() {
      if (!_dirty) setState(() => _dirty = true);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    _categories = await context.read<CategoryRepository>().listForSelect();
    if (widget.isEditing) {
      final t = await context.read<TagRepository>().findById(widget.id!);
      if (t != null && mounted) {
        _nameCtrl.text = t.name;
        _categoryId = t.categoryId;
      }
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final repo = context.read<TagRepository>();
    final item = FundTag(
      id: widget.id ?? 0,
      name: _nameCtrl.text.trim(),
      categoryId: _categoryId!,
    );
    if (widget.isEditing) {
      await repo.update(item);
    } else {
      await repo.create(item);
    }
    if (mounted) {
      setState(() => _dirty = false);
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return EntityFormShell(
      title: widget.isEditing ? 'Редактирование тега' : 'Новый тег',
      formKey: _formKey,
      isDirty: _dirty,
      onSave: _save,
      loading: _loading,
      children: [
        TextFormField(
          controller: _nameCtrl,
          decoration: const InputDecoration(
            labelText: 'Название',
            border: OutlineInputBorder(),
          ),
          validator: (v) =>
              FormValidators.length(v, min: 2, max: 80, label: 'Название'),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<int>(
          value: _categoryId,
          decoration: const InputDecoration(
            labelText: 'Направление',
            border: OutlineInputBorder(),
          ),
          items: _categories
              .map(
                (c) => DropdownMenuItem<int>(value: c.id, child: Text(c.name)),
              )
              .toList(),
          onChanged: (v) => setState(() {
            _categoryId = v;
            _dirty = true;
          }),
          validator: (v) => v == null ? 'Выберите направление' : null,
        ),
      ],
    );
  }
}
