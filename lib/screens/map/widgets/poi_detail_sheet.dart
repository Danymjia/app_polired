import 'package:flutter/material.dart';
import '../../../models/poi_model.dart';

class PoiDetailSheet extends StatelessWidget {
  final PoiModel poi;
  final VoidCallback onClose;

  const PoiDetailSheet({super.key, required this.poi, required this.onClose});

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
      child: Container(
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
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

            // Galería de fotos
            if (poi.photoAssets.isNotEmpty)
              SizedBox(
                height: 160,
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(20)),
                  child: PageView.builder(
                    itemCount: poi.photoAssets.length,
                    itemBuilder: (_, index) => Image.asset(
                      poi.photoAssets[index],
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => Container(
                        color: const Color(0xFF1D3557).withValues(alpha: 0.08),
                        child: const Icon(Icons.image_not_supported_rounded,
                            color: Colors.grey),
                      ),
                    ),
                  ),
                ),
              )
            else
              const SizedBox(height: 8),

            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
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
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Badge categoría
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1D3557).withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(poi.category.label,
                            style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1D3557))),
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

            // Botón cerrar
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: onClose,
                  child: const Text('Cerrar'),
                ),
              ),
            ),
          ],
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
