import 'package:flutter/material.dart';
import '../../../../config/theme.dart';

class RestrictedFeedOverlay extends StatelessWidget {
  final Widget child;
  final VoidCallback onJoinPressed;

  const RestrictedFeedOverlay({
    super.key,
    required this.child,
    required this.onJoinPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // The partially blocked post
        child,
        
        // Gradient Overlay
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppTheme.surface.withValues(alpha: 0.0),
                  AppTheme.surface.withValues(alpha: 0.8),
                  AppTheme.surface.withValues(alpha: 1.0),
                ],
                stops: const [0.0, 0.5, 1.0],
              ),
            ),
          ),
        ),
        
        // Message and Join Button
        Positioned(
          bottom: 40,
          left: 0,
          right: 0,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Text(
                  'Únete a esta red para seguir viendo su contenido',
                  textAlign: TextAlign.center,
                  style: AppTheme.headlineMedium.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: onJoinPressed,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF001B3C),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Unirse',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
