import '../models/post_model.dart';
import '../models/feed_context.dart';
import '../providers/post_store_provider.dart';
import '../utils/feed_selectors.dart';

/// Responsabilidad principal:
/// Implementación de la capa de "Read Model" en la arquitectura CQRS, cacheando vistas proyectadas de los Feeds.
///
/// Flujo dentro de la app:
/// `PostStoreProvider` delega en este servicio la reconstrucción de las listas de `PostModel` a partir de sus IDs, evitando procesamientos costosos innecesarios (O(K)).
///
/// Dependencias críticas:
/// - `PostStoreProvider` (Fuente de la verdad de los posts normalizados).
/// - `FeedSelectors` (Pure functions para mapear índices a objetos).
///
/// Side Effects:
/// - Mantiene referencias en memoria en `_cache` y `_lastFingerprint`.
///
/// Recordatorios técnicos y CQRS:
/// - Crítico llamar a `evict` cuando un feed ya no se muestra para no causar memory leaks con feeds secundarios grandes.
class ReadModelCacheService {
  final Map<FeedContext, List<PostModel>> _cache = {};
  final Map<FeedContext, String> _lastFingerprint = {};

  List<PostModel> getFeed(PostStoreProvider store, FeedContext context) {
    final currentFingerprint = store.getFingerprint(context);

    // Cache hit O(1)
    if (_lastFingerprint[context] == currentFingerprint &&
        _cache.containsKey(context)) {
      return _cache[context]!;
    }

    // Cache miss: recomputar O(K)
    final ids = store.getContextIndex(context);
    final result = FeedSelectors.select(ids, store.postsById);

    _cache[context] = result;
    _lastFingerprint[context] = currentFingerprint;
    return result;
  }

  /// Llamar cuando el usuario sale de un feed para liberar memoria
  void evict(FeedContext context) {
    _cache.remove(context);
    _lastFingerprint.remove(context);
  }

  /// Limpiar todo (en dispose del provider)
  void disposeAll() {
    _cache.clear();
    _lastFingerprint.clear();
  }
}
