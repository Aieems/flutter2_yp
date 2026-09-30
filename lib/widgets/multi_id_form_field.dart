import 'package:flutter/material.dart';

class MultiIdOption {
  final int id;
  final String label;
  const MultiIdOption(this.id, this.label);
}

class MultiIdFormField extends FormField<List<int>> {
  MultiIdFormField({
    super.key,
    required List<MultiIdOption> options,
    required List<int> initialValue,
    required String label,
    required ValueChanged<List<int>> onChanged,
    super.validator,
  }) : super(
          initialValue: initialValue,
          builder: (field) {
            final value = field.value ?? <int>[];
            return InputDecorator(
              decoration: InputDecoration(
                labelText: label,
                border: const OutlineInputBorder(),
                errorText: field.errorText,
              ),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: options.map((opt) {
                  final selected = value.contains(opt.id);
                  return FilterChip(
                    label: Text(opt.label),
                    selected: selected,
                    onSelected: (_) {
                      final next = [...value];
                      if (selected) {
                        next.remove(opt.id);
                      } else {
                        next.add(opt.id);
                      }
                      field.didChange(next);
                      onChanged(next);
                    },
                  );
                }).toList(),
              ),
            );
          },
        );
}
