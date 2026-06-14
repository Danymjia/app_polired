import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/// Responsabilidad principal:
/// Visor de imágenes en pantalla completa con soporte para múltiples imágenes (carrusel), zoom (`InteractiveViewer`), y carga asíncrona.
///
/// Flujo dentro de la app:
/// Utilizado cuando un usuario toca una imagen en un Post o en un Perfil (Avatar).
///
/// Dependencias críticas:
/// - `cached_network_image`.
///
/// Side Effects:
/// - Intercepta eventos de gestos (Pinch-to-zoom, Swipe).
/// - Navegación: Añade una ruta opaca sobre el stack actual.
///
/// Recordatorios técnicos y CQRS:
/// - Las imágenes pueden requerir mucha RAM. `cached_network_image` maneja esto, pero evitar carruseles masivos (>50 imágenes).
class FullscreenImageViewer extends StatefulWidget {
  final List<String> imageUrls;
  final int initialIndex;
  final bool isCircular;

  const FullscreenImageViewer({
    required this.imageUrls,
    this.initialIndex = 0,
    this.isCircular = false,
    super.key,
  });

  static Future<void> show(
    BuildContext context,
    List<String> urls, {
    int initialIndex = 0,
    bool isCircular = false,
  }) {
    return Navigator.push(
      context,
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black,
        pageBuilder: (context, animation, secondaryAnimation) => FullscreenImageViewer(
          imageUrls: urls,
          initialIndex: initialIndex,
          isCircular: isCircular,
        ),
      ),
    );
  }

  @override
  State<FullscreenImageViewer> createState() => _FullscreenImageViewerState();
}

class _FullscreenImageViewerState extends State<FullscreenImageViewer> {
  late final PageController _controller;
  int _current = 0;

  @override
  void initState() {
    super.initState();
    _current = widget.initialIndex;
    _controller = PageController(initialPage: widget.initialIndex);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          PageView.builder(
            controller: _controller,
            itemCount: widget.imageUrls.length,
            onPageChanged: (i) => setState(() => _current = i),
            itemBuilder: (context, index) {
              Widget imageWidget = CachedNetworkImage(
                imageUrl: widget.imageUrls[index],
                fit: BoxFit.cover,
                placeholder: (context, url) => const CircularProgressIndicator(
                  color: Colors.white,
                ),
                errorWidget: (context, url, error) => const Icon(
                  Icons.broken_image_outlined,
                  color: Colors.white54,
                  size: 48,
                ),
              );

              if (widget.isCircular) {
                // Determine a fixed size for the circle, e.g. width of screen minus some margin
                final size = MediaQuery.of(context).size.width - 32;
                imageWidget = SizedBox(
                  width: size,
                  height: size,
                  child: ClipOval(
                    child: imageWidget,
                  ),
                );
              }

              return InteractiveViewer(
                minScale: 0.8,
                maxScale: 4.0,
                child: Center(
                  child: imageWidget,
                ),
              );
            },
          ),
          Positioned(
            top: 48,
            left: 16,
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.15),
              ),
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ),
          if (widget.imageUrls.length > 1)
            Positioned(
              top: 48,
              right: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  '${_current + 1} / ${widget.imageUrls.length}',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
