import 'dart:async';
import '../models/commands/feed_command.dart';
import 'handlers/command_handler.dart';

/// CommandBus es estrictamente un enrutador. 
/// NO contiene lógica de negocio, red, ni almacenamiento.
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
