import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../models/fund_category.dart';
import '../../repositories/category_repository.dart';
import '../../validation/form_validators.dart';
import '../../widgets/entity_form_shell.dart';

class CategoryFormScreen extends StatefulWidget {
  const CategoryFormScreen({super.key, this.id});

  final int? id;
  bool get isEditing => id != null;

  @override
  State<CategoryFormScreen> createState() => _CategoryFormScreenState();
}

class _CategoryFormScreenState extends State<CategoryFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  bool _loading = true;
  bool _dirty = false;
  String? _nameServerError;

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
    if (widget.isEditing) {
      final c =
          await context.read<CategoryRepository>().findById(widget.id!);
      if (c != null && mounted) _nameCtrl.text = c.name;
    }
    if (mounted) setState(() => _loading = false);
  }

  void _showNameError(String message) {
    setState(() => _nameServerError = message);
    _formKey.currentState?.validate();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
  }

  Future<void> _save() async {
    setState(() => _nameServerError = null);
    if (!_formKey.currentState!.validate()) return;

    final repo = context.read<CategoryRepository>();
    final name = _nameCtrl.text.trim();

    final existing = await repo.findByName(name);
    if (existing != null &&
        (!widget.isEditing || existing.id != widget.id)) {
      _showNameError('Направление «$name» уже существует');
      return;
    }

    final item = FundCategory(id: widget.id ?? 0, name: name);
    try {
      if (widget.isEditing) {
        await repo.update(item);
      } else {
        await repo.create(item);
      }
    } on StateError catch (e) {
      if (e.message.contains('уже существует')) {
        _showNameError(e.message);
        return;
      }
      rethrow;
    }

    if (mounted) {
      setState(() => _dirty = false);
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return EntityFormShell(
      title:
          widget.isEditing ? 'Редактирование направления' : 'Новое направление',
      formKey: _formKey,
      isDirty: _dirty,
      onSave: _save,
      loading: _loading,
      children: [
        TextFormField(
          controller: _nameCtrl,
          onChanged: (_) {
            if (_nameServerError != null) {
              setState(() => _nameServerError = null);
            }
          },
          decoration: const InputDecoration(
            labelText: 'Название',
            border: OutlineInputBorder(),
            helperText: 'Должно быть уникальным',
          ),
          validator: (v) {
            final base =
                FormValidators.length(v, min: 2, max: 100, label: 'Название');
            if (base != null) return base;
            if (_nameServerError != null) return _nameServerError;
            return null;
          },
        ),
      ],
    );
  }
}
