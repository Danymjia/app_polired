import 'package:flutter_test/flutter_test.dart';
import 'package:polired/providers/post_store_provider.dart';
import 'package:polired/models/post_model.dart';
import 'package:polired/models/feed_context.dart';
import 'package:polired/models/events/post_event.dart';

void main() {
  group('PostStoreProvider (CQRS Phase 1)', () {
    late PostStoreProvider store;
    
    final dummyPost = PostModel(
      id: 'post_1',
      networkId: 'net_1',
      networkName: 'Network 1',
      authorId: 'user_1',
      authorUsername: 'user1',
      authorFullName: 'User One',
      titulo: 'Test Post',
      contenido: 'Content',
      tipoContenido: 'texto',
      categoria: 'comunidad',
      mediaUrls: [],
      likesCount: 0,
      commentsCount: 0,
      timestamp: DateTime.now(),
    );

    setUp(() {
      store = PostStoreProvider();
    });

    test('idempotencia de eventos duplicados: aplica solo una vez', () {
      final event1 = PostCreated(
        eventId: 'event-123',
        sequenceNumber: 1,
        context: FeedContext.home(),
        post: dummyPost,
      );

      store.applyPostCreated(event1);
      
      expect(store.postsById.length, 1);
      expect(store.getContextIndex(FeedContext.home()).length, 1);

      // Duplicate event
      final event2 = PostCreated(
        eventId: 'event-123',
        sequenceNumber: 1,
        context: FeedContext.home(),
        post: dummyPost,
      );

      store.applyPostCreated(event2);
      
      // Still 1
      expect(store.postsById.length, 1);
      expect(store.getContextIndex(FeedContext.home()).length, 1);
    });

    test('ignora eventos con sequenceNumber desactualizado', () {
      final event1 = PostCreated(
        eventId: 'event-1',
        sequenceNumber: 2,
        context: FeedContext.home(),
        post: dummyPost,
      );

      store.applyPostCreated(event1);
      
      // Stale event
      final staleEvent = PostCreated(
        eventId: 'event-stale',
        sequenceNumber: 1,
        context: FeedContext.home(),
        post: dummyPost.copyWith(id: 'post_2'),
      );

      store.applyPostCreated(staleEvent);
      
      // Should ignore stale
      expect(store.postsById.length, 1);
      expect(store.postsById.containsKey('post_2'), false);
    });

    test('fingerprint cambia en mutación', () {
      final fingerprint1 = store.getFingerprint(FeedContext.home());
      
      final event1 = PostCreated(
        eventId: 'event-1',
        sequenceNumber: 1,
        context: FeedContext.home(),
        post: dummyPost,
      );

      store.applyPostCreated(event1);
      
      final fingerprint2 = store.getFingerprint(FeedContext.home());
      expect(fingerprint1, isNot(equals(fingerprint2)));
      
      final event2 = PostUpdated(
        eventId: 'event-2',
        sequenceNumber: 2,
        context: FeedContext.home(),
        post: dummyPost.copyWith(likesCount: 1),
      );

      store.applyPostUpdated(event2);
      
      final fingerprint3 = store.getFingerprint(FeedContext.home());
      expect(fingerprint2, isNot(equals(fingerprint3)));
    });
  });
}
