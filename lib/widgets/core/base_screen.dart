import 'package:flutter/material.dart';

/// Responsabilidad principal:
/// Layout base que estandariza la estructura principal de las pantallas, manejando el Scaffold, SafeArea y el teclado.
///
/// Flujo dentro de la app:
/// Utilizado como contenedor raíz en múltiples pantallas para evitar reescribir lógica de SafeArea y `unfocus` del teclado.
///
/// Dependencias críticas:
/// - Ninguna.
///
/// Side Effects:
/// - Oculta el teclado automáticamente al tocar fuera de un input (`dismissKeyboardOnTap`).
///
/// Recordatorios técnicos y CQRS:
/// - Es un componente puramente presentacional.
class BaseScreen extends StatelessWidget {
  const BaseScreen({
    super.key,
    required this.body,
    this.safeAreaTop = true,
    this.safeAreaBottom = true,
    this.resizeToAvoidBottomInset = true,
    this.dismissKeyboardOnTap = true,
    this.appBar,
    this.bottomNavigationBar,
    this.backgroundColor,
  });

  final Widget body;
  final bool safeAreaTop;
  final bool safeAreaBottom;
  final bool resizeToAvoidBottomInset;
  final bool dismissKeyboardOnTap;
  final PreferredSizeWidget? appBar;
  final Widget? bottomNavigationBar;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    Widget content = SafeArea(
      top: safeAreaTop,
      bottom: safeAreaBottom,
      child: body,
    );

    if (dismissKeyboardOnTap) {
      content = GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: content,
      );
    }

    return Scaffold(
      backgroundColor: backgroundColor,
      resizeToAvoidBottomInset: resizeToAvoidBottomInset,
      appBar: appBar,
      body: content,
      bottomNavigationBar: bottomNavigationBar,
    );
  }
}
