import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class EntityFormShell extends StatefulWidget {
  const EntityFormShell({
    super.key,
    required this.title,
    required this.formKey,
    required this.isDirty,
    required this.onSave,
    required this.children,
    this.loading = false,
  });

  final String title;
  final GlobalKey<FormState> formKey;
  final bool isDirty;
  final Future<void> Function() onSave;
  final List<Widget> children;
  final bool loading;

  @override
  State<EntityFormShell> createState() => _EntityFormShellState();
}

class _EntityFormShellState extends State<EntityFormShell> {
  bool _saving = false;

  Future<bool> _confirmLeave(BuildContext context) async {
    if (!widget.isDirty) return true;
    final leave = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Несохранённые изменения'),
        content: const Text('Выйти без сохранения?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Остаться'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Выйти'),
          ),
        ],
      ),
    );
    return leave ?? false;
  }

  Future<void> _handleSave() async {
    if (_saving || widget.loading) return;
    setState(() => _saving = true);
    try {
      await widget.onSave();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !widget.isDirty && !_saving,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        if (await _confirmLeave(context) && context.mounted) {
          context.pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.title),
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: _saving
                ? null
                : () async {
                    if (await _confirmLeave(context) && context.mounted) {
                      context.pop();
                    }
                  },
          ),
        ),
        body: widget.loading
            ? const Center(child: CircularProgressIndicator())
            : Form(
                key: widget.formKey,
                child: ListView(
                  padding: const EdgeInsets.all(24),
                  children: [
                    ...widget.children,
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: _saving ? null : _handleSave,
                      child: _saving
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Сохранить'),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
