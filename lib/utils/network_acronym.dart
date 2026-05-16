/// Genera siglas a partir del nombre de una red (mismas reglas que el home).
/// Ej.: "Facultad de Ingeniería Eléctrica y Electrónica" → "FIEE"
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
