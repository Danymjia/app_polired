/// Responsabilidad principal:
/// Modelo visual (View Model) ligero usado exclusivamente para renderizar las burbujas superiores ("Stories") en el Home.
///
/// Flujo dentro de la app:
/// Proyectado en memoria dentro de `NetworkProvider` a partir de datos más complejos del backend.
///
/// Dependencias críticas:
/// - Ninguna externa.
///
/// Side Effects:
/// - Ninguno. 
///
/// Recordatorios técnicos y CQRS:
/// - Este modelo no tiene `fromJson` porque no se mapea directamente de la API. Es una Proyección pura adaptada para la UI.
class NetworkStoryModel {
  final String id;
  final String name;
  final String imageUrl;
  final bool isJoined;
  final String acronym;

  NetworkStoryModel({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.isJoined,
    required this.acronym,
  });
}
