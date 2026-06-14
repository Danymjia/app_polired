import 'package:flutter/material.dart';

/// Responsabilidad principal:
/// Insignia visual (Tooltip y Icono) para distinguir redes Verificadas (Azul) u Oficiales (Dorado).
///
/// Flujo dentro de la app:
/// Integrado como overlay (Positioned) dentro de componentes más grandes como `NetworkAvatar` o encabezados de perfil.
///
/// Dependencias críticas:
/// - Ninguna.
///
/// Side Effects:
/// - Ninguno.
///
/// Recordatorios técnicos y CQRS:
/// - Prioridad: Si una red tiene ambos booleanos verdaderos, se mostrará como "Oficial" (Dorado) por regla de negocio.
class NetworkBadge extends StatelessWidget {
  final bool esVerificada;
  final bool esOficial;

  const NetworkBadge({
    super.key,
    required this.esVerificada,
    required this.esOficial,
  });

  @override
  Widget build(BuildContext context) {
    if (!esVerificada && !esOficial) return const SizedBox.shrink();

    // Si por alguna razón tiene ambas (aunque el backend debería evitarlo),
    // damos prioridad a la oficial según los requerimientos.
    final isGold = esOficial;
    final color = isGold ? const Color(0xFFE9C46A) : const Color(0xFF3B82F6);

    return Tooltip(
      message: isGold ? 'Red Oficial' : 'Red Verificada',
      triggerMode: TooltipTriggerMode.tap,
      child: Container(
        width: 24, // Ajustado ligeramente para móvil para que no se vea gigante
        height: 24,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 2.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: const Center(
          child: Icon(
            Icons.check_circle,
            color: Colors.white,
            size: 14,
          ),
        ),
      ),
    );
  }
}
