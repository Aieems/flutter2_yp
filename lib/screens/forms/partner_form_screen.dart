import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../models/partner.dart';
import '../../repositories/partner_repository.dart';
import '../../validation/form_validators.dart';
import '../../widgets/entity_form_shell.dart';

class PartnerFormScreen extends StatefulWidget {
  const PartnerFormScreen({super.key, this.id});

  final int? id;
  bool get isEditing => id != null;

  @override
  State<PartnerFormScreen> createState() => _PartnerFormScreenState();
}

class _PartnerFormScreenState extends State<PartnerFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _lastNameCtrl = TextEditingController();
  final _firstNameCtrl = TextEditingController();
  final _countryCtrl = TextEditingController();
  final _yearCtrl = TextEditingController();
  bool _loading = true;
  bool _dirty = false;

  @override
  void initState() {
    super.initState();
    for (final c in [_lastNameCtrl, _firstNameCtrl, _countryCtrl, _yearCtrl]) {
      c.addListener(() {
        if (!_dirty) setState(() => _dirty = true);
      });
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _lastNameCtrl.dispose();
    _firstNameCtrl.dispose();
    _countryCtrl.dispose();
    _yearCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    if (widget.isEditing) {
      final p = await context.read<PartnerRepository>().findById(widget.id!);
      if (p != null && mounted) {
        _lastNameCtrl.text = p.lastName;
        _firstNameCtrl.text = p.firstName;
        _countryCtrl.text = p.country;
        _yearCtrl.text = '${p.birthYear}';
      }
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final repo = context.read<PartnerRepository>();
    final partner = Partner(
      id: widget.id ?? 0,
      lastName: _lastNameCtrl.text.trim(),
      firstName: _firstNameCtrl.text.trim(),
      country: _countryCtrl.text.trim(),
      birthYear: int.parse(_yearCtrl.text.trim()),
    );
    if (widget.isEditing) {
      await repo.update(partner);
    } else {
      await repo.create(partner);
    }
    if (mounted) {
      setState(() => _dirty = false);
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return EntityFormShell(
      title: widget.isEditing ? 'Редактирование партнёра' : 'Новый партнёр',
      formKey: _formKey,
      isDirty: _dirty,
      onSave: _save,
      loading: _loading,
      children: [
        TextFormField(
          controller: _lastNameCtrl,
          decoration: const InputDecoration(
            labelText: 'Название / фамилия',
            border: OutlineInputBorder(),
          ),
          validator: (v) =>
              FormValidators.length(v, min: 2, max: 80, label: 'Название'),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _firstNameCtrl,
          decoration: const InputDecoration(
            labelText: 'Имя / тип организации',
            border: OutlineInputBorder(),
          ),
          validator: (v) =>
              FormValidators.length(v, min: 1, max: 80, label: 'Имя'),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _countryCtrl,
          decoration: const InputDecoration(
            labelText: 'Страна',
            border: OutlineInputBorder(),
          ),
          validator: (v) =>
              FormValidators.length(v, min: 2, max: 60, label: 'Страна'),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _yearCtrl,
          decoration: const InputDecoration(
            labelText: 'Год основания',
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.number,
          validator: (v) =>
              FormValidators.intRange(v, min: 1900, max: 2100, label: 'Год'),
        ),
      ],
    );
  }
}
