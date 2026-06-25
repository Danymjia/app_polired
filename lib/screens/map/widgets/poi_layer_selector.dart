import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/poi_model.dart';
import '../../../providers/map_provider.dart';

class PoiLayerSelector extends StatefulWidget {
  final void Function(PoiCategory)? onFilterApplied;
  const PoiLayerSelector({super.key, this.onFilterApplied});

  @override
  State<PoiLayerSelector> createState() => _PoiLayerSelectorState();
}

class _PoiLayerSelectorState extends State<PoiLayerSelector> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final activeCategory = context.watch<MapProvider>().activeCategory;
    final categories = PoiCategory.values;

    return Container(
      height: 48,
      alignment: Alignment.centerLeft,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        transitionBuilder: (Widget child, Animation<double> animation) {
          return FadeTransition(
            opacity: animation,
            child: SizeTransition(
              sizeFactor: animation,
              axis: Axis.horizontal,
              axisAlignment: -1.0,
              child: child,
            ),
          );
        },
        child: _isExpanded
            ? ListView.separated(
                key: const ValueKey('expanded'),
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: categories.length + 1,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return _buildFilterButton(
                      icon: Icons.close_rounded,
                      label: "Cerrar",
                      isSelected: false,
                      onTap: () {
                        context.read<MapProvider>().setActiveCategory(null);
                        context.read<MapProvider>().clearSelection();
                        setState(() => _isExpanded = false);
                      },
                    );
                  }
                  
                  final category = categories[index - 1];
                  final isSelected = activeCategory == category;

                  return _buildFilterButton(
                    icon: category.iconData,
                    label: category.label,
                    isSelected: isSelected,
                    onTap: () {
                      if (isSelected) {
                        context.read<MapProvider>().setActiveCategory(null);
                      } else {
                        context.read<MapProvider>().setActiveCategory(category);
                        widget.onFilterApplied?.call(category);
                      }
                      context.read<MapProvider>().clearSelection();
                    },
                  );
                },
              )
            : Padding(
                key: const ValueKey('collapsed'),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _buildFilterButton(
                  icon: Icons.filter_list_rounded,
                  label: activeCategory != null ? activeCategory.label : "Filtros",
                  isSelected: activeCategory != null,
                  onTap: () => setState(() => _isExpanded = true),
                ),
              ),
      ),
    );
  }

  Widget _buildFilterButton({
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Material(
      color: isSelected ? const Color(0xFF1D3557) : Colors.white,
      borderRadius: BorderRadius.circular(24),
      elevation: isSelected ? 4 : 2,
      shadowColor: Colors.black.withValues(alpha: 0.1),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 20,
                color: isSelected ? Colors.white : const Color(0xFF1D3557),
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : const Color(0xFF1D3557),
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
