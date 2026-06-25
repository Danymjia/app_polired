import 'dart:convert';
import 'dart:math';
import 'package:flutter/services.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

const double _metersPerDegree = 111320.0;
const double _snapToleranceMeters = 3.0; // Tolerancia para nodos idénticos
const int _maxNodesForAutoBridge = 5;

double _distanceInMeters(Position p1, Position p2) {
  double dx = (p1.lng - p2.lng) * _metersPerDegree;
  double dy = (p1.lat - p2.lat) * _metersPerDegree;
  return sqrt(dx * dx + dy * dy);
}

class PathNode {
  final int id;
  final Position position;
  final List<int> edges = [];

  PathNode(this.id, this.position);
}

class PathGraphService {
  final List<PathNode> _nodes = [];
  bool _isLoaded = false;

  /// Carga el grafo peatonal desde el archivo GeoJSON.
  /// Aplica el auto-puente para componentes desconectados de menos de 5 nodos.
  Future<void> loadGraph() async {
    if (_isLoaded) return;
    
    final pathsJsonString = await rootBundle.loadString('assets/docs/paths.geojson');
    final pathsJson = jsonDecode(pathsJsonString);
    
    _nodes.clear();
    int nextNodeId = 0;

    int findOrAddNode(Position pos) {
      for (var n in _nodes) {
        if (_distanceInMeters(n.position, pos) <= _snapToleranceMeters) {
          return n.id;
        }
      }
      _nodes.add(PathNode(nextNodeId, pos));
      return nextNodeId++;
    }

    // 1. Construir nodos y aristas a partir de los LineStrings
    for (var feature in pathsJson['features']) {
      if (feature['geometry'] != null && feature['geometry']['type'] == 'LineString') {
        List<dynamic> coords = feature['geometry']['coordinates'];
        if (coords.length < 2) continue;

        int prevId = findOrAddNode(Position(coords[0][0].toDouble(), coords[0][1].toDouble()));
        for (int i = 1; i < coords.length; i++) {
          Position p2 = Position(coords[i][0].toDouble(), coords[i][1].toDouble());
          int currId = findOrAddNode(p2);
          
          if (!_nodes[prevId].edges.contains(currId)) _nodes[prevId].edges.add(currId);
          if (!_nodes[currId].edges.contains(prevId)) _nodes[currId].edges.add(prevId);
          
          prevId = currId;
        }
      }
    }

    // 2. Conectar islas pequeñas (auto-puente)
    _autoBridgeComponents();
    _isLoaded = true;
  }

  void _autoBridgeComponents() {
    Set<int> visited = {};
    List<List<int>> components = [];

    // Identificar componentes conexos
    for (int i = 0; i < _nodes.length; i++) {
      if (!visited.contains(i)) {
        List<int> comp = [];
        List<int> queue = [i];
        visited.add(i);

        while (queue.isNotEmpty) {
          int curr = queue.removeAt(0);
          comp.add(curr);
          for (int neighbor in _nodes[curr].edges) {
            if (!visited.contains(neighbor)) {
              visited.add(neighbor);
              queue.add(neighbor);
            }
          }
        }
        components.add(comp);
      }
    }

    if (components.isEmpty) return;

    // El componente más grande es la red principal
    components.sort((a, b) => b.length.compareTo(a.length));
    List<int> mainComponent = components.first;

    for (int i = 1; i < components.length; i++) {
      List<int> comp = components[i];
      if (comp.length <= _maxNodesForAutoBridge) {
        // Encontrar el par de nodos más cercano entre este componente y la red principal
        double minDist = double.infinity;
        int bestSmallNode = -1;
        int bestMainNode = -1;

        for (int smallId in comp) {
          for (int mainId in mainComponent) {
            double d = _distanceInMeters(_nodes[smallId].position, _nodes[mainId].position);
            if (d < minDist) {
              minDist = d;
              bestSmallNode = smallId;
              bestMainNode = mainId;
            }
          }
        }

        if (bestSmallNode != -1 && bestMainNode != -1) {
          // Crear la arista artificial (auto-puente)
          _nodes[bestSmallNode].edges.add(bestMainNode);
          _nodes[bestMainNode].edges.add(bestSmallNode);
        }
      }
    }
  }
  
