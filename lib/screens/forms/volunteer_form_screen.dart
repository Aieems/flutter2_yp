import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../models/volunteer.dart';
import '../../models/volunteer_card.dart';
import '../../repositories/volunteer_repository.dart';
import '../../validation/form_validators.dart';
import '../../widgets/entity_form_shell.dart';
import '../../widgets/nested_form_section.dart';

class VolunteerFormScreen extends StatefulWidget {
  const VolunteerFormScreen({super.key, this.id});

  final int? id;
  bool get isEditing => id != null;

  @override
  State<VolunteerFormScreen> createState() => _VolunteerFormScreenState();
}

class _VolunteerFormScreenState extends State<VolunteerFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _lastNameCtrl = TextEditingController();
  final _firstNameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _cardNumberCtrl = TextEditingController();
  final _issuedCtrl = TextEditingController();
  final _expiresCtrl = TextEditingController();
  bool _loading = true;
  bool _dirty = false;
  String? _emailServerError;

  @override
  void initState() {
    super.initState();
    for (final c in [
      _lastNameCtrl,
      _firstNameCtrl,
      _emailCtrl,
      _cardNumberCtrl,
      _issuedCtrl,
      _expiresCtrl,
    ]) {
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
    _emailCtrl.dispose();
    _cardNumberCtrl.dispose();
    _issuedCtrl.dispose();
    _expiresCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    if (widget.isEditing) {
      final v = await context.read<VolunteerRepository>().findById(widget.id!);
      if (v != null && mounted) {
        _lastNameCtrl.text = v.lastName;
        _firstNameCtrl.text = v.firstName;
        _emailCtrl.text = v.email;
        _cardNumberCtrl.text = v.card.cardNumber;
        _issuedCtrl.text = _fmt(v.card.issuedAt);
        _expiresCtrl.text = _fmt(v.card.expiresAt);
      }
    } else {
      final now = DateTime.now();
      _issuedCtrl.text = _fmt(now);
      _expiresCtrl.text = _fmt(now.add(const Duration(days: 365)));
    }
    if (mounted) setState(() => _loading = false);
  }

  String _fmt(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  DateTime? _parseDate(String raw) => DateTime.tryParse(raw.trim());

  Future<void> _save() async {
    setState(() => _emailServerError = null);
    if (!_formKey.currentState!.validate()) return;

    final repo = context.read<VolunteerRepository>();
    final email = _emailCtrl.text.trim();
    if (await repo.isEmailTaken(
      email,
      excludeId: widget.isEditing ? widget.id : null,
    )) {
      setState(() => _emailServerError = 'Email уже зарегистрирован');
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _formKey.currentState?.validate();
      });
      return;
    }

    final issued = _parseDate(_issuedCtrl.text);
    final expires = _parseDate(_expiresCtrl.text);
    if (issued == null || expires == null) return;

    final volunteer = Volunteer(
      id: widget.id ?? 0,
      lastName: _lastNameCtrl.text.trim(),
      firstName: _firstNameCtrl.text.trim(),
      email: email,
      card: VolunteerCard(
        cardNumber: _cardNumberCtrl.text.trim(),
        issuedAt: issued,
        expiresAt: expires,
      ),
    );

    try {
      if (widget.isEditing) {
        await repo.update(volunteer);
      } else {
        await repo.create(volunteer);
      }
    } on StateError catch (e) {
      if (e.message.contains('Email')) {
        setState(() => _emailServerError = e.message);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _formKey.currentState?.validate();
        });
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
      title: widget.isEditing ? 'Редактирование волонтёра' : 'Новый волонтёр',
      formKey: _formKey,
      isDirty: _dirty,
      onSave: _save,
      loading: _loading,
      children: [
        TextFormField(
          controller: _lastNameCtrl,
          decoration: const InputDecoration(
            labelText: 'Фамилия',
            border: OutlineInputBorder(),
          ),
          validator: (v) =>
              FormValidators.length(v, min: 2, max: 80, label: 'Фамилия'),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _firstNameCtrl,
          decoration: const InputDecoration(
            labelText: 'Имя',
            border: OutlineInputBorder(),
          ),
          validator: (v) =>
              FormValidators.length(v, min: 2, max: 80, label: 'Имя'),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _emailCtrl,
          decoration: InputDecoration(
            labelText: 'Email',
            border: const OutlineInputBorder(),
            errorText: _emailServerError,
          ),
          validator: (v) {
            final base = FormValidators.email(v);
            if (base != null) return base;
            if (_emailServerError != null) return _emailServerError;
            return null;
          },
        ),
        const SizedBox(height: 16),
        NestedFormSection(
          title: 'Волонтёрский билет (связь 1:1, аналог читатель + билет)',
          children: [
            TextFormField(
              controller: _cardNumberCtrl,
              decoration: const InputDecoration(
                labelText: 'Номер билета',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              validator: (v) =>
                  FormValidators.length(v, min: 4, max: 32, label: 'Номер'),
            ),
            TextFormField(
              controller: _issuedCtrl,
              decoration: const InputDecoration(
                labelText: 'Дата выдачи (ГГГГ-ММ-ДД)',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              validator: (v) =>
                  _parseDate(v ?? '') == null ? 'Некорректная дата' : null,
            ),
            TextFormField(
              controller: _expiresCtrl,
              decoration: const InputDecoration(
                labelText: 'Действует до (ГГГГ-ММ-ДД)',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              validator: (v) {
                if (_parseDate(v ?? '') == null) return 'Некорректная дата';
                final issued = _parseDate(_issuedCtrl.text);
                final exp = _parseDate(v!);
                if (issued != null && exp != null && !exp.isAfter(issued)) {
                  return 'Дата окончания должна быть позже выдачи';
                }
                return null;
              },
            ),
          ],
        ),
      ],
    );
  }
}
