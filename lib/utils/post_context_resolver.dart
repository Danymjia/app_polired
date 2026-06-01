import '../models/feed_context.dart';
import '../models/post_model.dart';

/// Responsabilidad principal:
/// Lógica de dominio. Determina a qué contextos lógicos (Feeds) pertenece un Post recién creado.
///
/// Flujo dentro de la app:
/// Consumido fuertemente por `CreatePostCommandHandler` y `NavigationBus` tras una creación exitosa para saber dónde indexar la vista y hacia dónde rutar al usuario.
///
/// Dependencias críticas:
/// - Modelos `FeedContext` y `PostModel`.
///
/// Side Effects:
/// - Ninguno directo, pero dicta qué mutaciones realizará `PostStoreProvider`.
///
/// Recordatorios técnicos y CQRS:
/// - Regla de negocio crítica: Si cambian las políticas de visibilidad de publicaciones en el Backend, DEBE reflejarse aquí para evitar "Ghost Posts" locales (Inconsistencia Estado-API).

class PostContextResolver {
  /// Devuelve TODOS los contextos en los que este post debe aparecer
  static List<FeedContext> resolveContexts(PostModel post) {
    final contexts = <FeedContext>[];

    // 1. Siempre al perfil del autor
    contexts.add(FeedContext.profile(userId: post.authorId.toString()));

    // 2. Si tiene comunidad, va a Home
    if (post.networkId.isNotEmpty) {
      contexts.add(FeedContext.home(communityId: post.networkId.toString()));
    }

    // 3. Explorar Global
    contexts.add(FeedContext.exploreGlobal());
    
    // 4. Explorar por categoría
    if (post.categoria.isNotEmpty) {
      contexts.add(FeedContext.exploreTab(categoryId: post.categoria.toString()));
    }

    return contexts;
  }

  /// Decide a qué feed debe saltar el usuario después de crear
  static FeedContext resolveNavigationTarget(FeedContext creationContext, PostModel post) {
    // Si lo creó con intención de home, vamos al home de esa comunidad
    if (creationContext.type == ContextType.home) {
      return FeedContext.home(communityId: post.networkId.toString());
    }
    // Si lo creó con intención global, vamos al tab de su categoría en explorar
    if (creationContext.type == ContextType.exploreGlobal || creationContext.type == ContextType.exploreTab) {
      return FeedContext.exploreTab(categoryId: post.categoria.toString());
    }
    // Fallback
    return FeedContext.profile(userId: post.authorId.toString());
  }
}
