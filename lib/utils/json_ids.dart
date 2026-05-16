/// Normaliza identificadores Mongo / JSON genéricos a [String].
///
/// Acepta: [String], [int] (algunas APIs serializan numérico), [Map] con
/// `$oid`, o mapas que contengan anidados `_id` / `id`.
/// Devuelve null si el valor es nulo, vacío o no reconocible como id.
String? parseMongoId(dynamic value) {
  if (value == null) return null;
  if (value is String) {
    final t = value.trim();
    return t.isEmpty ? null : t;
  }
  if (value is int) {
    return value.toString();
  }
  if (value is Map) {
    final m = Map<String, dynamic>.from(value);
    final oid = m[r'$oid'];
    if (oid is String) {
      final t = oid.trim();
      if (t.isNotEmpty) return t;
    }
    if (m.containsKey('_id') || m.containsKey('id')) {
      return parseMongoIdFromMap(m);
    }
    return null;
  }
  final s = value.toString().trim();
  if (s.isEmpty || s == 'null') return null;
  return s;
}

/// Lee un id desde respuestas que pueden usar `_id`, `id` u otro orden.
///
/// [keys] define el orden de preferencia (por defecto `_id` primero, luego `id`).
String? parseMongoIdFromMap(
  Map<String, dynamic> json, {
  List<String> keys = const ['_id', 'id'],
}) {
  for (final key in keys) {
    if (!json.containsKey(key)) continue;
    final parsed = parseMongoId(json[key]);
    if (parsed != null && parsed.isNotEmpty) return parsed;
  }
  return null;
}

DateTime? parseDate(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  if (value is String) return DateTime.tryParse(value);
  if (value is Map && value[r'$date'] != null) {
    final d = value[r'$date'];
    if (d is String) return DateTime.tryParse(d);
    if (d is int) return DateTime.fromMillisecondsSinceEpoch(d);
  }
  return null;
}
