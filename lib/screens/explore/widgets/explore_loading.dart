import 'package:flutter/material.dart';
import '../../../config/theme.dart';

/// Responsabilidad principal:
/// Animación de esqueleto (Skeleton) para indicar carga en el feed de Explorar.
///
/// Flujo dentro de la app:
/// Renderizado inicial mientras se cargan los datos iniciales de las publicaciones.
///
/// Dependencias críticas:
/// - Ninguna (Widget presentacional).
///
/// Side Effects:
/// - Ninguno.
///
/// Recordatorios técnicos y CQRS:
/// - Optimizado para rendimiento con `SliverList` y colores predefinidos del tema.
class ExploreLoading extends StatelessWidget {
  const ExploreLoading({super.key});

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: AppTheme.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(AppTheme.radiusXl),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        _SkeletonCircle(size: 48),
                        const SizedBox(width: 12),
                        Expanded(child: _SkeletonLine(widthFactor: 0.4)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  const _SkeletonRectangle(height: 220),
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: _SkeletonLine(widthFactor: 0.9),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: _SkeletonLine(widthFactor: 0.7),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            );
          },
          childCount: 3,
        ),
      ),
    );
  }
}

class _SkeletonRectangle extends StatelessWidget {
  final double height;

  const _SkeletonRectangle({required this.height});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
      ),
    );
  }
}

class _SkeletonLine extends StatelessWidget {
  final double widthFactor;

  const _SkeletonLine({required this.widthFactor});

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      widthFactor: widthFactor,
      child: Container(
        height: 14,
        decoration: BoxDecoration(
          color: AppTheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
}

class _SkeletonCircle extends StatelessWidget {
  final double size;

  const _SkeletonCircle({required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLow,
        shape: BoxShape.circle,
      ),
    );
  }
}
