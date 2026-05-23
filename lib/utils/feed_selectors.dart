import '../models/post_model.dart';

class FeedSelectors {
  /// Proyección pura: Mapea IDs al estado real y los ordena descendentemente por timestamp.
  static List<PostModel> select(
      Iterable<String> ids, Map<String, PostModel> storeMap) {
    return ids
        .map((id) => storeMap[id])
        .whereType<PostModel>() // filtramos nulls por seguridad
        .toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }
}
