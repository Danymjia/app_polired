import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../models/poi_model.dart';

/// Convierte un ícono de Material en una imagen de bytes para Mapbox
/// (Mapbox necesita Uint8List, no widgets Flutter)
class MarkerImageUtil {

  /// Genera un marcador estilo "cápsula negra" como el diseño de referencia
  /// Devuelve los bytes PNG listos para registrar en Mapbox
  static Future<Uint8List> generateMarkerBytes({
    required PoiCategory category,
    required bool isSelected,
    double size = 44,
  }) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final totalSize = size + (isSelected ? 8 : 0);

    // Fondo de la cápsula
    final bgPaint = Paint()
      ..color = isSelected ? const Color(0xFF0D47A1) : const Color(0xFF1A237E)
      ..style = PaintingStyle.fill;

    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, totalSize, totalSize),
      Radius.circular(totalSize * 0.28),
    );
    canvas.drawRRect(rrect, bgPaint);

    // Sombra simulada (borde semitransparente)
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawRRect(rrect, shadowPaint);

    // Ícono centrado (usando IconData de Material)
    final iconData = _iconForCategory(category);
    final textPainter = TextPainter(textDirection: TextDirection.ltr);
    textPainter.text = TextSpan(
      text: String.fromCharCode(iconData.codePoint),
      style: TextStyle(
        fontSize: totalSize * 0.45,
        fontFamily: iconData.fontFamily,
        color: Colors.white,
      ),
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        (totalSize - textPainter.width) / 2,
        (totalSize - textPainter.height) / 2,
      ),
    );

    final picture = recorder.endRecording();
    final image = await picture.toImage(totalSize.toInt(), totalSize.toInt());
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    return byteData!.buffer.asUint8List();
  }

  static IconData _iconForCategory(PoiCategory category) => switch (category) {
    PoiCategory.academic => Icons.school_rounded,
    PoiCategory.services => Icons.local_library_rounded,
    PoiCategory.food     => Icons.restaurant_rounded,
    PoiCategory.sports   => Icons.fitness_center_rounded,
    PoiCategory.admin    => Icons.business_rounded,
    PoiCategory.other    => Icons.place_rounded,
  };
}
