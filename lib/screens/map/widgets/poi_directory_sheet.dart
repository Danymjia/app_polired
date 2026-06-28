import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/map_provider.dart';
import '../../../models/poi_model.dart';

/// Responsabilidad principal:
/// Directorio navegable de todos los POIs del campus agrupados por categorías.
///
/// Flujo dentro de la app:
/// Accesible desde un botón flotante en `MapScreen`. Permite explorar lugares si no se sabe el nombre exacto.
///
/// Dependencias críticas:
/// - `MapProvider` (para obtener la lista de POIs agrupados por categoría).
///
/// Side Effects:
/// - Dispara `onPoiSelected` cuando el usuario elige un lugar.
///
/// Recordatorios técnicos y CQRS:
/// - Implementa navegación en dos niveles (Nivel 1: Categorías, Nivel 2: Lista de lugares) manteniendo el estado internamente sin afectar el provider global.
class PoiDirectorySheet extends StatefulWidget {
  final PoiCategory? initialCategory;
  final VoidCallback onClose;
  final void Function(PoiModel poi) onPoiSelected;

  const PoiDirectorySheet({
    super.key,
    this.initialCategory,
    required this.onClose,
    required this.onPoiSelected,
  });

  @override
  State<PoiDirectorySheet> createState() => _PoiDirectorySheetState();
}

class _PoiDirectorySheetState extends State<PoiDirectorySheet> {
  PoiCategory? _selectedCategory;

  @override
  void initState() {
    super.initState();
    if (widget.initialCategory != null) {
      _selectedCategory = widget.initialCategory;
    }
  }

  IconData _getCategoryIcon(PoiCategory cat) {
    switch (cat) {
      case PoiCategory.academic: return Icons.school_rounded;
      case PoiCategory.services: return Icons.room_service_rounded;
      case PoiCategory.sports: return Icons.sports_soccer_rounded;
      case PoiCategory.other: 
        return Icons.place_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onClose,
      child: Container(
        color: Colors.black.withValues(alpha: 0.3),
        child: GestureDetector(
          onTap: () {}, // evitar que el tap interior cierre
          child: NotificationListener<DraggableScrollableNotification>(
            onNotification: (notification) {
              if (notification.extent <= 0.05) {
                widget.onClose();
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
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: Column(
                  children: [
                    // Handle
                    Center(
                      child: Container(
                        margin: const EdgeInsets.only(top: 10, bottom: 6),
                        width: 36,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
  
                    Expanded(
                      child: _selectedCategory == null
                          ? _buildLevel1(scrollController)
                          : _buildLevel2(context, scrollController),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    ),
  );
}

  Widget _buildLevel1(ScrollController controller) {
    final categories = [
      PoiCategory.academic,
      PoiCategory.services,
      PoiCategory.sports,
      PoiCategory.other,
    ];

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
          child: Row(
            children: [
              const SizedBox(width: 48), // Balance for right button
              const Expanded(
                child: Text('Directorio EPN',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1D3557))),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded, size: 20),
                onPressed: widget.onClose,
              ),
            ],
          ),
        ),
        Expanded(
          child: GridView.builder(
            controller: controller,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.1,
              ),
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final cat = categories[index];
                return InkWell(
                  onTap: () => setState(() => _selectedCategory = cat),
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F5F5),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _getCategoryIcon(cat),
                          size: 48,
                          color: const Color(0xFF1D3557),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          cat.label,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1D3557),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      );
  }

  Widget _buildLevel2(BuildContext context, ScrollController controller) {
    final mapProvider = context.watch<MapProvider>();
    final pois = mapProvider.poiByCategory[_selectedCategory] ?? [];

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 0, 16, 8),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF1D3557)),
                onPressed: () => setState(() => _selectedCategory = null),
              ),
              Expanded(
                child: Text(
                  _selectedCategory!.label,
                  style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1D3557)),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(width: 48), // balance back button
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            controller: controller,
            padding: const EdgeInsets.only(bottom: 24),
              itemCount: pois.length,
              itemBuilder: (context, index) {
                final poi = pois[index];
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                  leading: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1D3557).withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(_getCategoryIcon(_selectedCategory!),
                        color: const Color(0xFF1D3557), size: 20),
                  ),
                  title: Text(poi.name,
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w600)),
                  subtitle: Text(poi.shortDescription,
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
                  onTap: () {
                    widget.onPoiSelected(poi);
                  },
                );
              },
            ),
          ),
        ],
      );
  }
}
