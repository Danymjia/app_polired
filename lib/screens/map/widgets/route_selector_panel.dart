import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/map_provider.dart';
import '../../../models/poi_model.dart';
import '../../../services/poi_data.dart';
import 'poi_search_bar.dart';

class RouteSelectorPanel extends StatefulWidget {
  final VoidCallback onClose;
  final Function(PoiModel start, PoiModel end) onRouteRequested;

  const RouteSelectorPanel({
    super.key,
    required this.onClose,
    required this.onRouteRequested,
  });

  @override
  State<RouteSelectorPanel> createState() => _RouteSelectorPanelState();
}

class _RouteSelectorPanelState extends State<RouteSelectorPanel> {
  PoiModel? _start;
  PoiModel? _end;

  @override
  void initState() {
    super.initState();
    final mapProvider = context.read<MapProvider>();
    _start = mapProvider.routeStart;
    _end = mapProvider.routeEnd;
  }

  void _showSearchSheet(BuildContext context, bool isStart) {
    String searchQuery = '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setStateSheet) {
            final filteredPois = PoiData.all.where((poi) {
              if (searchQuery.isEmpty) return true;
              return poi.matchesQuery(searchQuery);
            }).toList();

            return Container(
              height: MediaQuery.of(context).size.height * 0.7,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      isStart ? 'Selecciona Origen' : 'Selecciona Destino',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1D3557)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: TextField(
                      autofocus: true,
                      onChanged: (value) {
                        setStateSheet(() {
                          searchQuery = value;
                        });
                      },
                      decoration: InputDecoration(
                        hintText: 'Buscar por nombre o sigla (ej. FIEE)...',
                        prefixIcon: const Icon(Icons.search, color: Colors.grey),
                        filled: true,
                        fillColor: Colors.grey[100],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: filteredPois.isEmpty
                        ? const Center(
                            child: Text(
                              'No se encontraron coincidencias.',
                              style: TextStyle(color: Colors.grey, fontSize: 16),
                            ),
                          )
                        : ListView.builder(
                            itemCount: filteredPois.length,
                            itemBuilder: (context, index) {
                              final poi = filteredPois[index];
                              return ListTile(
                                leading: Icon(poi.category.iconData, color: const Color(0xFFE63946)),
                                title: Text(poi.name),
                                subtitle: Text(poi.shortDescription),
                                onTap: () {
                                  setState(() {
                                    if (isStart) {
                                      _start = poi;
                                    } else {
                                      _end = poi;
                                    }
                                  });
                                  Navigator.pop(context);
                                  _checkRoute();
                                },
                              );
                            },
                          ),
                  )
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _checkRoute() {
    if (_start != null && _end != null && _start!.id != _end!.id) {
      widget.onRouteRequested(_start!, _end!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    _buildSelectorField('Desde', _start?.name ?? 'Elegir punto de partida...', () => _showSearchSheet(context, true)),
                    const SizedBox(height: 8),
                    _buildSelectorField('Hasta', _end?.name ?? 'Elegir destino...', () => _showSearchSheet(context, false)),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                children: [
                  IconButton(
                    icon: const Icon(Icons.swap_vert, color: Color(0xFF457B9D)),
                    onPressed: () {
                      setState(() {
                        final temp = _start;
                        _start = _end;
                        _end = temp;
                      });
                      _checkRoute();
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.grey),
                    onPressed: widget.onClose,
                  ),
                ],
              )
            ],
          )
        ],
      ),
    );
  }

  Widget _buildSelectorField(String label, String value, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 50,
              child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF1D3557))),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                value,
                style: TextStyle(
                  color: value.contains('Elegir') ? Colors.grey : Colors.black87,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
