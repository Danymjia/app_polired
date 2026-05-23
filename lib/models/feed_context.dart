/// FeedContext es la ÚNICA fuente de decisión de destino de un post.
///
/// PROHIBIDO: usar `categoria` para decidir destino.
/// OBLIGATORIO: todo flujo de creación/sincronización usa [FeedContext].
enum ContextType { home, exploreGlobal, exploreTab, profile }

class FeedContext {
  final ContextType type;
  final String? communityId;   // usado en home
  final String? categoryId;    // usado en exploreTab
  final String? userId;        // usado en profile

  const FeedContext._({
    required this.type,
    this.communityId,
    this.categoryId,
    this.userId,
  });

  static FeedContext home({String? communityId}) =>
      FeedContext._(type: ContextType.home, communityId: communityId);

  static FeedContext exploreGlobal() =>
      const FeedContext._(type: ContextType.exploreGlobal);

  static FeedContext exploreTab({required String categoryId}) =>
      FeedContext._(type: ContextType.exploreTab, categoryId: categoryId);

  static FeedContext profile({required String userId}) =>
      FeedContext._(type: ContextType.profile, userId: userId.toString());

  @override
  bool operator ==(Object other) =>
      other is FeedContext &&
      other.type == type &&
      other.communityId == communityId &&
      other.categoryId == categoryId &&
      other.userId == userId;

  @override
  int get hashCode => Object.hash(type, communityId, categoryId, userId);

  String get id => '${type.name}_${communityId ?? ""}_${categoryId ?? ""}_${userId ?? ""}';

  String get name => id; // fallback for backwards compatibility
}

/// Estado paginado para el feed de una red específica en Home.
///
/// El [NetworkProvider] mantiene un [HomeFeedState] por cada [redId],
/// formando un cache multi-stream completamente aislado.
class HomeFeedState {
  final List<String> postIds = [];
  bool isLoadingInitial = false;
  bool isLoadingMore = false;
  bool hasMore = true;
  int currentPage = 1;
  String? errorMessage;

  bool get isEmpty => postIds.isEmpty;
}
