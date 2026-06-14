import 'package:flutter/material.dart';
import '../../../config/theme.dart';

/// Responsabilidad principal:
/// Componente de navegación por pestañas (Tabs) personalizado para la sección Explorar.
///
/// Flujo dentro de la app:
/// Se utiliza para alternar entre la vista de Redes y la vista de Usuarios.
///
/// Dependencias críticas:
/// - Ninguna (Recibe callbacks y estados por parámetros).
///
/// Side Effects:
/// - Dispara `onTabSelected` cuando el usuario cambia de pestaña.
///
/// Recordatorios técnicos y CQRS:
/// - Componente presentacional puro. El estado de la pestaña activa se mantiene en el widget padre.
class ExploreTabs extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onTabSelected;
  final List<String> tabs;

  const ExploreTabs({
    super.key,
    required this.selectedIndex,
    required this.onTabSelected,
    required this.tabs,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.surface.withAlpha(230),
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: AppTheme.surfaceContainerHighest,
              width: 1,
            ),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(tabs.length, (index) {
            final isActive = index == selectedIndex;
            return GestureDetector(
              onTap: () => onTabSelected(index),
              child: Container(
                padding: const EdgeInsets.only(bottom: 4),
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: isActive ? AppTheme.onSurface : Colors.transparent,
                      width: 2,
                    ),
                  ),
                ),
                child: Center(
                  child: Text(
                    tabs[index],
                    style: AppTheme.bodyMedium.copyWith(
                      fontSize: 14,
                      fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                      color: isActive ? AppTheme.onSurface : AppTheme.outline,
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}
