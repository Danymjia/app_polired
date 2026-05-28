import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/map_provider.dart';
import '../../../models/poi_model.dart';

class PoiDirectorySheet extends StatelessWidget {
  final VoidCallback onClose;
  final void Function(PoiModel poi) onPoiSelected;

  const PoiDirectorySheet({
    super.key,
    required this.onClose,
    required this.onPoiSelected,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onClose,
      child: Container(
        color: Colors.black.withValues(alpha: 0.3),
        child: GestureDetector(
          onTap: () {}, // evitar que el tap interior cierre
          child: DraggableScrollableSheet(
            initialChildSize: 0.55,
            minChildSize: 0.3,
            maxChildSize: 0.92,
            builder: (context, scrollController) {
              final mapProvider = context.watch<MapProvider>();
              final byCategory = mapProvider.poiByCategory;

              return Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius:
                      BorderRadius.vertical(top: Radius.circular(24)),
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

                    // Título
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                      child: Row(
                        children: [
                          const Text('Directorio del campus',
                              style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF1D3557))),
                          const Spacer(),
                          IconButton(
                            icon: const Icon(Icons.close_rounded, size: 20),
                            onPressed: onClose,
                          ),
                        ],
                      ),
                    ),

                    // Lista por categorías
                    Expanded(
                      child: ListView(
                        controller: scrollController,
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                        children: byCategory.entries.map((entry) {
                          return _CategorySection(
                            category: entry.key,
                            pois: entry.value,
                            onPoiTap: (poi) {
                              onPoiSelected(poi);
                              context.read<MapProvider>().selectPoi(poi);
                              onClose();
                            },
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _CategorySection extends StatefulWidget {
  final PoiCategory category;
  final List<PoiModel> pois;
  final void Function(PoiModel) onPoiTap;

  const _CategorySection({
    required this.category,
    required this.pois,
    required this.onPoiTap,
  });

  @override
  State<_CategorySection> createState() => _CategorySectionState();
}

class _CategorySectionState extends State<_CategorySection> {
  bool _expanded = true;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header de categoría (colapsable)
        InkWell(
          onTap: () => setState(() => _expanded = !_expanded),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1D3557),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.place_rounded,
                      color: Colors.white, size: 16),
                ),
                const SizedBox(width: 10),
                Text(widget.category.label,
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1D3557))),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1D3557).withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text('${widget.pois.length}',
                      style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1D3557))),
                ),
                const Spacer(),
                Icon(
                    _expanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: Colors.grey.shade400),
              ],
            ),
          ),
        ),

        // Lista de POIs de la categoría
        AnimatedCrossFade(
          firstChild: Column(
            children: widget.pois
                .map((poi) => _PoiListTile(
                      poi: poi,
                      onTap: () => widget.onPoiTap(poi),
                    ))
                .toList(),
          ),
          secondChild: const SizedBox.shrink(),
          crossFadeState: _expanded
              ? CrossFadeState.showFirst
              : CrossFadeState.showSecond,
          duration: const Duration(milliseconds: 200),
        ),

        Divider(height: 1, color: Colors.grey.shade100),
        const SizedBox(height: 8),
      ],
    );
  }
}

class _PoiListTile extends StatelessWidget {
  final PoiModel poi;
  final VoidCallback onTap;

  const _PoiListTile({required this.poi, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      leading: poi.photoAssets.isNotEmpty
          ? ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(
                poi.photoAssets.first,
                width: 44,
                height: 44,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => _placeholderIcon(),
              ),
            )
          : _placeholderIcon(),
      title: Text(poi.name,
          style: const TextStyle(
              fontSize: 13, fontWeight: FontWeight.w600)),
      subtitle: poi.building != null
          ? Text(poi.building!,
              style: TextStyle(fontSize: 11, color: Colors.grey.shade500))
          : null,
      trailing: const Icon(Icons.chevron_right_rounded,
          color: Colors.grey, size: 18),
      onTap: onTap,
    );
  }

  Widget _placeholderIcon() {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: const Color(0xFF1D3557).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(Icons.place_rounded,
          color: Color(0xFF1D3557), size: 20),
    );
  }
}
