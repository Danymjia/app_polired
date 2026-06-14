import 'package:flutter/material.dart';

/// Responsabilidad principal:
/// Envuelve el contenido en un `SingleChildScrollView` y `IntrinsicHeight` para asegurar que la UI se adapte cuando aparece el teclado.
///
/// Flujo dentro de la app:
/// Usado en pantallas de autenticación y formularios donde el teclado puede tapar botones o campos importantes.
///
/// Dependencias críticas:
/// - Ninguna.
///
/// Side Effects:
/// - Fuerza a la UI a recalcular su altura mínima igualando el alto de la pantalla disponible.
///
/// Recordatorios técnicos y CQRS:
/// - Altamente acoplado con `resizeToAvoidBottomInset` del Scaffold. Si el Scaffold padre no lo tiene activo, esto no hará efecto.
class KeyboardAwareLayout extends StatelessWidget {
  const KeyboardAwareLayout({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: constraints.maxHeight,
            ),
            child: IntrinsicHeight(
              child: child,
            ),
          ),
        );
      },
    );
  }
}
