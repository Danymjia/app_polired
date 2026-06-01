/// Responsabilidad principal:
/// Generar siglas formateadas a partir del nombre de una red o comunidad.
///
/// Flujo dentro de la app:
/// Utilizado por los componentes visuales de avatares como "Fallback" cuando una comunidad no tiene imagen propia.
///
/// Dependencias críticas:
/// - Ninguna.
///
/// Side Effects:
/// - Ninguno. Función 100% pura.
///
/// Recordatorios técnicos y CQRS:
/// - `stopWords` están hardcodeadas en español. Vigilar escalabilidad de internacionalización.
String buildNetworkAcronym(String name) {
  final words = name.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
  if (words.isEmpty) return '?';
  if (words.length == 1) {
    final w = words.first;
    return w.substring(0, w.length.clamp(0, 3)).toUpperCase();
  }
  const stopWords = {'de', 'del', 'la', 'el', 'los', 'las', 'y', 'e', 'o', 'u'};
  final siglas = words
      .where((w) => !stopWords.contains(w.toLowerCase()))
      .map((w) => w[0].toUpperCase())
      .join();
  if (siglas.isEmpty) return words.first[0].toUpperCase();
  return siglas.substring(0, siglas.length.clamp(0, 5));
}
