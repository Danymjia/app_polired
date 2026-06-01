import 'dart:async';
import '../models/events/post_event.dart';

/// Responsabilidad principal:
/// Bus de Eventos pub/sub (basado en Streams) exclusivo para notificaciones visuales/navegación.
///
/// Flujo dentro de la app:
/// Permite que un Command (o un Service), que no tiene acceso al `BuildContext` de Flutter, emita un `NavigationEvent`. El `NavigationService` lo captura y reacciona visualmente.
///
/// Dependencias críticas:
/// - `StreamController`.
///
/// Side Effects:
/// - Emisión reactiva.
///
/// Recordatorios técnicos y CQRS:
/// - Patrón de Desacoplamiento: Esto es lo que permite que la capa de dominio sea testeable unitariamente sin involucrar paquetes de UI.
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