  PathNode? _findNearestNode(Position target) {
    if (_nodes.isEmpty) return null;
    PathNode? nearest;
    double minDist = double.infinity;
    for (var node in _nodes) {
      double d = _distanceInMeters(node.position, target);
      if (d < minDist) {
        minDist = d;
        nearest = node;
      }
    }
    return nearest;
  }

  /// Calcula la ruta peatonal más corta usando A*
  List<Position> findRoute(Position start, Position end) {
    if (!_isLoaded) return [];

    PathNode? startNode = _findNearestNode(start);
    PathNode? endNode = _findNearestNode(end);

    if (startNode == null || endNode == null) {
      print("[RUTEO] Fallo crítico: startNode ($startNode) o endNode ($endNode) es null");
      return [];
    }
    
    print("[RUTEO] Origen (POI): lng=${start.lng}, lat=${start.lat}");
    print("[RUTEO] Snap Origen (Grafo): id=${startNode.id}, lng=${startNode.position.lng}, lat=${startNode.position.lat}");
    print("[RUTEO] Destino (POI): lng=${end.lng}, lat=${end.lat}");
    print("[RUTEO] Snap Destino (Grafo): id=${endNode.id}, lng=${endNode.position.lng}, lat=${endNode.position.lat}");

    // Algoritmo A*
    Map<int, double> gScore = {startNode.id: 0.0};
    Map<int, double> fScore = {startNode.id: _distanceInMeters(startNode.position, endNode.position)};
    Map<int, int> cameFrom = {};

    List<int> openSet = [startNode.id];
    Set<int> closedSet = {};

    while (openSet.isNotEmpty) {
      // Encontrar el nodo en openSet con el menor fScore
      int currentId = openSet.first;
      double currentF = fScore[currentId] ?? double.infinity;
      for (int i = 1; i < openSet.length; i++) {
        int id = openSet[i];
        double f = fScore[id] ?? double.infinity;
        if (f < currentF) {
          currentF = f;
          currentId = id;
        }
      }

      if (currentId == endNode.id) {
        // Reconstruir el camino
        List<Position> path = [];
        int curr = currentId;
        while (cameFrom.containsKey(curr)) {
          path.insert(0, _nodes[curr].position);
          curr = cameFrom[curr]!;
        }
        path.insert(0, _nodes[startNode.id].position);
        
        // Agregar las coordenadas reales de inicio y fin para que la ruta se conecte exactamente con los marcadores
        if (_distanceInMeters(start, path.first) > 0.5) {
          path.insert(0, start);
        }
        if (_distanceInMeters(end, path.last) > 0.5) {
          path.add(end);
        }
        
        print("[RUTEO] ÉXITO: A* encontró una ruta con ${path.length} puntos.");
        return path;
      }

      openSet.remove(currentId);
      closedSet.add(currentId);

      for (int neighborId in _nodes[currentId].edges) {
        if (closedSet.contains(neighborId)) continue;

        double tentativeGScore = (gScore[currentId] ?? double.infinity) + 
                                 _distanceInMeters(_nodes[currentId].position, _nodes[neighborId].position);

        if (!openSet.contains(neighborId)) {
          openSet.add(neighborId);
        } else if (tentativeGScore >= (gScore[neighborId] ?? double.infinity)) {
          continue;
        }

        cameFrom[neighborId] = currentId;
        gScore[neighborId] = tentativeGScore;
        fScore[neighborId] = tentativeGScore + _distanceInMeters(_nodes[neighborId].position, endNode.position);
      }
    }

    print("[RUTEO] FALLO: A* no pudo encontrar un camino entre el nodo ${startNode.id} y ${endNode.id}. Islas desconectadas.");
    return []; // No se encontró ruta
  }
}
