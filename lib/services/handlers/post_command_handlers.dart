import '../../models/commands/feed_command.dart';
import '../../models/events/post_event.dart';
import '../../utils/post_context_resolver.dart';
import '../../providers/post_store_provider.dart';
import '../../services/post_service.dart';
import '../../models/feed_context.dart';
import '../../models/post_model.dart';
import '../navigation_bus.dart';
import 'command_handler.dart';

class CreatePostCommandHandler extends CommandHandler<CreatePostCommand> {
  final PostService _postService;
  final PostStoreProvider _store;
  final NavigationBus _navigationBus;

  CreatePostCommandHandler(this._postService, this._store, this._navigationBus);

  @override
  Future<CommandResult> handle(CreatePostCommand command) async {
    try {
      final backendFeedContext = command.feedContext.type == ContextType.home ? 'home' : 'global';
      
      final isArticle = command.category == 'venta' || command.category == 'cursos';

      final response = isArticle
          ? await _postService.createArticle(
              feedContext: backendFeedContext,
              titulo: command.title,
              descripcion: command.content, // createArticle uses 'descripcion' instead of 'contenido'
              precio: command.price ?? 0.0,
              categoria: command.category,
              comunidadId: command.networkId,
              tipoContenido: command.postType,
              imageFiles: command.imageFiles,
              aspectRatio: command.aspectRatio,
            )
          : (command.postType == 'imagen'
              ? await _postService.createPost(
                  feedContext: backendFeedContext,
                  contenido: command.content,
                  categoria: command.category,
                  titulo: command.title,
                  comunidadId: command.networkId,
                  imageFiles: command.imageFiles,
                  aspectRatio: command.aspectRatio,
                )
              : await _postService.createPost(
                  feedContext: backendFeedContext,
                  contenido: command.content,
                  categoria: command.category,
                  titulo: command.title,
                  comunidadId: command.networkId,
                ));

      if (response.success && response.data != null) {
        try {
          final dynamicData = response.data;
          final postData = dynamicData['post'] ?? dynamicData['publicacion'] ?? dynamicData['articulo'] ?? dynamicData;
          final postModel = PostModel.fromJson(postData);

          final contextsToUpdate = PostContextResolver.resolveContexts(postModel);

          for (final targetContext in contextsToUpdate) {
            final event = PostCreated(
              eventId: 'evt_${postModel.id}_${targetContext.id}_${DateTime.now().millisecondsSinceEpoch}',
              sequenceNumber: _store.nextSequenceNumber(targetContext),
              context: targetContext,
              post: postModel,
            );
            _store.applyStateEvent(event);
          }

          final targetTab = PostContextResolver.resolveNavigationTarget(command.feedContext, postModel);
          _navigationBus.dispatch(FocusPostEvent(
            postId: postModel.id,
            context: targetTab,
          ));

          return CommandResult(success: true, data: postModel.id);
        } catch (e) {
          // Fallback if parsing fails
          return CommandResult(success: false, error: 'Error procesando respuesta del servidor');
        }
      }
      return CommandResult(success: false, error: response.message ?? 'Error creating post');
    } catch (e) {
      return CommandResult(success: false, error: e.toString());
    }
  }
}

class ToggleLikeCommandHandler extends CommandHandler<ToggleLikeCommand> {
  final PostService _postService;
  final PostStoreProvider _store;

  ToggleLikeCommandHandler(this._postService, this._store);

  @override
  Future<CommandResult> handle(ToggleLikeCommand command) async {
    final post = _store.getPost(command.postId);
    if (post == null) return CommandResult(success: false, error: 'Post not found');

    final bool wasLiked = post.likedByMe;
    final int newLikeCount = wasLiked ? (post.likesCount - 1).clamp(0, double.infinity).toInt() : post.likesCount + 1;
    final bool newLiked = !wasLiked;

    // 1. Emisión optimista (UI Event) O(1)
    _store.emitUIEvent(PostInteractionUpdated(
      postId: post.id,
      likeCount: newLikeCount,
      liked: newLiked,
      saved: post.savedByMe,
      commentCount: post.commentsCount,
    ));

    // 2. Operación de red
    final success = await _postService.toggleLike(command.postId, wasLiked);

    if (!success) {
      // 3. Rollback
      _store.emitUIEvent(PostInteractionUpdated(
        postId: post.id,
        likeCount: post.likesCount,
        liked: post.likedByMe,
        saved: post.savedByMe,
        commentCount: post.commentsCount,
      ));
      return CommandResult(success: false, error: 'Failed to toggle like');
    }
    return CommandResult(success: true);
  }
}

