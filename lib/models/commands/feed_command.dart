import 'dart:io';
import '../events/post_event.dart';
import '../../models/feed_context.dart';

/// Responsabilidad principal:
/// Definición formal de Comandos (Command Side - CQRS) que expresan intención del usuario para mutar estado (Crear, Dar Like, Borrar).
///
/// Flujo dentro de la app:
/// Instanciados desde la UI (ej. botón de "Like") y despachados hacia los `CommandHandlers` (ej. `ToggleLikeCommandHandler`) a través del `CommandBus`.
///
/// Dependencias críticas:
/// - `post_event.dart` (Eventos asociados para posibles Rollbacks u Optmistic Updates).
/// - `dart:io` (Manejo de archivos físicos temporales para uploads).
///
/// Side Effects:
/// - Estos objetos EN SÍ no tienen side effects, son DTOs de intención, pero su *ejecución* vía Handlers dispara llamadas HTTP y mutaciones masivas de estado.
///
/// Recordatorios técnicos y CQRS:
/// - CQRS Puro: Un comando no debe retornar datos de dominio, excepto el `CommandResult` genérico para confirmación de éxito/fallo a la UI.
abstract class FeedCommand {}

class CreatePostCommand extends FeedCommand {
  final FeedContext feedContext;
  final String category;
  final String content;
  final String? title;
  final String? networkId;
  final String? networkName;
  final String postType; // 'texto' o 'imagen'
  final List<File>? imageFiles;
  final double? price;
  final double aspectRatio;

  CreatePostCommand({
    required this.feedContext,
    required this.category,
    required this.content,
    required this.postType,
    this.title,
    this.networkId,
    this.networkName,
    this.imageFiles,
    this.price,
    this.aspectRatio = 1.0,
  });
}

class DeletePostCommand extends FeedCommand {
  final String postId;

  DeletePostCommand({required this.postId});
}

class ToggleLikeCommand extends FeedCommand {
  final String postId;

  ToggleLikeCommand({required this.postId});
}

class ToggleSaveCommand extends FeedCommand {
  final String postId;

  ToggleSaveCommand({required this.postId});
}

class InitializeSocialStateCommand extends FeedCommand {}

class CommandResult {
  final bool success;
  final String? error;
  final StateEvent? rollbackEvent;
  final dynamic data;

  CommandResult({
    required this.success,
    this.error,
    this.rollbackEvent,
    this.data,
  });
}
