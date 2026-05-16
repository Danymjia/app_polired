import 'package:flutter/material.dart';
import '../../../config/theme.dart';

class ExploreEmptyState extends StatelessWidget {
  const ExploreEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(AppTheme.radiusXl),
              ),
              child: Icon(Icons.search_off, size: 54, color: AppTheme.onSurface.withOpacity(0.6)),
            ),
            const SizedBox(height: 24),
            Text(
              'No encontramos contenido nuevo aún',
              style: AppTheme.headlineMedium.copyWith(fontWeight: FontWeight.w800),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Revisa más tarde o cambia de categoría para descubrir publicaciones globales.',
              style: AppTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
