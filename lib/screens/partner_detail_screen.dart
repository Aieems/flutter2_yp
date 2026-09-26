import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/partner.dart';
import '../repositories/partner_repository.dart';
import '../widgets/delete_dialogs.dart';

class PartnerDetailScreen extends StatefulWidget {
  const PartnerDetailScreen({super.key, required this.partnerId});

  final int partnerId;

  @override
  State<PartnerDetailScreen> createState() => _PartnerDetailScreenState();
}

class _PartnerDetailScreenState extends State<PartnerDetailScreen> {
  Partner? _partner;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final repo = context.read<PartnerRepository>();
      _partner = await repo.findById(widget.partnerId);
    } catch (e) {
      _error = '$e';
    }
    if (mounted) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Партнёр')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Партнёр')),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_error!),
              FilledButton(onPressed: _load, child: const Text('Повторить')),
            ],
          ),
        ),
      );
    }
    final p = _partner;
    if (p == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Партнёр')),
        body: const Center(child: Text('Партнёр не найден')),
      );
    }

    final repo = context.read<PartnerRepository>();

    return Scaffold(
      appBar: AppBar(
        title: Text(p.displayName),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Страна: ${p.country}'),
            Text('Год основания / регистрации: ${p.birthYear}'),
            if (p.isDeleted)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Запись удалена',
                  style: TextStyle(color: Colors.red.shade700),
                ),
              ),
            const Spacer(),
            Wrap(
              spacing: 8,
              children: [
                if (p.isDeleted)
                  FilledButton.icon(
                    onPressed: () async {
                      await repo.restore(p.id);
                      await _load();
                    },
                    icon: const Icon(Icons.restore),
                    label: const Text('Восстановить'),
                  )
                else
                  FilledButton.icon(
                    onPressed: () async {
                      if (await confirmSoftDelete(context, p.displayName)) {
                        await repo.softDelete(p.id);
                        if (context.mounted) context.pop();
                      }
                    },
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('Логическое удаление'),
                  ),
                OutlinedButton.icon(
                  onPressed: () async {
                    if (await confirmHardDelete(context, p.displayName)) {
                      await repo.hardDelete(p.id);
                      if (context.mounted) context.pop();
                    }
                  },
                  icon: const Icon(Icons.delete_forever),
                  label: const Text('Удалить навсегда'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
