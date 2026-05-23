import '../models/post_model.dart';
import '../models/feed_context.dart';
import '../providers/post_store_provider.dart';
import '../utils/feed_selectors.dart';

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
