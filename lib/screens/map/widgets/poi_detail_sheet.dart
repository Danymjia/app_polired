import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/poi_model.dart';
import '../../../providers/map_provider.dart';

/// Responsabilidad principal:
/// Bottom sheet que muestra el detalle de un Punto de Interés (POI) seleccionado en el mapa (fotos, horarios, cómo llegar).
///
/// Flujo dentro de la app:
/// Se despliega sobre el mapa (`MapScreen`) cuando el usuario toca un marcador o selecciona un resultado de búsqueda.
///
/// Dependencias críticas:
/// - `PoiModel` (Modelo de datos puro inyectado por parámetro).
///
/// Side Effects:
/// - Ninguno internamente; expone callbacks para cierre (`onClose`) o volver al directorio (`onOpenDirectory`).
///
/// Recordatorios técnicos y CQRS:
/// - Usa `DraggableScrollableSheet` para permitir arrastrar hacia arriba/abajo y ver el contenido completo de manera nativa.
class PoiDetailSheet extends StatelessWidget {
  final PoiModel poi;
  final VoidCallback onClose;
  final void Function(PoiCategory)? onOpenDirectory;
  final VoidCallback? onStartRouting;

  const PoiDetailSheet({
    super.key, 
    required this.poi, 
    required this.onClose,
    this.onOpenDirectory,
    this.onStartRouting,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) => Transform.translate(
        offset: Offset(0, 40 * (1 - value)),
        child: Opacity(opacity: value, child: child),
      ),
      child: NotificationListener<DraggableScrollableNotification>(
        onNotification: (notification) {
          if (notification.extent <= 0.05) {
            onClose();
          }
          return false;
        },
        child: DraggableScrollableSheet(
          initialChildSize: 0.5,
          minChildSize: 0.0,
          maxChildSize: 0.5,
          snap: true,
          snapSizes: const [0.5],
          builder: (context, scrollController) {
            return Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 20,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  if (constraints.maxHeight < 60) return const SizedBox.shrink();
                  return Column(
                children: [
                  // Indicador de drag
                  Center(
                    child: Container(
                      margin: const EdgeInsets.only(top: 10),
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),

                  // Top Bar (Cerrar / Regresar)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 8, 16, 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextButton.icon(
                          onPressed: () {
                            if (onOpenDirectory != null) {
                              onOpenDirectory!(poi.category);
                            } else {
                              onClose();
                            }
                          },
                          icon: const Icon(Icons.arrow_back, size: 18),
                          label: const Text('Directorio', style: TextStyle(fontWeight: FontWeight.w600)),
                          style: TextButton.styleFrom(
                            foregroundColor: const Color(0xFF1D3557),
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            minimumSize: Size.zero,
                          ),
                        ),
                        IconButton(
                          onPressed: onClose,
                          icon: const Icon(Icons.close_rounded),
                          color: Colors.grey.shade600,
                          padding: const EdgeInsets.all(4),
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                  ),

                  Expanded(
                    child: SingleChildScrollView(
                      controller: scrollController,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Galería de fotos
                          if (poi.photoAssets.isNotEmpty)
                            _PoiImageCarousel(
                              photoAssets: poi.photoAssets,
                              buildingNumber: poi.buildingNumber,
                              category: poi.category,
                            )
                          else
                            const SizedBox(height: 8),

                          Padding(
                            padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Header
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(poi.name,
                                        style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w700,
                                            color: Color(0xFF1D3557))),
                                    const SizedBox(height: 4),
                                    Text(poi.shortDescription,
                                        style: TextStyle(
                                            fontSize: 13,
                                            color: Colors.grey.shade600,
                                            height: 1.4)),
                                    const SizedBox(height: 12),
                                    ElevatedButton.icon(
                                      onPressed: () {
                                        if (onStartRouting != null) {
                                          onStartRouting!();
                                        } else {
                                          context.read<MapProvider>().startRoutingFromPoi(poi);
                                        }
                                      },
                                      icon: const Icon(Icons.directions_walk_rounded),
                                      label: const Text('Ir a este lugar'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFFE63946),
                                        foregroundColor: Colors.white,
                                        elevation: 0,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 20),

                                // Horarios
                                _SectionTitle(icon: Icons.schedule_rounded, label: 'Horarios'),
                                const SizedBox(height: 8),
                                ...poi.schedule.map((s) => Padding(
                                      padding: const EdgeInsets.only(bottom: 4),
                                      child: Text(s,
                                          style: const TextStyle(
                                              fontSize: 13, height: 1.5)),
                                    )),

                                const SizedBox(height: 16),

                                // Cómo llegar
                                _SectionTitle(
                                    icon: Icons.directions_walk_rounded,
                                    label: 'Cómo llegar'),
                                const SizedBox(height: 8),
                                Text(poi.howToGet,
                                    style: const TextStyle(fontSize: 13, height: 1.6)),

                                // Edificio y piso
                                if (poi.building != null || poi.floor != null) ...[
                                  const SizedBox(height: 16),
                                  _SectionTitle(
                                      icon: Icons.apartment_rounded, label: 'Ubicación'),
                                  const SizedBox(height: 8),
                                  if (poi.building != null)
                                    Text('Edificio: ${poi.building}',
                                        style: const TextStyle(fontSize: 13)),
                                  if (poi.floor != null)
                                    Text('Piso: ${poi.floor}',
                                        style: const TextStyle(fontSize: 13)),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            }, // Cierre del LayoutBuilder
          ),
        );
      }, // Cierre del builder de DraggableScrollableSheet
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final IconData icon;
  final String label;
  const _SectionTitle({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: const Color(0xFF1D3557)),
        const SizedBox(width: 6),
        Text(label,
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1D3557))),
      ],
    );
  }
}

class _PoiImageCarousel extends StatefulWidget {
  final List<String> photoAssets;
  final String? buildingNumber;
  final PoiCategory category;

