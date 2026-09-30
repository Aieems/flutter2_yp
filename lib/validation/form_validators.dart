class FormValidators {
  static String? required(String? value, {String label = 'Поле'}) {
    if (value == null || value.trim().isEmpty) {
      return '$label обязательно';
    }
    return null;
  }

  static String? length(
    String? value, {
    required int min,
    required int max,
    String label = 'Поле',
  }) {
    if (value == null) return null;
    final len = value.trim().length;
    if (len < min || len > max) {
      return '$label: от $min до $max символов';
    }
    return null;
  }

  static String? intRange(
    String? value, {
    required int min,
    required int max,
    String label = 'Число',
  }) {
    if (value == null || value.trim().isEmpty) {
      return '$label обязательно';
    }
    final n = int.tryParse(value.trim());
    if (n == null) return 'Введите целое число';
    if (n < min || n > max) return '$label: от $min до $max';
    return null;
  }

  static String? positiveInt(String? value, {String label = 'Количество'}) {
    if (value == null || value.trim().isEmpty) {
      return '$label обязательно';
    }
    final n = int.tryParse(value.trim());
    if (n == null || n <= 0) return '$label должно быть больше 0';
    return null;
  }

  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email обязателен';
    }
    final v = value.trim();
    final re = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
    if (!re.hasMatch(v)) return 'Некорректный email';
    if (v.length > 120) return 'Email слишком длинный';
    return null;
  }

  static String? projectCode(String? value) {
    final req = required(value, label: 'ISBN');
    if (req != null) return req;
    return length(value, min: 3, max: 32, label: 'ISBN');
  }

  static String? year(String? value) {
    return intRange(value, min: 1990, max: 2100, label: 'Год');
  }
}
