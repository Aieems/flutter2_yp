import 'package:flutter/material.dart';

class PasswordStrengthField extends StatefulWidget {
  const PasswordStrengthField({
    super.key,
    required this.controller,
    required this.onStrengthChanged,
  });

  final TextEditingController controller;
  final ValueChanged<bool> onStrengthChanged;

  static bool isStrong(String value) => _PasswordStrengthFieldState.checkStrong(value);

  @override
  State<PasswordStrengthField> createState() => _PasswordStrengthFieldState();
}

class _PasswordStrengthFieldState extends State<PasswordStrengthField> {
  bool _obscure = true;

  static bool checkStrong(String value) {
    if (value.length < 8) return false;
    if (!RegExp(r'\d').hasMatch(value)) return false;
    if (!RegExp(r'[!@#$%^&*(),.?":{}|<>_\-+=\[\]\\;/`~]').hasMatch(value)) {
      return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextFormField(
          controller: widget.controller,
          obscureText: _obscure,
          onChanged: (v) => widget.onStrengthChanged(checkStrong(v)),
          decoration: InputDecoration(
            labelText: 'Пароль *',
            suffixIcon: IconButton(
              icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off),
              onPressed: () => setState(() => _obscure = !_obscure),
            ),
          ),
          validator: (v) {
            if (v == null || v.isEmpty) return 'Укажите пароль';
            if (!checkStrong(v)) return 'Пароль не соответствует требованиям';
            return null;
          },
        ),
        const SizedBox(height: 8),
        ValueListenableBuilder<TextEditingValue>(
          valueListenable: widget.controller,
          builder: (context, value, _) {
            final p = value.text;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _rule('Не менее 8 символов', p.length >= 8),
                _rule('Есть цифра', RegExp(r'\d').hasMatch(p)),
                _rule(
                  'Есть спецсимвол',
                  RegExp(r'[!@#$%^&*(),.?":{}|<>_\-+=\[\]\\;/`~]').hasMatch(p),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _rule(String text, bool ok) {
    return Row(
      children: [
        Icon(
          ok ? Icons.check_circle : Icons.radio_button_unchecked,
          size: 16,
          color: ok ? Colors.green : Colors.grey,
        ),
        const SizedBox(width: 6),
        Text(text, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}
