import 'dart:async';
import '../models/events/post_event.dart';

/// Bus de eventos de navegación.
/// Permite desacoplar la emisión de [NavigationEvent] (ej. [FocusPostEvent])
/// del consumidor ([NavigationService]) sin dependencias directas.
class NavigationBus {
  final _controller = StreamController<NavigationEvent>.broadcast();

  /// Stream al que se suscriben los consumidores (ej. [NavigationService]).
  Stream<NavigationEvent> get stream => _controller.stream;

  /// Emite un evento de navegación a todos los suscriptores activos.
  void dispatch(NavigationEvent event) {
    if (!_controller.isClosed) {
      _controller.add(event);
    }
  }

  /// Libera los recursos del stream controller.
  void dispose() {
    _controller.close();
  }
}
