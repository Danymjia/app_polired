// DATOS ESTÁTICOS DEL CAMPUS
// Reemplazar las coordenadas con las reales de tu universidad
// Reemplazar los datos con los reales de cada lugar

import '../models/poi_model.dart';

class PoiData {
  static const List<PoiModel> all = [
    PoiModel(
      id: 'biblioteca-central',
      name: 'Biblioteca Central',
      shortDescription: 'Sala de estudio, préstamo de libros y acceso a recursos digitales',
      category: PoiCategory.services,
      latitude: -0.2288,    // REEMPLAZAR
      longitude: -78.5240,  // REEMPLAZAR
      schedule: [
        'Lunes a Viernes: 8:00 - 20:00',
        'Sábado: 9:00 - 14:00',
        'Domingo: Cerrado',
      ],
      howToGet: 'Desde la entrada principal, camina por el pasillo central unos 80 metros. La biblioteca está a tu izquierda en el Edificio A, planta baja.',
      photoAssets: ['assets/photos/biblioteca_1.jpg', 'assets/photos/biblioteca_2.jpg'],
      floor: 'Planta baja',
      building: 'Edificio A',
    ),
    PoiModel(
      id: 'cafeteria-principal',
      name: 'Cafetería Principal',
      shortDescription: 'Menú diario, snacks y bebidas para toda la comunidad universitaria',
      category: PoiCategory.food,
      latitude: -0.2295,    // REEMPLAZAR
      longitude: -78.5248,  // REEMPLAZAR
      schedule: [
        'Lunes a Viernes: 7:00 - 18:00',
        'Sábado: 8:00 - 13:00',
      ],
      howToGet: 'Ubicada en el centro del campus junto al edificio administrativo. Señalizada con letrero azul.',
      photoAssets: ['assets/photos/cafeteria_1.jpg'],
      building: 'Edificio Central',
    ),
    PoiModel(
      id: 'facultad-ingenieria',
      name: 'Facultad de Ingeniería',
      shortDescription: 'Aulas, laboratorios y oficinas de docentes de Ingeniería',
      category: PoiCategory.academic,
      latitude: -0.2301,    // REEMPLAZAR
      longitude: -78.5235,  // REEMPLAZAR
      schedule: [
        'Lunes a Viernes: 7:00 - 21:00',
        'Sábado: 8:00 - 14:00',
      ],
      howToGet: 'Desde la entrada norte, el edificio de Ingeniería es el de 4 pisos a mano derecha. Busca las letras grandes "ING" en la fachada.',
      photoAssets: [],
      building: 'Bloque de Ingeniería',
    ),
    // AGREGAR TODOS LOS POI REALES DEL CAMPUS AQUÍ
  ];
}
