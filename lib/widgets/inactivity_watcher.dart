import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Выход по неактивности с предупреждением за [warningBefore] до [timeout].
class InactivityWatcher extends StatefulWidget {
  const InactivityWatcher({
    super.key,
    required this.timeout,
    required this.warningBefore,
    required this.onTimeout,
    required this.onActivity,
    required this.child,
  });

  final Duration timeout;
  final Duration warningBefore;
  final VoidCallback onTimeout;
  final VoidCallback onActivity;
  final Widget child;

  @override
  State<InactivityWatcher> createState() => _InactivityWatcherState();
}

class _InactivityWatcherState extends State<InactivityWatcher> {
  Timer? _timer;
  Timer? _warningTimer;
  bool _dialogOpen = false;

  @override
  void initState() {
    super.initState();
    HardwareKeyboard.instance.addHandler(_onKey);
    _restart();
  }

  bool _onKey(KeyEvent event) {
    _restart();
    return false;
  }

  void _restart() {
    widget.onActivity();
    _timer?.cancel();
    _warningTimer?.cancel();
    if (_dialogOpen && mounted) {
      Navigator.of(context, rootNavigator: true).maybePop();
      _dialogOpen = false;
    }
    final warnAt = widget.timeout - widget.warningBefore;
    if (warnAt > Duration.zero) {
      _warningTimer = Timer(warnAt, _showWarning);
    }
    _timer = Timer(widget.timeout, widget.onTimeout);
  }

  Future<void> _showWarning() async {
    if (!mounted || _dialogOpen) return;
    _dialogOpen = true;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Сессия скоро завершится'),
        content: Text(
          'Нет активности ${widget.timeout.inMinutes} мин. '
          'Через ${widget.warningBefore.inSeconds} с вы будете выведены из системы.',
        ),
        actions: [
          FilledButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              _dialogOpen = false;
              _restart();
            },
            child: const Text('Продолжить работу'),
          ),
        ],
      ),
    );
    _dialogOpen = false;
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_onKey);
    _timer?.cancel();
    _warningTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) => _restart(),
      onPointerMove: (_) => _restart(),
      onPointerSignal: (_) => _restart(),
      child: widget.child,
    );
  }
}
