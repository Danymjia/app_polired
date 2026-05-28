import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:provider/provider.dart';
import '../../providers/map_provider.dart';
import '../../models/poi_model.dart';
import '../../services/poi_data.dart';
import 'utils/marker_image_util.dart';
import 'widgets/poi_search_bar.dart';
import 'widgets/poi_detail_sheet.dart';
import 'widgets/poi_directory_sheet.dart';

// Centro del campus EPN
final _campusCenter = Point(coordinates: Position(-78.4891, -0.2107));
final _campusBounds = CoordinateBounds(
  // Esquinas aproximadas para no salir del campus
  southwest: Point(coordinates: Position(-78.4920, -0.2135)),
  northeast: Point(coordinates: Position(-78.4860, -0.2080)),
  infiniteBounds: false,
);

// ESTILOS DISPONIBLES
// Usar 'standard' mientras no tienes el estilo de Studio listo
// Cuando publiques en Studio, reemplaza _mapStyle con la URL de tu estilo
class _MapStyles {
  // Tu estilo personalizado (reemplazar cuando esté publicado en Studio)
  static const campus = 'mapbox://styles/dany404/cmplst9ax000z01qvhgtxeu8r';

  // El activo
  static const active = campus; // cambiar a campus cuando esté listo
}

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  MapboxMap? _mapboxMap;
  PointAnnotationManager? _annotationManager;
  bool _directoryOpen = false;

  final Map<String, String> _annotationIdToPoiId = {};
  final Map<String, PointAnnotation> _annotations = {};
  bool _labelsVisible = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // MAPA BASE
          MapWidget(
            styleUri: _MapStyles.active,
            viewport: CameraViewportState(
              center: _campusCenter,
              zoom: 17.5,
              pitch: 50.0,       // Vista 3D isométrica
              bearing: 0.0,      // Norte arriba (ajustar según campus)
            ),
            onMapCreated: _onMapCreated,
            onStyleLoadedListener: (_) => _loadMarkers(),
            onCameraChangeListener: (CameraChangedEventData event) {
              if (!mounted) return;
              final zoom = event.cameraState.zoom;
              context.read<MapProvider>().onZoomChanged(zoom);
              _syncLabelVisibility(zoom);
            },
          ),

          // BARRA DE BÚSQUEDA SUPERIOR
          Positioned(
            top: MediaQuery.of(context).padding.top + 12,
            left: 16,
            right: 16,
            child: PoiSearchBar(
              onPoiSelected: (poi) async {
                await _flyToPoi(poi);
              },
            ),
          ),

          // BOTÓN DIRECTORIO (abajo izquierda)
          Positioned(
            bottom: 100,
            left: 16,
            child: _buildDirectoryButton(),
          ),

          // BOTÓN RESET CÁMARA (abajo derecha)
          Positioned(
            bottom: 100,
            right: 16,
            child: _buildResetButton(),
          ),

          // PANEL INFERIOR: Detalle de POI seleccionado
          Consumer<MapProvider>(
            builder: (context, mapProvider, _) {
              final poi = mapProvider.selectedPoi;
              if (poi == null) return const SizedBox.shrink();
              return Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: PoiDetailSheet(
                  poi: poi,
                  onClose: () async {
                    final previousId = poi.id;
                    mapProvider.clearSelection();
                    await _updateMarkerSelection(previousId, null);
                    // Volver a vista general
                    await _mapboxMap?.flyTo(
                      CameraOptions(
                        center: _campusCenter,
                        zoom: 17.0,
                        pitch: 50.0,
                        bearing: 0.0,
                      ),
                      MapAnimationOptions(duration: 600),
                    );
                  },
                ),
              );
            },
          ),

          // DIRECTORIO LATERAL / BOTTOM SHEET
          if (_directoryOpen)
            PoiDirectorySheet(
              onClose: () => setState(() => _directoryOpen = false),
              onPoiSelected: (poi) async {
                final previousId = context.read<MapProvider>().selectedPoi?.id;
                context.read<MapProvider>().selectPoi(poi);
                await _updateMarkerSelection(previousId, poi.id);
                await _flyToPoi(poi);
                setState(() => _directoryOpen = false);
              },
            ),
        ],
      ),
    );
  }

  // ---- MAP CALLBACKS ----

  void _onMapCreated(MapboxMap map) async {
    _mapboxMap = map;

    // Restricciones del campus
    await map.setBounds(CameraBoundsOptions(
      bounds: _campusBounds,
      minZoom: 15.0,
      maxZoom: 20.0,
    ));

    // Crear manager de marcadores
    _annotationManager = await map.annotations.createPointAnnotationManager();
    _annotationManager!.tapEvents(onTap: (annotation) async {
      final poi = _findPoiByAnnotationId(annotation.id);
      if (poi != null) {
        final previousId = context.read<MapProvider>().selectedPoi?.id;
        context.read<MapProvider>().selectPoi(poi);
        await _updateMarkerSelection(previousId, poi.id);
        _flyToPoi(poi);
      }
    });
  }

  // ---- MARCADORES ----

  Future<void> _loadMarkers() async {
    if (_annotationManager == null || _mapboxMap == null) return;
    _annotationIdToPoiId.clear();
    _annotations.clear();

    // Pre-generar y registrar imágenes por categoría (normal + seleccionado)
    for (final category in PoiCategory.values) {
      final normalKey   = 'marker_${category.name}_normal';
      final selectedKey = 'marker_${category.name}_selected';

      final normalBytes   = await MarkerImageUtil.generateMarkerBytes(
          category: category, isSelected: false);
      final selectedBytes = await MarkerImageUtil.generateMarkerBytes(
          category: category, isSelected: true);

      await _mapboxMap!.style.addStyleImage(
        normalKey, 1.0,
        MbxImage(width: 44, height: 44, data: normalBytes),
        false, [], [], null,
      );
      await _mapboxMap!.style.addStyleImage(
        selectedKey, 1.0,
        MbxImage(width: 52, height: 52, data: selectedBytes),
        false, [], [], null,
      );
    }

    // Crear las anotaciones
    for (final poi in PoiData.all) {
      final iconKey = 'marker_${poi.category.name}_normal';
      final annotation = await _annotationManager!.create(
        PointAnnotationOptions(
          geometry: Point(coordinates: Position(poi.longitude, poi.latitude)),
          iconImage: iconKey,
          iconSize: 1.0,
          iconAnchor: IconAnchor.BOTTOM,
          // Etiqueta — se controla visibilidad vía zoom en el provider
          textField: poi.name,
          textOffset: [0.0, 0.5],
          textSize: 11.0,
          textColor: Colors.black.toARGB32(),
          textHaloColor: Colors.white.toARGB32(),
          textHaloWidth: 1.5,
          textAnchor: TextAnchor.TOP,
        ),
      );
      _annotationIdToPoiId[annotation.id] = poi.id;
      _annotations[poi.id] = annotation; // guardar referencia para actualizar
    }
  }

  Future<void> _updateMarkerSelection(String? previousPoiId, String? newPoiId) async {
    // Resetear anterior
    if (previousPoiId != null && _annotations.containsKey(previousPoiId)) {
      final prev = _annotations[previousPoiId]!;
      final poi = PoiData.all.firstWhere((p) => p.id == previousPoiId);
      prev.iconImage = 'marker_${poi.category.name}_normal';
      prev.iconSize = 1.0;
      await _annotationManager?.update(prev);
    }
    // Resaltar nuevo
    if (newPoiId != null && _annotations.containsKey(newPoiId)) {
      final next = _annotations[newPoiId]!;
      final poi = PoiData.all.firstWhere((p) => p.id == newPoiId);
      next.iconImage = 'marker_${poi.category.name}_selected';
      next.iconSize = 1.0;
      await _annotationManager?.update(next);
    }
  }

  Future<void> _syncLabelVisibility(double zoom) async {
    final shouldShow = zoom >= 16.5;
    if (shouldShow == _labelsVisible) return; // sin cambio
    _labelsVisible = shouldShow;

    // Actualizar todas las anotaciones
    final updates = _annotations.values.map((annotation) {
      annotation.textOpacity = shouldShow ? 1.0 : 0.0;
      return annotation;
    }).toList();

    if (updates.isNotEmpty && _annotationManager != null) {
      await Future.wait(
        updates.map((annotation) => _annotationManager!.update(annotation)),
      );
    }
  }

  PoiModel? _findPoiByAnnotationId(String annotationId) {
    final poiId = _annotationIdToPoiId[annotationId];
    if (poiId == null) return null;
    try {
      return PoiData.all.firstWhere((p) => p.id == poiId);
    } catch (_) {
      return null;
    }
  }

  // ---- ANIMACIONES DE CÁMARA ----

  Future<void> _flyToPoi(PoiModel poi) async {
    await _mapboxMap?.flyTo(
      CameraOptions(
        center: Point(coordinates: Position(poi.longitude, poi.latitude)),
        zoom: 18.5,
        pitch: 55.0,
        bearing: 15.0,
      ),
      MapAnimationOptions(duration: 1200, startDelay: 0),
    );
  }

  Future<void> _resetCamera() async {
    final previousId = context.read<MapProvider>().selectedPoi?.id;
    context.read<MapProvider>().clearSelection();
    await _updateMarkerSelection(previousId, null);
    
    await _mapboxMap?.flyTo(
      CameraOptions(
        center: _campusCenter,
        zoom: 17.5,
        pitch: 50.0,
        bearing: 0.0,
      ),
      MapAnimationOptions(duration: 800),
    );
  }

  // ---- BOTONES UI ----

  Widget _buildDirectoryButton() {
    return FloatingActionButton.extended(
      heroTag: 'directory',
      backgroundColor: Colors.white,
      foregroundColor: const Color(0xFF1D3557),
      onPressed: () => setState(() => _directoryOpen = true),
      icon: const Icon(Icons.grid_view_rounded),
      label: const Text('Directorio',
          style: TextStyle(fontWeight: FontWeight.w600)),
    );
  }

  Widget _buildResetButton() {
    return FloatingActionButton(
      heroTag: 'reset',
      backgroundColor: Colors.white,
      foregroundColor: const Color(0xFF1D3557),
      mini: true,
      onPressed: _resetCamera,
      child: const Icon(Icons.my_location_rounded),
    );
  }
}


