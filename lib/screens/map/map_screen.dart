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
import 'widgets/poi_layer_selector.dart';
import 'dart:convert';
import 'utils/campus_polygon.dart';
import '../../widgets/core/base_screen.dart';
import '../../services/path_graph_service.dart';
import 'widgets/route_selector_panel.dart';
import 'models/map_view_mode.dart';
import 'widgets/map_view_toggle_button.dart';

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
  static const satellite = 'mapbox://styles/mapbox/satellite-v9';
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
  final PathGraphService _pathService = PathGraphService();
  bool _directoryOpen = false;
  PoiCategory? _directoryFilter;

  final Map<String, String> _annotationIdToPoiId = {};
  final Map<String, PointAnnotation> _annotations = {};
  PointAnnotation? _campusAnnotation;

  // Estado de visibilidad actual para evitar updates innecesarios
  bool _markersVisible = false;
  bool _labelsVisible = false;
  PoiCategory? _currentActiveCategory;
  bool _isRoutingActive = false;

  // Variables de rotación continua
  late AnimationController _rotationController;
  double _currentBearing = 0.0;
  bool _userInteracting = false;
  bool _isFlying = false;
  bool _styleReady = false;

  late MapProvider _mapProvider;

  double get _pitchForCurrentMode => _pitchForMode(context.read<MapProvider>().currentViewMode);

  double _pitchForMode(MapViewMode mode) {
    switch (mode) {
      case MapViewMode.normal:
        return 45.0;
      case MapViewMode.lineal:
        return 0.0;
      case MapViewMode.satelite:
        return 0.0; // satélite puro queda mejor cenital; confirmar con el usuario si prefiere inclinado
    }
  }

  @override
  void initState() {
    super.initState();
    _pathService.loadGraph();
    _mapProvider = context.read<MapProvider>();
    _mapProvider.addListener(_onMapProviderChanged);
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..addListener(_onRotationTick);
    // Ya no se llama a repeat() aquí. Se llamará al finalizar el vuelo hacia un POI.
  }

  void _onMapProviderChanged() async {
    if (_mapboxMap != null && mounted && _styleReady) {
      final state = await _mapboxMap!.getCameraState();
      await _syncMarkerVisibility(state.zoom);
      await _syncRouteLine();
    }
  }

  Future<void> _syncRouteLine() async {
    if (_mapboxMap == null || !_styleReady) return;
    final mapProvider = context.read<MapProvider>();
    final coords = mapProvider.activeRouteCoords;
    
    if (coords.isEmpty || !mapProvider.isRoutingMode) {
      await _mapboxMap!.style.setStyleSourceProperty("route-source", "data", '{"type": "FeatureCollection", "features": []}');
      return;
    }
    
    // Draw the route
    final jsonStr = '''
    {
      "type": "FeatureCollection",
      "features": [
        {
          "type": "Feature",
          "properties": {},
          "geometry": {
            "type": "LineString",
            "coordinates": [
              ${coords.map((p) => "[${p.lng}, ${p.lat}]").join(",")}
            ]
          }
        }
      ]
    }
    ''';
    await _mapboxMap!.style.setStyleSourceProperty("route-source", "data", jsonStr);
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
    _rotationController.stop();
    _rotationController.dispose();
    _mapProvider.removeListener(_onMapProviderChanged);
    
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
            onPointerDown: (_) {
              _userInteracting = true;
              _rotationController.stop();
            },
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
                await _onStyleLoaded();
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

          // PANEL SUPERIOR: Búsqueda o Modo Ruta
          Consumer<MapProvider>(
            builder: (context, mapProvider, child) {
              if (mapProvider.isRoutingMode) {
                return Positioned(
                  top: MediaQuery.of(context).padding.top + 12,
                  left: 0,
                  right: 0,
                  child: RouteSelectorPanel(
                    onClose: () {
                      mapProvider.exitRoutingMode();
                    },
                    onRouteRequested: (start, end) async {
                      final path = _pathService.findRoute(
                        Position(start.longitude, start.latitude),
                        Position(end.longitude, end.latitude)
                      );
                      mapProvider.setRouteStart(start);
                      mapProvider.setRouteEnd(end);
                      mapProvider.setActiveRouteCoords(path);
                      
                      if (path.isNotEmpty && _mapboxMap != null) {
                        double minLat = 90.0, maxLat = -90.0, minLng = 180.0, maxLng = -180.0;
                        for (final p in path) {
                          if (p.lat.toDouble() < minLat) minLat = p.lat.toDouble();
                          if (p.lat.toDouble() > maxLat) maxLat = p.lat.toDouble();
                          if (p.lng.toDouble() < minLng) minLng = p.lng.toDouble();
                          if (p.lng.toDouble() > maxLng) maxLng = p.lng.toDouble();
                        }
                        final bounds = CoordinateBounds(
                          southwest: Point(coordinates: Position(minLng, minLat)),
                          northeast: Point(coordinates: Position(maxLng, maxLat)),
                          infiniteBounds: true,
                        );
                        final state = await _mapboxMap!.getCameraState();
                        final cam = await _mapboxMap!.cameraForCoordinateBounds(
                          bounds, 
                          MbxEdgeInsets(top: 250, left: 60, bottom: 60, right: 60),
                          state.bearing, state.pitch, null, null
                        );
                        
                        double targetZoom = cam.zoom ?? state.zoom;
                        if (targetZoom > 18.0) targetZoom = 18.0;

                        await _mapboxMap!.flyTo(
                          CameraOptions(
                            center: cam.center,
                            zoom: targetZoom,
                            bearing: state.bearing,
                            pitch: _pitchForCurrentMode,
                          ),
                          MapAnimationOptions(duration: 800)
                        );
                      }
                    }
                  ),
                );
              }
              
              return Positioned(
                top: MediaQuery.of(context).padding.top + 12,
                left: 0,
                right: 0,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
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
                              onSearchTap: _closeAllSheets,
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
                    const SizedBox(height: 12),
                    PoiLayerSelector(
                      onFilterApplied: (category) {
                        _flyToCategoryBounds(category);
                      },
                    ),
                  ],
                ),
              );
            },
          ),

          // BOTÓN DIRECTORIO + UBICACIÓN (abajo izquierda)
          Positioned(
            bottom: MediaQuery.of(context).padding.bottom + 24,
            left: 16,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDirectoryButton(),
                const SizedBox(width: 8),
                _buildResetButton(),
              ],
            ),
          ),

          // BOTÓN DE VISTAS DE MAPA (abajo derecha, reemplaza al reset)
          Positioned(
            bottom: MediaQuery.of(context).padding.bottom + 24,
            right: 16,
            child: Consumer<MapProvider>(
              builder: (context, mapProvider, _) => MapViewToggleButton(
                currentMode: mapProvider.currentViewMode,
                onModeSelected: (mode) => _applyViewMode(mode),
              ),
            ),
          ),

          // PANEL INFERIOR: Detalle de POI seleccionado
          Consumer<MapProvider>(
            builder: (context, mapProvider, _) {
              final poi = mapProvider.selectedPoi;
              if (poi == null) return const SizedBox.shrink();
              return Positioned.fill(
                child: PoiDetailSheet(
                  poi: poi,
                  onStartRouting: () async {
                    final previousId = poi.id;
                    mapProvider.startRoutingFromPoi(poi);
                    await _updateMarkerSelection(previousId, null);
                    
                    if (_mapboxMap != null) {
                      final state = await _mapboxMap!.getCameraState();
                      await _mapboxMap?.flyTo(
                        CameraOptions(
                          center: state.center,
                          zoom: 17.0, // Moderate zoom out
                          pitch: _pitchForCurrentMode,
                          bearing: state.bearing,
                          padding: MbxEdgeInsets(top: 150, left: 0, bottom: 0, right: 0),
                        ),
                        MapAnimationOptions(duration: 800),
                      );
                    }
                  },
                  onClose: () async {
                    final previousId = poi.id;
                    mapProvider.clearSelection();
                    await _updateMarkerSelection(previousId, null);
                    
                    final state = await _mapboxMap!.getCameraState();
                    await _mapboxMap?.flyTo(
                      CameraOptions(
                        center: state.center,
                        zoom: (state.zoom > 16.5) ? state.zoom - 1.0 : state.zoom,
                        pitch: _pitchForCurrentMode,
                        bearing: state.bearing,
                      ),
                      MapAnimationOptions(duration: 800),
                    );
                  },
                  onOpenDirectory: (category) async {
                    _rotationController.stop();
                    final previousId = poi.id;
                    mapProvider.clearSelection();
                    await _updateMarkerSelection(previousId, null);
                    
                    final state = await _mapboxMap!.getCameraState();
                    await _mapboxMap?.flyTo(
                      CameraOptions(
                        center: state.center,
                        zoom: (state.zoom > 16.5) ? state.zoom - 1.0 : state.zoom,
                        pitch: _pitchForCurrentMode,
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
                // Si había un POI seleccionado y cerramos el directorio, y no volamos a ningún lado, 
                // podríamos reactivar la rotación. Pero al cerrar el directorio no seleccionamos un POI 
                // si no elegimos uno. Si elegimos, _flyToPoi se encarga.
              }),
              onPoiSelected: (poi) async {
                _rotationController.stop();
                final previousId = context.read<MapProvider>().selectedPoi?.id;
                context.read<MapProvider>().selectPoi(poi);
                await _updateMarkerSelection(previousId, poi.id);
                setState(() {
                  _directoryOpen = false;
                  _directoryFilter = null;
                });
                await _flyToPoi(poi);
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
  }

  Future<void> _onStyleLoaded() async {
    if (_mapboxMap == null) return;
    final mode = context.read<MapProvider>().currentViewMode;

    await _mapboxMap!.style.setStyleImportConfigProperty("basemap", "showPointOfInterestLabels", false);
    await _mapboxMap!.style.setStyleImportConfigProperty("basemap", "showPlaceLabels", false);

    if (mode != MapViewMode.satelite) {
      await _mapboxMap!.style.setStyleImportConfigProperty(
        "basemap", "show3dObjects", mode == MapViewMode.normal,
      );
    }

    await _mapboxMap!.setBounds(CameraBoundsOptions(
      bounds: _campusBounds,
      minZoom: _minZoom,
      maxZoom: _maxZoom,
    ));

    await _mapboxMap!.style.addSource(GeoJsonSource(
      id: "route-source",
      data: '{"type": "FeatureCollection", "features": []}',
    ));
    await _mapboxMap!.style.addLayer(LineLayer(
      id: "route-layer",
      sourceId: "route-source",
      lineColor: const Color(0xFF4CAF50).toARGB32(),
      lineWidth: 6.0,
      lineOpacity: 0.8,
      lineJoin: LineJoin.ROUND,
      lineCap: LineCap.ROUND,
    ));

    if (mode != MapViewMode.satelite) {
      await _addFogOfWarEffect();
    }

    if (_annotationManager != null) {
      await _annotationManager!.deleteAll();
      await _mapboxMap!.annotations.removeAnnotationManager(_annotationManager!);
    }
    _annotationManager = await _mapboxMap!.annotations.createPointAnnotationManager();
    _annotationManager!.tapEvents(onTap: (annotation) async {
      final poi = _findPoiByAnnotationId(annotation.id);
      if (poi != null) {
        final previousId = context.read<MapProvider>().selectedPoi?.id;
        context.read<MapProvider>().selectPoi(poi);
        await _updateMarkerSelection(previousId, poi.id);
        _flyToPoi(poi);
      }
    });
    await _loadMarkers();

    await _syncRouteLine();

    _styleReady = true;
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

    // 1. Generar los bytes de Canvas en paralelo para todos los POIs
    final futures = <Future<Map<String, dynamic>>>[];
    for (final poi in PoiData.all) {
      futures.add(() async {
        final markerBytes = await MarkerImageUtil.generatePoiMarker(poi, size: 56);
        return {
          'poiId': poi.id,
          'bytes': markerBytes,
        };
      }());
    }

    final results = await Future.wait(futures);

    // 2. Registrar las imágenes secuencialmente en Mapbox (Method Channel thread-safe)
    for (final result in results) {
      final poiId = result['poiId'] as String;
      final bytes = result['bytes'] as dynamic;
      
      final iconKey = 'image_$poiId';

      await _mapboxMap!.style.addStyleImage(
        iconKey, 1.0,
        MbxImage(width: 56, height: 56, data: bytes),
        false, [], [], null,
      );
    }

    // Crear anotaciones para los 41 puntos
    for (final poi in PoiData.all) {
      final iconKey = 'image_${poi.id}';
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
    final campusBytes = await MarkerImageUtil.generateCampusMarker();
    await _mapboxMap!.style.addStyleImage(
      'image_campus_logo', 1.0,
      MbxImage(width: 56, height: 56, data: campusBytes),
      false, [], [], null,
    );

    _campusAnnotation = await _annotationManager!.create(
      PointAnnotationOptions(
        geometry: Point(coordinates: Position(_campusCenter.coordinates.lng, _campusCenter.coordinates.lat)),
        iconImage: 'image_campus_logo',
        iconSize: 1.2,
        iconOpacity: 1.0,
        textField: 'Escuela Politécnica Nacional',
        textOffset: [0.0, 1.2],
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
    final activeCategory = _mapProvider.activeCategory;
    final isRoutingWithBoth = _mapProvider.isRoutingMode && _mapProvider.routeStart != null && _mapProvider.routeEnd != null;
    final shouldShowMarkers = zoom >= _markersVisibleZoom || activeCategory != null;
    final shouldShowLabels = zoom >= _labelsVisibleZoom || activeCategory != null;

    // Salir si nada cambia
    if (shouldShowMarkers == _markersVisible &&
        shouldShowLabels == _labelsVisible &&
        activeCategory == _currentActiveCategory &&
        isRoutingWithBoth == _isRoutingActive) {
      return;
    }

    _markersVisible = shouldShowMarkers;
    _labelsVisible = shouldShowLabels;
    _currentActiveCategory = activeCategory;
    _isRoutingActive = isRoutingWithBoth;

    final selectedPoiId = context.read<MapProvider>().selectedPoi?.id;

    final updates = <PointAnnotation>[];
    
    for (final entry in _annotations.entries) {
      final annotation = entry.value;
      bool changed = false;
      
      final poi = PoiData.all.firstWhere((p) => p.id == entry.key);
      final isFilteredOut = activeCategory != null && poi.category != activeCategory;
      
      double targetIconOpacity = 0.0;
      double targetTextOpacity = 0.0;

      if (isRoutingWithBoth) {
        if (poi.id == _mapProvider.routeStart?.id || poi.id == _mapProvider.routeEnd?.id) {
          targetIconOpacity = 1.0;
          targetTextOpacity = 1.0;
        } else {
          targetIconOpacity = 0.0;
          targetTextOpacity = 0.0;
        }
      } else {
        targetIconOpacity = shouldShowMarkers 
            ? (isFilteredOut ? 0.0 : (selectedPoiId != null && entry.key != selectedPoiId ? 0.3 : 1.0)) 
            : 0.0;
        targetTextOpacity = shouldShowLabels 
            ? (isFilteredOut ? 0.0 : (selectedPoiId != null && entry.key != selectedPoiId ? 0.3 : 1.0)) 
            : 0.0;
      }
          
      if (annotation.iconOpacity != targetIconOpacity) {
        annotation.iconOpacity = targetIconOpacity;
        changed = true;
      }
      if (annotation.textOpacity != targetTextOpacity) {
        annotation.textOpacity = targetTextOpacity;
        changed = true;
      }
      
      if (changed) {
        updates.add(annotation);
      }
    }

    if (_campusAnnotation != null) {
      bool changed = false;
      final targetIconOpacity = (shouldShowMarkers || _isRoutingActive) ? 0.0 : 1.0;
      final targetTextOpacity = (shouldShowMarkers || _isRoutingActive) ? 0.0 : 1.0;
      if (_campusAnnotation!.iconOpacity != targetIconOpacity) {
        _campusAnnotation!.iconOpacity = targetIconOpacity;
        changed = true;
      }
      if (_campusAnnotation!.textOpacity != targetTextOpacity) {
        _campusAnnotation!.textOpacity = targetTextOpacity;
        changed = true;
      }
      if (changed) {
        updates.add(_campusAnnotation!);
      }
    }

    if (updates.isNotEmpty && _annotationManager != null) {
      await Future.wait(
        updates.map((a) => _annotationManager!.update(a)),
      );
    }
  }

  Future<void> _flyToCategoryBounds(PoiCategory category) async {
    final pois = PoiData.all.where((p) => p.category == category).toList();
    if (pois.isEmpty || _mapboxMap == null) return;
    
    double minLat = 90.0, maxLat = -90.0, minLng = 180.0, maxLng = -180.0;
    for (final p in pois) {
      if (p.latitude < minLat) minLat = p.latitude;
      if (p.latitude > maxLat) maxLat = p.latitude;
      if (p.longitude < minLng) minLng = p.longitude;
      if (p.longitude > maxLng) maxLng = p.longitude;
    }
    
    final bounds = CoordinateBounds(
      southwest: Point(coordinates: Position(minLng, minLat)),
      northeast: Point(coordinates: Position(maxLng, maxLat)),
      infiniteBounds: true,
    );
    
    final state = await _mapboxMap!.getCameraState();
    
    final cameraOptions = await _mapboxMap!.cameraForCoordinateBounds(
      bounds, 
      MbxEdgeInsets(top: 150, left: 60, bottom: 60, right: 60),
      state.bearing, 
      state.pitch, 
      null, null
    );
    
    double targetZoom = cameraOptions.zoom ?? state.zoom;
    if (targetZoom < 17.2) {
      targetZoom = 17.2;
    }
    
    await _mapboxMap!.flyTo(
      CameraOptions(
        center: cameraOptions.center,
        zoom: targetZoom,
        bearing: state.bearing,
        pitch: _pitchForCurrentMode,
      ), 
      MapAnimationOptions(duration: 800)
    );
  }

  Future<void> _updateMarkerSelection(
      String? previousPoiId, String? newPoiId) async {
    final updates = <PointAnnotation>[];

    // Restaurar el anterior
    if (previousPoiId != null && _annotations.containsKey(previousPoiId)) {
      final prev = _annotations[previousPoiId]!;
      if (prev.iconSize != 1.0) {
        prev.iconSize = 1.0;
        updates.add(prev);
      }
    }

    // Seleccionar el nuevo
    if (newPoiId != null && _annotations.containsKey(newPoiId)) {
      final ann = _annotations[newPoiId]!;
      if (ann.iconSize != 1.4) {
        ann.iconSize = 1.4;
        updates.add(ann);
      }
    } else if (newPoiId == null) {
      _rotationController.stop();
    }

    if (updates.isNotEmpty) {
      await Future.wait(updates.map((a) => _annotationManager!.update(a)));
    }
    
    // Sincronizar opacidades usando la lógica centralizada
    if (_mapboxMap != null) {
      final state = await _mapboxMap!.getCameraState();
      // Forzar actualización ignorando caché local para aplicar selecciones
      _markersVisible = false; 
      await _syncMarkerVisibility(state.zoom);
    }

    // Iniciar pulso
    if (newPoiId != null) {
      _pulseMarker(newPoiId);
    }
  }

  Future<void> _pulseMarker(String poiId) async {
    final ann = _annotations[poiId];
    if (ann == null) return;
    ann.iconSize = 1.6;
    await _annotationManager?.update(ann);
    await Future.delayed(const Duration(milliseconds: 200));
    
    final ann2 = _annotations[poiId];
    if (ann2 == null) return;
    ann2.iconSize = 1.4;
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
    _rotationController.stop();
    // Altura aproximada del PoiDetailSheet + margen de seguridad
    // Ajustar este valor si el sheet es más alto o más bajo
    const double sheetHeight = 320.0;
    const double topPadding = 80.0; // espacio para la barra de búsqueda

    await _mapboxMap?.flyTo(
      CameraOptions(
        center: Point(coordinates: Position(poi.longitude, poi.latitude)),
        zoom: 18.5,
        pitch: _pitchForCurrentMode,
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
    if (!mounted) return;
    _isFlying = false;
    _currentBearing = 15.0;
    
    // Iniciar rotación si aún sigue seleccionado y no hay interacción
    if (context.read<MapProvider>().selectedPoi?.id == poi.id && 
        !_userInteracting && 
        !_directoryOpen) {
      _rotationController.repeat();
    }
  }

  Future<void> _applyViewMode(MapViewMode mode) async {
    if (_mapboxMap == null) return;

    final previousMode = context.read<MapProvider>().currentViewMode;
    final wasOnCampusStyle = previousMode != MapViewMode.satelite;
    final willBeOnCampusStyle = mode != MapViewMode.satelite;

    // Caso A: cambio ENTRE Normal y Lineal (mismo estilo base, liviano)
    if (wasOnCampusStyle && willBeOnCampusStyle) {
      final show3dObjects = mode == MapViewMode.normal;
      await _mapboxMap!.style.setStyleImportConfigProperty(
        "basemap", "show3dObjects", show3dObjects,
      );

      final state = await _mapboxMap!.getCameraState();
      await _mapboxMap!.flyTo(
        CameraOptions(
          center: state.center,
          zoom: state.zoom,
          pitch: _pitchForMode(mode),
          bearing: state.bearing,
        ),
        MapAnimationOptions(duration: 800),
      );

      if (!mounted) return;
      context.read<MapProvider>().setViewMode(mode);
      return;
    }

    // Caso B: entrando o saliendo de Satélite (cambia el estilo base, requiere reconstruir todo)
    final targetStyleUri = mode == MapViewMode.satelite
        ? _MapStyles.satellite
        : _MapStyles.campus;

    if (mounted) {
      context.read<MapProvider>().setViewMode(mode);
    }

    await _mapboxMap!.loadStyleURI(targetStyleUri);

    final state = await _mapboxMap!.getCameraState();
    await _mapboxMap!.flyTo(
      CameraOptions(
        center: state.center,
        zoom: state.zoom,
        pitch: _pitchForMode(mode),
        bearing: state.bearing,
      ),
      MapAnimationOptions(duration: 800),
    );
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
        pitch: _pitchForCurrentMode,
        bearing: 0.0,
        padding: MbxEdgeInsets(top: 80, left: 0, bottom: 0, right: 0),
      ),
      MapAnimationOptions(duration: 800),
    );
    _isFlying = false;
    _currentBearing = 0.0;
  }

  Future<void> _closeAllSheets() async {
    _rotationController.stop();
    bool changed = false;
    if (_directoryOpen) {
      setState(() => _directoryOpen = false);
      changed = true;
    }
    
    final mapProvider = context.read<MapProvider>();
    final poi = mapProvider.selectedPoi;
    if (poi != null) {
      final previousId = poi.id;
      mapProvider.clearSelection();
      await _updateMarkerSelection(previousId, null);
      changed = true;
    }
    
    if (changed && _mapboxMap != null) {
      final state = await _mapboxMap!.getCameraState();
      await _mapboxMap?.flyTo(
        CameraOptions(
          center: state.center,
          zoom: (state.zoom > 16.5) ? state.zoom - 1.0 : state.zoom,
          pitch: _pitchForCurrentMode,
          bearing: state.bearing,
        ),
        MapAnimationOptions(duration: 800),
      );
    }
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
