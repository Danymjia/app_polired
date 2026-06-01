import 'package:flutter/material.dart';
import '../config/theme.dart';

/// Responsabilidad principal:
/// Envoltorio global para `Image.network` que estandariza el manejo de estados (loading, fallos, URLs inválidas).
///
/// Flujo dentro de la app:
/// Componente hoja. Intercepta nulos o errores de red para prevenir fallos en la capa de renderizado y mostrar placeholders consistentes.
///
/// Dependencias críticas:
/// Ninguna. Componente puro puramente presentacional.
///
/// Side Effects:
/// Ninguno.
///
/// Recordatorios técnicos y CQRS:
/// - Oportunidad de Optimización: Internamente delega en `Image.network` nativo, el cual usa un caché efímero en RAM. Para escalar y soportar Offline-first, este widget debe migrarse a envolver `cached_network_image` persistiendo en SQLite/Disco local.
class SafeNetworkImage extends StatelessWidget {
  final String? url;
  final BoxFit fit;
  final double? width;
  final double? height;
  final Alignment alignment;
  final Widget? placeholder;
  final Widget? errorWidget;
  final BorderRadius? borderRadius;

  const SafeNetworkImage({
    super.key,
    required this.url,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.alignment = Alignment.center,
    this.placeholder,
    this.errorWidget,
    this.borderRadius,
  });

  bool get _hasUrl => url != null && url!.trim().isNotEmpty;

  Widget _defaultFallback() {
    return Container(
      width: width,
      height: height,
      color: AppTheme.surfaceContainerLow,
      alignment: Alignment.center,
      child: const Icon(
        Icons.broken_image_outlined,
        color: AppTheme.onSurfaceVariant,
        size: 28,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final fallback = errorWidget ?? placeholder ?? _defaultFallback();
    final widgetToRender = !_hasUrl
        ? fallback
        : Image.network(
            url!.trim(),
            width: width,
            height: height,
            fit: fit,
            alignment: alignment,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Container(
                width: width,
                height: height,
                color: AppTheme.surfaceContainerLow,
                alignment: Alignment.center,
                child: const CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppTheme.primary,
                ),
              );
            },
            errorBuilder: (context, error, stackTrace) => fallback,
          );

    if (borderRadius != null) {
      return ClipRRect(borderRadius: borderRadius!, child: widgetToRender);
    }
    return widgetToRender;
  }
}

/// Avatar circular a partir de una URL remota o iniciales.
class CircularNetworkAvatar extends StatelessWidget {
  final String? imageUrl;
  final String initials;
  final double size;
  final Color backgroundColor;
  final TextStyle? initialsStyle;

  const CircularNetworkAvatar({
    super.key,
    required this.imageUrl,
    required this.initials,
    this.size = 40,
    this.backgroundColor = AppTheme.surfaceContainerHighest,
    this.initialsStyle,
  });

  @override
  Widget build(BuildContext context) {
    final hasUrl = imageUrl != null && imageUrl!.trim().isNotEmpty;
    final content = hasUrl
        ? SafeNetworkImage(
            url: imageUrl,
            width: size,
            height: size,
            fit: BoxFit.cover,
            errorWidget: _buildPlaceholder(context),
          )
        : _buildPlaceholder(context);

    return ClipOval(
      child: Container(
        width: size,
        height: size,
        color: backgroundColor,
        child: content,
      ),
    );
  }

  Widget _buildPlaceholder(BuildContext context) {
    return Center(
      child: Text(
        initials.isNotEmpty ? initials[0].toUpperCase() : '?',
        style:
            initialsStyle ??
            Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }
}
