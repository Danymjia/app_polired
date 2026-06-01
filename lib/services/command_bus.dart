import 'dart:async';
import '../models/commands/feed_command.dart';
import 'handlers/command_handler.dart';

/// Responsabilidad principal:
/// Enrutador del patrón CQRS (Command Bus). Se encarga de mapear cada objeto Comando (intención) hacia su Controlador (CommandHandler) específico.
///
/// Flujo dentro de la app:
/// La UI instancia un Comando y hace `dispatch()`. El Bus busca su respectivo Handler en el diccionario `_handlers` y ejecuta la lógica de mutación de forma agnóstica.
///
/// Dependencias críticas:
/// - `CommandHandler` (Interfaces base).
///
/// Side Effects:
/// - Ninguno propio. Actúa de semáforo.
///
/// Recordatorios técnicos y CQRS:
/// - Registro Temprano: Todos los Handlers deben ser inyectados/registrados (`registerHandler`) en el arranque de la app (generalmente en `service_locator.dart` o `main.dart`). Si se omite, la app lanzará un `StateError` crítico en runtime.
class CommandBus {
  final Map<Type, CommandHandler> _handlers = {};

  void registerHandler<T extends FeedCommand>(CommandHandler<T> handler) {
    _handlers[T] = handler;
  }

  Future<CommandResult> dispatch<T extends FeedCommand>(T command) async {
    final handler = _handlers[command.runtimeType] as CommandHandler<T>?;
    if (handler == null) {
      throw StateError('No handler registered for command type: ${command.runtimeType}');
    }
    return handler.handle(command);
  }
}
