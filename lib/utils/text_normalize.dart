String normalizeKey(String value) =>
    value.trim().replaceAll(RegExp(r'\s+'), '').toLowerCase();

/// Сравнение названий (направление, тег и т.п.): без лишних пробелов, без учёта регистра.
String normalizeName(String value) =>
    value.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
