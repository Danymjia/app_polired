import 'package:flutter/material.dart';
import '../models/map_view_mode.dart';

class MapViewToggleButton extends StatefulWidget {
  final MapViewMode currentMode;
  final ValueChanged<MapViewMode> onModeSelected;

  const MapViewToggleButton({
    super.key,
    required this.currentMode,
    required this.onModeSelected,
  });

  @override
  State<MapViewToggleButton> createState() => _MapViewToggleButtonState();
}

class _MapViewToggleButtonState extends State<MapViewToggleButton> {
  bool _isOpen = false;

  void _toggleMenu() {
    setState(() {
      _isOpen = !_isOpen;
    });
  }

  void _closeMenu() {
    if (_isOpen) {
      setState(() {
        _isOpen = false;
      });
    }
  }

  Widget _buildModeButton(MapViewMode mode, IconData icon) {
    final isActive = widget.currentMode == mode;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: FloatingActionButton(
        heroTag: 'map_view_mode_${mode.name}',
        mini: true,
        backgroundColor: isActive ? const Color(0xFF1D3557) : Colors.white,
        foregroundColor: isActive ? Colors.white : Colors.grey.shade600,
        elevation: isActive ? 4 : 2,
        onPressed: () {
          widget.onModeSelected(mode);
          _closeMenu();
        },
        child: Icon(icon, size: 20),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return TapRegion(
      onTapOutside: (_) => _closeMenu(),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          AnimatedOpacity(
            opacity: _isOpen ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 200),
            child: AnimatedSize(
              duration: const Duration(milliseconds: 200),
              alignment: Alignment.bottomCenter,
              child: _isOpen
                  ? Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildModeButton(MapViewMode.satelite, Icons.satellite_alt_outlined),
                        _buildModeButton(MapViewMode.lineal, Icons.timeline_outlined),
                        _buildModeButton(MapViewMode.normal, Icons.layers_outlined),
                        const SizedBox(height: 8),
                      ],
                    )
                  : const SizedBox.shrink(),
            ),
          ),
          FloatingActionButton(
            heroTag: 'map_view_toggle',
            mini: true,
            backgroundColor: Colors.white,
            foregroundColor: const Color(0xFF1D3557),
            onPressed: _toggleMenu,
            child: const Icon(Icons.view_in_ar_outlined),
          ),
        ],
      ),
    );
  }
}
