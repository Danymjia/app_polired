import '../../models/commands/feed_command.dart';

/// Responsabilidad principal:
/// Clase base (interfaz) para implementar manejadores de comandos (Command Handlers) del patrón CQRS.
///
/// Flujo dentro de la app:
/// Extendida por comandos específicos (ej. CreatePostHandler) para separar la intención del usuario de la ejecución de red y actualización del estado.
///
/// Dependencias críticas:
/// - `FeedCommand` (Payload del comando).
///
/// Side Effects:
/// - Ninguno por sí misma; las implementaciones disparan efectos secundarios (HTTP, Store).
///
/// Recordatorios técnicos y CQRS:
/// - Fomenta el principio de Responsabilidad Única (SRP). Todo nuevo comando de escritura debe implementar esta interfaz.
abstract class CommandHandler<T extends FeedCommand> {
  Future<CommandResult> handle(T command);
}
