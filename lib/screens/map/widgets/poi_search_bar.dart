import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/map_provider.dart';
import '../../../models/poi_model.dart';

class PoiSearchBar extends StatefulWidget {
  final Future<void> Function(PoiModel poi)? onPoiSelected;
  final VoidCallback? onSearchTap;

  const PoiSearchBar({super.key, this.onPoiSelected, this.onSearchTap});

  @override
  State<PoiSearchBar> createState() => _PoiSearchBarState();
}

class _PoiSearchBarState extends State<PoiSearchBar> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      if (_focusNode.hasFocus) {
        widget.onSearchTap?.call();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Campo de búsqueda
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              const SizedBox(width: 16),
              Icon(Icons.search_rounded,
                  color: Colors.grey.shade500, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  onChanged: (v) {
                    context.read<MapProvider>().updateSearch(v);
                    setState(() => _isExpanded = v.isNotEmpty);
                  },
                  decoration: const InputDecoration(
                    hintText: 'Buscar lugar en el campus...',
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 14),
                    hintStyle: TextStyle(fontSize: 14),
                  ),
                  style: const TextStyle(fontSize: 14),
                ),
              ),
              if (_isExpanded)
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 18),
                  color: Colors.grey.shade500,
                  onPressed: () {
                    _controller.clear();
                    _focusNode.unfocus();
                    context.read<MapProvider>().clearSearch();
                    setState(() => _isExpanded = false);
                  },
                )
              else
                const SizedBox(width: 16),
            ],
          ),
        ),

        // Resultados en tiempo real
        if (_isExpanded)
          Consumer<MapProvider>(
            builder: (context, mapProvider, _) {
              final results = mapProvider.searchResults;
              if (results.isEmpty) {
                return _buildNoResults();
              }
              return _buildResults(results);
            },
          ),
      ],
    );
  }

  Widget _buildResults(List<PoiModel> results) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 300),
          child: ListView.separated(
            shrinkWrap: true,
            padding: EdgeInsets.zero,
            itemCount: results.length,
            separatorBuilder: (_, _) => Divider(
            height: 1,
            color: Colors.grey.shade100,
          ),
          itemBuilder: (context, index) {
            final poi = results[index];
            return ListTile(
              dense: true,
              leading: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFF1D3557),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.place_rounded,
                    color: Colors.white, size: 18),
              ),
              title: Text(poi.name,
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600)),
              subtitle: Text(poi.category.label,
                  style: TextStyle(
                      fontSize: 11, color: Colors.grey.shade500)),
              onTap: () async {
                context.read<MapProvider>().selectPoi(poi);
                _controller.clear();
                _focusNode.unfocus();
                context.read<MapProvider>().clearSearch();
                setState(() => _isExpanded = false);
                await widget.onPoiSelected?.call(poi);
              },
            );
          },
        ),
        ),
      ),
    );
  }

  Widget _buildNoResults() {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: const Text(
        'Sin resultados para esa búsqueda.',
        textAlign: TextAlign.center,
        style: TextStyle(color: Colors.grey, fontSize: 13),
      ),
    );
  }
}
