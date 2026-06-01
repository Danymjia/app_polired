import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import '../models/feed_context.dart';
import '../models/post_model.dart';
import '../providers/post_store_provider.dart';
import '../services/read_model_cache_service.dart';

/// Responsabilidad principal:
/// Facade/Selector reactivo (Query Layer) para conectar la UI con el `PostStoreProvider` previniendo redibujos innecesarios.
///
/// Flujo dentro de la app:
/// Consumido directamente por los Widgets de listas de Posts. Utiliza `context.select` sobre el `fingerprint` del contexto de ese Feed.
///
/// Dependencias críticas:
/// - `PostStoreProvider` (Caché crudo).
/// - `ReadModelCacheService` (Caché computada y ordenada).
///
/// Side Effects:
/// - Ninguno. Selector de lectura pura.
///
/// Recordatorios técnicos y CQRS:
/// - PUNTO CRÍTICO DE RENDIMIENTO: Usar `context.watch<PostStoreProvider>()` destruiría los frames de la app. `context.select` sobre el fingerprint evita jank masivo.
class FeedProvider {
  /// Devuelve el feed reaccional para el contexto dado.
  /// Se suscribe SOLO a los cambios de ese contexto específico (vía fingerprint),
  /// evitando reconstrucciones cuando otros feeds cambian.
  static List<PostModel> watchFeed(BuildContext context, FeedContext feedContext) {
    // 1. Selector reactivo: re-evalúa el widget si el fingerprint de ESTE contexto cambia.
    context.select<PostStoreProvider, String>(
      (store) => store.getFingerprint(feedContext),
    );
    
    // 2. Fetcher puro: usa el caché y el store actual
    final store = context.read<PostStoreProvider>();
    final cache = context.read<ReadModelCacheService>();
    return cache.getFeed(store, feedContext);
  }
}
