/// Responsabilidad principal:
/// Tokens estáticos de espaciado para paddings y margins consistentes en la UI.
///
/// Flujo dentro de la app:
/// Importado transversalmente en la capa visual (`/widgets` y `/screens`).
///
/// Dependencias críticas:
/// - Ninguna.
///
/// Side Effects:
/// - Ninguno.
///
/// Recordatorios técnicos y CQRS:
/// - No reemplazar estos valores estáticos por literales numéricos sueltos (ej. `padding: EdgeInsets.all(16)`) para mantener consistencia.
class AppSpacing {
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;
}
