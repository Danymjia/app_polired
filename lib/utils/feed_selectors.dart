import '../models/post_model.dart';

/// Responsabilidad principal:
/// Proyección pura (Query side en CQRS) para mapear IDs de posts al modelo real desde el store (`PostStoreProvider`) ordenados por fecha.
///
/// Flujo dentro de la app:
/// Consumido masivamente por los Providers de Feed (`GlobalFeedProvider`, etc.) para armar las listas de UI.
///
/// Dependencias críticas:
/// - Ninguna externa.
///
/// Side Effects:
/// - Ninguno. Función 100% pura y síncrona.
///
/// Recordatorios técnicos y CQRS:
/// - Rendimiento: `.sort` ordena la lista sincrónicamente; si la cantidad de IDs crece masivamente, podría causar jank en el UI thread.

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