class ToggleSaveCommandHandler extends CommandHandler<ToggleSaveCommand> {
  final PostService _postService;
  final PostStoreProvider _store;

  ToggleSaveCommandHandler(this._postService, this._store);

  @override
  Future<CommandResult> handle(ToggleSaveCommand command) async {
    final post = _store.getPost(command.postId);
    if (post == null) return CommandResult(success: false, error: 'Post not found');

    final bool wasSaved = post.savedByMe;
    final bool newSaved = !wasSaved;

    _store.emitUIEvent(PostInteractionUpdated(
      postId: post.id,
      likeCount: post.likesCount,
      liked: post.likedByMe,
      saved: newSaved,
      commentCount: post.commentsCount,
    ));

    final success = await _postService.toggleSave(command.postId, wasSaved);

    if (!success) {
      _store.emitUIEvent(PostInteractionUpdated(
        postId: post.id,
        likeCount: post.likesCount,
        liked: post.likedByMe,
        saved: post.savedByMe,
        commentCount: post.commentsCount,
      ));
      return CommandResult(success: false, error: 'Failed to toggle save');
    }
    return CommandResult(success: true);
  }
}

class InitializeSocialStateCommandHandler extends CommandHandler<InitializeSocialStateCommand> {
  final PostService _postService;
  final PostStoreProvider _store;

  InitializeSocialStateCommandHandler(this._postService, this._store);

  @override
  Future<CommandResult> handle(InitializeSocialStateCommand command) async {
    try {
      final likesResult = await _postService.fetchLikedPosts(page: 1, limit: 1000);
      final savesResult = await _postService.fetchSavedPosts();

      List<String> likedIds = [];
      List<String> savedIds = [];

      if (likesResult.success && likesResult.data != null) {
        likedIds = likesResult.data!.map((e) => e.id).toList();
      }
      if (savesResult.success && savesResult.data != null) {
        savedIds = savesResult.data!.map((e) => e.id).toList();
      }

      _store.setSocialHydration(likedIds, savedIds);

      return CommandResult(success: true);
    } catch (e) {
      return CommandResult(success: false, error: e.toString());
    }
  }
}

class DeletePostCommandHandler extends CommandHandler<DeletePostCommand> {
  final PostService _postService;
  final PostStoreProvider _store;

  DeletePostCommandHandler(this._postService, this._store);

  @override
  Future<CommandResult> handle(DeletePostCommand command) async {
    // 1. Guardar estado previo para rollback
    final post = _store.getPost(command.postId);
    if (post == null) return CommandResult(success: false, error: 'Post not found');

    final previousContexts = _store.getContextsForPost(command.postId);

    // 2. State Event: Delete optimista
    for (final context in previousContexts) {
      _store.applyStateEvent(PostDeleted(
        postId: command.postId,
        context: context,
        sequenceNumber: _store.nextSequenceNumber(context),
      ));
    }

    // Forzamos invalidación de feeds UI porque falta un ID en las listas resueltas.
    _store.incrementFeedVersionHome();
    _store.incrementFeedVersionGlobal();
    if (post.networkId.isNotEmpty) {
      _store.incrementFeedVersionNetwork(post.networkId);
    }

    // 3. Operación de red
    final isArticle = post.categoria == 'venta' || post.categoria == 'cursos';
    final result = await _postService.deletePost(command.postId, isArticle: isArticle);

    if (!result.success) {
      // 4. Rollback
      for (final context in previousContexts) {
        _store.applyStateEvent(PostCreated(
          post: post,
          context: context,
          sequenceNumber: _store.nextSequenceNumber(context),
        ));
      }
      _store.incrementFeedVersionHome();
      _store.incrementFeedVersionGlobal();
      return CommandResult(success: false, error: result.message ?? 'Failed to delete');
    }

    return CommandResult(success: true);
  }
}
