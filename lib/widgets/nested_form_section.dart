import 'package:flutter/material.dart';

/// Вложенная группа полей (аналог билета у читателя в задании).
class NestedFormSection extends StatelessWidget {
  const NestedFormSection({
    super.key,
    required this.title,
    required this.children,
  });

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return InputDecorator(
      decoration: InputDecoration(
        labelText: title,
        border: const OutlineInputBorder(),
        contentPadding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) const SizedBox(height: 12),
            children[i],
          ],
        ],
      ),
    );
  }
}
