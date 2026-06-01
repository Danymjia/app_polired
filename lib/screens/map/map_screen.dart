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
import 'dart:convert';
import 'utils/campus_polygon.dart';
import '../../widgets/core/base_screen.dart';

/// Responsabilidad principal:
/// Renderizar el mapa de la Escuela Politécnica Nacional usando Mapbox. Gestiona el "Fog of War" (polígono invertido oscuro fuera del campus), marcadores dinámicos y la cámara interactiva (Auto-rotación).
///
/// Flujo dentro de la app:
/// Utiliza `MapboxMap` para el renderizado nativo. Extrae los POIs de un archivo estático local (`PoiData.all`). Coordina el vuelo de cámara (`flyTo`) cuando se interactúa con un marcador o con el directorio de búsqueda.
///
/// Dependencias críticas:
/// - `MapboxMapsFlutter` (Motor nativo).
/// - `MapProvider` (Estado efímero de selección y rastreo del nivel de zoom actual).
///
/// Side Effects:
/// - Ticker Continuo: Posee un `AnimationController` infinito `_rotationController.repeat()` que rota la cámara silenciosamente si el usuario no interactúa. Esto drena batería si la pantalla se deja abierta.
///
/// Recordatorios técnicos y CQRS:
/// - Desconexión del Dominio: Los Puntos de Interés (POIs) están *hardcodeados* en assets locales en lugar de consumirse vía API / Repositorio CQRS, lo que genera una brecha técnica respecto al resto de la arquitectura.

// Centro del campus EPN
final _campusCenter = Point(coordinates: Position(-78.4900, -0.2107));

final _campusBounds = CoordinateBounds(
  southwest: Point(coordinates: Position(-78.4930, -0.2140)),
  northeast: Point(coordinates: Position(-78.4850, -0.2075)),
  infiniteBounds: false,
);

class _MapStyles {
  static const campus = 'mapbox://styles/dany404/cmplst9ax000z01qvhgtxeu8r';
  static const active = campus;
}

