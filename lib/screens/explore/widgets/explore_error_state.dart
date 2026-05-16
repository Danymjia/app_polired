import 'package:flutter/material.dart';
import '../../../config/theme.dart';

class ExploreErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const ExploreErrorState({super.key, required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              decoration: BoxDecoration(
                color: AppTheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(AppTheme.radiusXl),
              ),
              padding: const EdgeInsets.all(24),
              child: Icon(Icons.wifi_off, size: 56, color: AppTheme.error),
            ),
            const SizedBox(height: 20),
            Text(
              'Algo salió mal',
              style: AppTheme.headlineMedium.copyWith(fontWeight: FontWeight.w800),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              message,
              style: AppTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 22),
            ElevatedButton(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                ),
              ),
              child: Text('Reintentar', style: AppTheme.bodyLarge.copyWith(color: AppTheme.onPrimary)),
            ),
          ],
        ),
      ),
    );
  }
}