  const _PoiImageCarousel({required this.photoAssets, this.buildingNumber, required this.category});

  @override
  State<_PoiImageCarousel> createState() => _PoiImageCarouselState();
}

class _PoiImageCarouselState extends State<_PoiImageCarousel> {
  late final PageController _pageController;
  int _currentImageIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(keepPage: false);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _openFullScreenImage(BuildContext context, String imagePath) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.9),
      builder: (context) => Stack(
        children: [
          Positioned.fill(
            child: InteractiveViewer(
              minScale: 1.0,
              maxScale: 5.0,
              child: Center(
                child: Image.asset(imagePath, fit: BoxFit.contain),
              ),
            ),
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            right: 16,
            child: Material(
              color: Colors.transparent,
              child: IconButton(
                icon: const Icon(Icons.close_rounded, color: Colors.white, size: 32),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AspectRatio(
          aspectRatio: 16 / 9,
          child: Stack(
            children: [
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                  child: Container(
                    color: Colors.black87,
                    child: PageView.builder(
                      controller: _pageController,
                      itemCount: widget.photoAssets.length,
                      onPageChanged: (index) {
                        setState(() {
                          _currentImageIndex = index;
                        });
                      },
                      itemBuilder: (_, index) => GestureDetector(
                        onTap: () => _openFullScreenImage(context, widget.photoAssets[index]),
                        child: Image.asset(
                          widget.photoAssets[index],
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => Container(
                            color: const Color(0xFF1D3557).withValues(alpha: 0.08),
                            child: const Icon(Icons.image_not_supported_rounded, color: Colors.grey),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              if (widget.buildingNumber != null)
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE63946),
                      borderRadius: BorderRadius.circular(4),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.3),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      'Edificio ${widget.buildingNumber!}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              Positioned(
                bottom: 12,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(widget.category.iconData, size: 14, color: const Color(0xFF1D3557)),
                      const SizedBox(width: 4),
                      Text(widget.category.label,
                          style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1D3557))),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        if (widget.photoAssets.length > 1) ...[
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(widget.photoAssets.length, (index) {
              return AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: _currentImageIndex == index ? 8 : 6,
                height: _currentImageIndex == index ? 8 : 6,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _currentImageIndex == index
                      ? const Color(0xFF1D3557)
                      : const Color(0xFF1D3557).withValues(alpha: 0.3),
                ),
              );
            }),
          ),
        ],
      ],
    );
  }
}
