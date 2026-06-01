import 'package:uuid/uuid.dart';
import '../../models/post_model.dart';
import '../../models/feed_context.dart';

/// Responsabilidad principal:
/// Definición formal de Eventos (Event Sourcing / CQRS). Representan acciones que YA OCURRIERON y notifican a los stores o a la UI.
///
/// Flujo dentro de la app:
/// Emitidos por los `CommandHandlers` o WebSockets, y escuchados por `PostStoreProvider` (StateEvents), Widgets individuales (UIEvents) o `NavigationBus`.
///
/// Dependencias críticas:
/// - `uuid` para trazabilidad y deduplicación de eventos en un stream global.
///
/// Side Effects:
/// - Estos eventos INICIAN side effects locales (recálculo de listas, saltos de navegación, re-renders parciales).
///
/// Recordatorios técnicos y CQRS:
/// - La división semántica (State vs UI vs Navigation) es vital para el control de granularidad de renders, evitando redibujar listas completas por un simple "Like".
abstract class FeedEvent {
  final String eventId;
  final DateTime timestamp;

  FeedEvent({
    String? eventId,
    DateTime? timestamp,
  })  : eventId = eventId ?? const Uuid().v4(),
        timestamp = timestamp ?? DateTime.now();
}

// ─── STATE EVENTS (Mutación de Store) ──────────────────────────────────────
/// Estos eventos modifican la consistencia de los datos cacheados en el PostStore.
abstract class StateEvent extends FeedEvent {
  final int sequenceNumber;
  final FeedContext context;

  StateEvent({
    required this.sequenceNumber,
    required this.context,
    super.eventId,
    super.timestamp,
  });
}

class PostCreated extends StateEvent {
  final PostModel post;

  PostCreated({
    required this.post,
    required super.sequenceNumber,
    required super.context,
    super.eventId,
    super.timestamp,
  });
}

class PostDeleted extends StateEvent {
  final String postId;

  PostDeleted({
    required this.postId,
    required super.sequenceNumber,
    required super.context,
    super.eventId,
    super.timestamp,
  });
}

class PostUpdated extends StateEvent {
  final PostModel post;

  PostUpdated({
    required this.post,
    required super.sequenceNumber,
    required super.context,
    super.eventId,
    super.timestamp,
  });
}

// ─── UI EVENTS (Refresco Granular O(1)) ─────────────────────────────────────
/// Estos eventos NO reconstruyen la lista entera, SOLO notifican a widgets individuales
/// (ej. PostCard) o cambian variables aisladas, sin incrementar el feedVersion general.
abstract class UIEvent extends FeedEvent {
  UIEvent({super.eventId, super.timestamp});
}

class PostInteractionUpdated extends UIEvent {
  final String postId;
  final int likeCount;
  final bool liked;
  final bool saved;
  final int commentCount;

  PostInteractionUpdated({
    required this.postId,
    required this.likeCount,
    required this.liked,
    required this.saved,
    required this.commentCount,
    super.eventId,
    super.timestamp,
  });
}

// ─── NAVIGATION EVENTS (Efectos Visuales Puros) ─────────────────────────────
abstract class NavigationEvent extends FeedEvent {
  final String postId;
  final FeedContext context;

  NavigationEvent({
    required this.postId,
    required this.context,
    super.eventId,
    super.timestamp,
  });
}

class FocusPostEvent extends NavigationEvent {
  FocusPostEvent({
    required super.postId,
    required super.context,
    super.eventId,
    super.timestamp,
  });
}
