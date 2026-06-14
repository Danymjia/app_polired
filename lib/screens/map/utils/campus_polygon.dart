/// Responsabilidad principal:
/// Contiene las coordenadas (GeoJSON) del polígono que delimita el campus de la EPN.
///
/// Flujo dentro de la app:
/// Utilizado por el MapProvider y la vista del mapa para renderizar la máscara invertida (oscurecer fuera del campus) y el borde.
///
/// Dependencias críticas:
/// - Ninguna (Datos estáticos puros).
///
/// Side Effects:
/// - Ninguno.
///
/// Recordatorios técnicos y CQRS:
/// - Mapbox requiere que el polígono invertido contenga primero el anillo exterior (el mundo entero) y luego el anillo interior (el campus) como hueco.
class CampusPolygonData {
  static const List<List<double>> campusRing = [
    [-78.49287371339769, -0.21141781321387043],
    [-78.49164700215674, -0.2124066147712682],
    [-78.49038372608038, -0.2125546502202269],
    [-78.48904340418198, -0.21267318127308954],
    [-78.48893399014936, -0.21245435471381313],
    [-78.4887333977563, -0.21237685364044978],
    [-78.4881544151673, -0.2113055152275365],
    [-78.48769434166644, -0.2107505471599893],
    [-78.48609693320356, -0.20883142526803056],
    [-78.48665434271386, -0.20842365859753897],
    [-78.48761952159788, -0.20949357846210148],
    [-78.48785894581722, -0.209385090087423],
    [-78.48797420151605, -0.20951133488512141],
    [-78.48871589763188, -0.20992837118923546],
    [-78.4887693727454, -0.20983231122744428],
    [-78.4889597022504, -0.20949770191828065],
    [-78.48846238967292, -0.20907713791440585],
    [-78.4890456575112, -0.2085798286393299],
    [-78.49008326029701, -0.2092275586176413],
    [-78.49041333170246, -0.2093635237267506],
    [-78.49051219386173, -0.21081604012032074],
    [-78.49077661110688, -0.2110303078148945],
    [-78.49156074500715, -0.21096192450890783],
    [-78.49241326267763, -0.21086162899219119],
    [-78.49287371339769, -0.21141781321387043]
  ];

  static Map<String, dynamic> getInvertedPolygonGeoJson() {
    const List<List<double>> worldRing = [
      [-180.0, -90.0],
      [180.0, -90.0],
      [180.0, 90.0],
      [-180.0, 90.0],
      [-180.0, -90.0]
    ];

    return {
      "type": "FeatureCollection",
      "features": [
        {
          "type": "Feature",
          "properties": {},
          "geometry": {
            "type": "Polygon",
            "coordinates": [worldRing, campusRing]
          }
        }
      ]
    };
  }

  static Map<String, dynamic> getCampusBorderGeoJson() {
    return {
      "type": "Feature",
      "properties": {},
      "geometry": {
        "type": "LineString",
        "coordinates": campusRing
      }
    };
  }
}