// Zoom mínimo = campus completo visible
// Zoom de marcadores = solo cuando el usuario se acerca
const double _minZoom       = 15.0;  // campus completo
const double _maxZoom       = 20.0;
const double _markersVisibleZoom = 17.0;  // marcadores aparecen aquí
const double _labelsVisibleZoom  = 17.8;  // etiquetas aparecen aquí

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> with SingleTickerProviderStateMixin {
  MapboxMap? _mapboxMap;
  PointAnnotationManager? _annotationManager;
  bool _directoryOpen = false;
  PoiCategory? _directoryFilter;

  final Map<String, String> _annotationIdToPoiId = {};
  final Map<String, PointAnnotation> _annotations = {};
  PointAnnotation? _campusAnnotation;

  // Estado de visibilidad actual para evitar updates innecesarios
  bool _markersVisible = false;
  bool _labelsVisible = false;

  // Variables de rotación continua
  late AnimationController _rotationController;
  double _currentBearing = 0.0;
  bool _userInteracting = false;
  bool _isFlying = false;

  late MapProvider _mapProvider;

  @override
  void initState() {
    super.initState();
    _mapProvider = context.read<MapProvider>();
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..addListener(_onRotationTick);
    _rotationController.repeat();
  }

  void _onRotationTick() {
    if (_userInteracting || _isFlying || _mapboxMap == null) return;
    if (_directoryOpen) return;
    
    // Solo rotar cuando hay un marcador seleccionado
    if (context.read<MapProvider>().selectedPoi == null) return;

    _currentBearing += 0.08;
    if (_currentBearing >= 360) _currentBearing -= 360;

    _mapboxMap!.setCamera(CameraOptions(bearing: _currentBearing));
  }

  @override
  void dispose() {
    _rotationController.dispose();
    
    // Limpiar el estado global del mapa al salir de la pantalla para que
    // los sheets se cierren y la carga inicial sea limpia.
    Future.microtask(() {
      _mapProvider.clearSelection();
      _mapProvider.clearSearch();
      _mapProvider.setActiveCategory(null);
    });

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BaseScreen(
      backgroundColor: Colors.transparent,
      resizeToAvoidBottomInset: false,
      safeAreaTop: false,
      safeAreaBottom: false,
      dismissKeyboardOnTap: true,
      body: Stack(
        children: [
          // MAPA BASE
          Listener(
            onPointerDown: (_) => _userInteracting = true,
            onPointerUp: (_) async {
              _userInteracting = false;
              if (_mapboxMap != null) {
                final state = await _mapboxMap!.getCameraState();
                _currentBearing = state.bearing;
              }
            },
            child: MapWidget(
              styleUri: _MapStyles.active,
              // ignore: deprecated_member_use
              cameraOptions: CameraOptions(
                center: _campusCenter,
                zoom: 15.2,
                pitch: 45.0,
                bearing: 0.0,
                padding: MbxEdgeInsets(top: 80, left: 0, bottom: 0, right: 0),
              ),
              onMapCreated: _onMapCreated,
              onStyleLoadedListener: (_) async {
                await _addFogOfWarEffect();
                await _loadMarkers();
              },
              onCameraChangeListener: (CameraChangedEventData event) {
                if (!mounted) return;
                final zoom = event.cameraState.zoom;
                context.read<MapProvider>().onZoomChanged(zoom);
                _syncMarkerVisibility(zoom);
                if (_userInteracting) {
                  _currentBearing = event.cameraState.bearing;
                }
              },
            ),
          ),

          // BARRA DE BÚSQUEDA SUPERIOR Y BOTÓN HOME
          Positioned(
            top: MediaQuery.of(context).padding.top + 12,
            left: 8,
            right: 16,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF1D3557)),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: PoiSearchBar(
                    onPoiSelected: (poi) async {
                      final previousId = context.read<MapProvider>().selectedPoi?.id;
                      context.read<MapProvider>().selectPoi(poi);
                      await _updateMarkerSelection(previousId, poi.id);
                      await _flyToPoi(poi);
                    },
                  ),
                ),
              ],
            ),
          ),

          // BOTÓN DIRECTORIO (abajo izquierda)
          Positioned(
            bottom: MediaQuery.of(context).padding.bottom + 24,
            left: 16,
            child: _buildDirectoryButton(),
          ),

          // BOTÓN RESET CÁMARA (abajo derecha)
          Positioned(
            bottom: MediaQuery.of(context).padding.bottom + 24,
            right: 16,
            child: _buildResetButton(),
          ),

          // PANEL INFERIOR: Detalle de POI seleccionado
          Consumer<MapProvider>(
            builder: (context, mapProvider, _) {
              final poi = mapProvider.selectedPoi;
              if (poi == null) return const SizedBox.shrink();
              return Positioned.fill(
                child: PoiDetailSheet(
                  poi: poi,
                  onClose: () async {
                    final previousId = poi.id;
                    mapProvider.clearSelection();
                    await _updateMarkerSelection(previousId, null);
                    
                    final state = await _mapboxMap!.getCameraState();
                    await _mapboxMap?.flyTo(
                      CameraOptions(
                        center: state.center,
                        zoom: (state.zoom > 16.5) ? state.zoom - 1.0 : state.zoom,
                        pitch: state.pitch,
                        bearing: state.bearing,
                      ),
                      MapAnimationOptions(duration: 800),
                    );
                  },
                  onOpenDirectory: (category) async {
                    final previousId = poi.id;
                    mapProvider.clearSelection();
                    await _updateMarkerSelection(previousId, null);
                    
                    final state = await _mapboxMap!.getCameraState();
                    await _mapboxMap?.flyTo(
                      CameraOptions(
                        center: state.center,
                        zoom: (state.zoom > 16.5) ? state.zoom - 1.0 : state.zoom,
                        pitch: state.pitch,
                        bearing: state.bearing,
                      ),
                      MapAnimationOptions(duration: 800),
                    );

                    setState(() {
                      _directoryFilter = category;
                      _directoryOpen = true;
                    });
                  },
                ),
              );
            },
          ),

          // DIRECTORIO LATERAL / BOTTOM SHEET
          if (_directoryOpen)
            Positioned.fill(
              child: PoiDirectorySheet(
                initialCategory: _directoryFilter,
              onClose: () => setState(() {
                _directoryOpen = false;
                _directoryFilter = null;
              }),
              onPoiSelected: (poi) async {
                final previousId = context.read<MapProvider>().selectedPoi?.id;
                context.read<MapProvider>().selectPoi(poi);
                await _updateMarkerSelection(previousId, poi.id);
                await _flyToPoi(poi);
                setState(() => _directoryOpen = false);
              },
            ),
          ),
        ],
      ),
    );
  }

  // ---- MAP CALLBACKS ----

  void _onMapCreated(MapboxMap map) async {
    _mapboxMap = map;

    await map.setBounds(CameraBoundsOptions(
      bounds: _campusBounds,
      minZoom: _minZoom,
      maxZoom: _maxZoom,
    ));

    // Forzar el centrado inicial con el padding correcto para que coincida con _resetCamera
    await map.setCamera(CameraOptions(
      center: _campusCenter,
      zoom: 15.2,
      pitch: 45.0,
      bearing: 0.0,
      padding: MbxEdgeInsets(top: 80, left: 0, bottom: 0, right: 0),
    ));

    await map.style.setStyleImportConfigProperty("basemap", "showPointOfInterestLabels", false);
    await map.style.setStyleImportConfigProperty("basemap", "showPlaceLabels", false);

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

  Future<void> _addFogOfWarEffect() async {
    if (_mapboxMap == null) return;
    final style = _mapboxMap!.style;

    await style.addSource(GeoJsonSource(
      id: "fog-source",
      data: jsonEncode(CampusPolygonData.getInvertedPolygonGeoJson()),
    ));

    await style.addSource(GeoJsonSource(
      id: "fog-border-source",
      data: jsonEncode(CampusPolygonData.getCampusBorderGeoJson()),
    ));

    // Fill sutil — opacidad baja para que el exterior sea visible pero atenuado
    await style.addLayer(FillLayer(
      id: "fog-fill-layer",
      sourceId: "fog-source",
      fillColor: Colors.black.toARGB32(),
      fillOpacity: 0.20,
    ));

    // Blur en el borde — más fino y suave
    await style.addLayer(LineLayer(
      id: "fog-blur-layer",
      sourceId: "fog-border-source",
      lineColor: Colors.black.toARGB32(),
      lineOpacity: 0.18,
      lineWidth: 18.0,
      lineBlur: 20.0,
    ));
  }

  // ---- MARCADORES ----

  Future<void> _loadMarkers() async {
    if (_annotationManager == null || _mapboxMap == null) return;

    // Cargar GeoJSON si aún no se ha hecho
    await PoiData.loadFromAssets();

    _annotationIdToPoiId.clear();
    _annotations.clear();

    // Pre-registrar imágenes por categoría (normal + seleccionado)
    for (final category in PoiCategory.values) {
      final normalKey = 'marker_${category.name}_normal';
      final selectedKey = 'marker_${category.name}_selected';

      final normalBytes = await MarkerImageUtil.generateMarkerBytes(
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

    // Crear anotaciones para los 41 puntos
    for (final poi in PoiData.all) {
      final iconKey = 'marker_${poi.category.name}_normal';
      final annotation = await _annotationManager!.create(
        PointAnnotationOptions(
          geometry: Point(coordinates: Position(poi.longitude, poi.latitude)),
          iconImage: iconKey,
          iconSize: 1.0,
          iconAnchor: IconAnchor.BOTTOM,
          iconOpacity: 0.0, // controlado por _syncMarkerVisibility
          textField: poi.name,
          textOffset: [0.0, 0.5],
          textSize: 11.0,
          textColor: Colors.black.toARGB32(),
          textHaloColor: Colors.white.toARGB32(),
          textHaloWidth: 1.5,
          textAnchor: TextAnchor.TOP,
          textOpacity: 0.0, // controlado por _syncMarkerVisibility
        ),
      );
      _annotationIdToPoiId[annotation.id] = poi.id;
      _annotations[poi.id] = annotation;
    }

    _campusAnnotation = await _annotationManager!.create(
      PointAnnotationOptions(
        geometry: Point(coordinates: Position(_campusCenter.coordinates.lng, _campusCenter.coordinates.lat)),
        iconImage: 'marker_other_selected',
        iconSize: 1.2,
        iconOpacity: 1.0,
        textField: 'Escuela Politécnica Nacional',
        textOffset: [0.0, 0.5],
        textSize: 14.0,
        textColor: Colors.black.toARGB32(),
        textHaloColor: Colors.white.toARGB32(),
        textHaloWidth: 2.0,
        textAnchor: TextAnchor.TOP,
        textOpacity: 1.0,
      )
    );

    // Asegurar visibilidad correcta de los marcadores en la carga inicial
    final cameraState = await _mapboxMap!.getCameraState();
    await _syncMarkerVisibility(cameraState.zoom);
  }

  /// Controla la visibilidad de íconos Y etiquetas según el zoom actual.
  /// - Bajo _markersVisibleZoom  → íconos y textos ocultos (opacity 0)
  /// - Sobre _markersVisibleZoom → íconos visibles siempre
  ///                               textos visibles solo sobre 16.5
  Future<void> _syncMarkerVisibility(double zoom) async {
    final shouldShowMarkers = zoom >= _markersVisibleZoom;
    final shouldShowLabels = zoom >= _labelsVisibleZoom;

    // Salir si nada cambia
    if (shouldShowMarkers == _markersVisible &&
        shouldShowLabels == _labelsVisible) {
      return;
    }

    _markersVisible = shouldShowMarkers;
    _labelsVisible = shouldShowLabels;

    final selectedPoiId = context.read<MapProvider>().selectedPoi?.id;

    final updates = _annotations.entries.map((entry) {
      final annotation = entry.value;
      if (shouldShowMarkers) {
        annotation.iconOpacity = (selectedPoiId != null && entry.key != selectedPoiId) ? 0.3 : 1.0;
      } else {
        annotation.iconOpacity = 0.0;
      }
      if (shouldShowLabels) {
        annotation.textOpacity = (selectedPoiId != null && entry.key != selectedPoiId) ? 0.3 : 1.0;
      } else {
        annotation.textOpacity = 0.0;
      }
      return annotation;
    }).toList();

    if (_campusAnnotation != null) {
      _campusAnnotation!.iconOpacity = shouldShowMarkers ? 0.0 : 1.0;
      _campusAnnotation!.textOpacity = shouldShowMarkers ? 0.0 : 1.0;
      updates.add(_campusAnnotation!);
    }

    if (updates.isNotEmpty && _annotationManager != null) {
      await Future.wait(
        updates.map((a) => _annotationManager!.update(a)),
      );
    }
  }

  Future<void> _updateMarkerSelection(
      String? previousPoiId, String? newPoiId) async {
    // Restaurar el anterior
    if (previousPoiId != null && _annotations.containsKey(previousPoiId)) {
      final prev = _annotations[previousPoiId]!;
      final poi = PoiData.all.firstWhere((p) => p.id == previousPoiId);
      prev.iconImage = 'marker_${poi.category.name}_normal';
      prev.iconSize = 1.0;
      await _annotationManager?.update(prev);
    }

    // Si no hay ninguno seleccionado (deselección global), restaurar opacidad de todos
    if (newPoiId == null) {
      final updates = _annotations.values.map((ann) {
        ann.iconOpacity = _markersVisible ? 1.0 : 0.0;
        ann.textOpacity = _labelsVisible ? 1.0 : 0.0;
        return ann;
      }).toList();
      if (updates.isNotEmpty) {
        await Future.wait(updates.map((a) => _annotationManager!.update(a)));
      }
      return;
    }

    // Hay un nuevo seleccionado: oscurecer los demás
    final updates = _annotations.entries.map((entry) {
      final ann = entry.value;
      if (entry.key == newPoiId) {
        final poi = PoiData.all.firstWhere((p) => p.id == newPoiId);
        ann.iconImage = 'marker_${poi.category.name}_selected';
        ann.iconOpacity = _markersVisible ? 1.0 : 0.0;
        ann.textOpacity = _labelsVisible ? 1.0 : 0.0;
      } else {
        ann.iconOpacity = _markersVisible ? 0.3 : 0.0;
        ann.textOpacity = _labelsVisible ? 0.3 : 0.0;
      }
      return ann;
    }).toList();

    if (updates.isNotEmpty) {
      await Future.wait(updates.map((a) => _annotationManager!.update(a)));
    }

    // Iniciar pulso
    _pulseMarker(newPoiId);
  }

  Future<void> _pulseMarker(String poiId) async {
    final ann = _annotations[poiId];
    if (ann == null) return;
    ann.iconSize = 1.4;
    await _annotationManager?.update(ann);
    await Future.delayed(const Duration(milliseconds: 200));
    
    final ann2 = _annotations[poiId];
    if (ann2 == null) return;
    ann2.iconSize = 1.0;
    await _annotationManager?.update(ann2);
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
    _isFlying = true;
    // Altura aproximada del PoiDetailSheet + margen de seguridad
    // Ajustar este valor si el sheet es más alto o más bajo
    const double sheetHeight = 320.0;
    const double topPadding = 80.0; // espacio para la barra de búsqueda

    await _mapboxMap?.flyTo(
      CameraOptions(
        center: Point(coordinates: Position(poi.longitude, poi.latitude)),
        zoom: 18.5,
        pitch: 55.0,
        bearing: 15.0,
        padding: MbxEdgeInsets(
          top: topPadding,
          left: 0,
          bottom: sheetHeight,  // empuja el centro visual hacia arriba
          right: 0,
        ),
      ),
      MapAnimationOptions(duration: 1200, startDelay: 0),
    );
    
    // Esperar medio segundo adicional después de llegar antes de empezar a rotar
    await Future.delayed(const Duration(milliseconds: 1000));
    _isFlying = false;
    _currentBearing = 15.0;
  }

  Future<void> _resetCamera() async {
    _isFlying = true;
    final previousId = context.read<MapProvider>().selectedPoi?.id;
    context.read<MapProvider>().clearSelection();
    await _updateMarkerSelection(previousId, null);

    await _mapboxMap?.flyTo(
      CameraOptions(
        center: _campusCenter,
        zoom: 15.2,
        pitch: 45.0,
        bearing: 0.0,
        padding: MbxEdgeInsets(top: 80, left: 0, bottom: 0, right: 0),
      ),
      MapAnimationOptions(duration: 800),
    );
    _isFlying = false;
    _currentBearing = 0.0;
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
