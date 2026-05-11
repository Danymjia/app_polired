import 'package:flutter/material.dart';
import '../config/theme.dart';

/// Logo de Polired: usa la imagen assets/images/logo_v5.2.png.
/// Parámetros:
///   [size]       — diámetro del contenedor circular
///   [showText]   — si mostrar el texto "Polired" debajo
///   [shape]      — BoxShape.circle (default) o usar borderRadius
///   [borderRadius] — si se quiere esquina redondeada rectangular (forgot password)
class PoliredLogo extends StatelessWidget {
  final double size;
  final bool showText;
  final bool useRoundedRect;

  const PoliredLogo({
    super.key,
    this.size = 80,
    this.showText = false,
    this.useRoundedRect = false,
  });

  @override
  Widget build(BuildContext context) {
    final Widget imageContainer = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainer,
        shape: useRoundedRect ? BoxShape.rectangle : BoxShape.circle,
        borderRadius: useRoundedRect
            ? BorderRadius.circular(size * 0.2)
            : null,
        border: Border.all(color: AppTheme.surfaceContainerHighest),
      ),
      clipBehavior: Clip.antiAlias,
      child: Image.asset(
        'assets/images/logo_v5.2.png',
        fit: BoxFit.cover,
        // Mientras el usuario no haya puesto el logo, muestra un fallback
        errorBuilder: (ctx, err, stack) => Icon(
          Icons.hub_outlined,
          size: size * 0.45,
          color: AppTheme.primary,
        ),
      ),
    );

    if (!showText) return imageContainer;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        imageContainer,
        const SizedBox(height: 12),
        Text(
          'Polired',
          style: AppTheme.displayLarge.copyWith(
            color: AppTheme.primary,
            fontSize: size * 0.38,
          ),
        ),
      ],
    );
  }
}
