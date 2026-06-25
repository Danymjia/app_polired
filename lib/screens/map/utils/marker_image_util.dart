import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../models/poi_model.dart';

class MarkerImageUtil {
  static Future<ui.Image?> _loadImage(String assetPath) async {
    try {
      final data = await rootBundle.load(assetPath);
      final list = data.buffer.asUint8List();
      final codec = await ui.instantiateImageCodec(list, targetWidth: 100, targetHeight: 100);
      final frame = await codec.getNextFrame();
      return frame.image;
    } catch (e) {
      return null;
    }
  }

  static Future<Uint8List> generatePoiMarker(PoiModel poi, {double size = 56}) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    
    // Dejar un poco de margen para el badge si existe
    final double padding = poi.buildingNumber != null ? size * 0.15 : 0;
    final double imageSize = size - padding;
    final Rect imageRect = Rect.fromLTWH(0, padding, imageSize, imageSize);
    
    // Fondo base del marcador (sombra y borde)
    final RRect rrect = RRect.fromRectAndRadius(imageRect, Radius.circular(imageSize * 0.3));
    
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
    canvas.drawRRect(rrect.shift(const Offset(0, 2)), shadowPaint);
    
    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawRRect(rrect.inflate(2), borderPaint);

    ui.Image? image;
    if (poi.photoAssets.isNotEmpty) {
      image = await _loadImage(poi.photoAssets.first);
    }

    if (image != null) {
      // Dibujar imagen recortada
      canvas.save();
      canvas.clipRRect(rrect);
      
      // Calculate aspect ratio to fill the rect (cover)
      final double srcWidth = image.width.toDouble();
      final double srcHeight = image.height.toDouble();
      final double destWidth = imageRect.width;
      final double destHeight = imageRect.height;
      
      final double scaleX = destWidth / srcWidth;
      final double scaleY = destHeight / srcHeight;
      final double scale = scaleX > scaleY ? scaleX : scaleY;
      
      final double scaledWidth = srcWidth * scale;
      final double scaledHeight = srcHeight * scale;
      
      final Rect srcRect = Rect.fromLTWH(
        (srcWidth - destWidth / scale) / 2,
        (srcHeight - destHeight / scale) / 2,
        destWidth / scale,
        destHeight / scale,
      );
      
      canvas.drawImageRect(image, srcRect, imageRect, Paint());
      canvas.restore();
    } else {
      // Dibujar fallback
      final fallbackBgPaint = Paint()
        ..color = const Color(0xFF1D3557)
        ..style = PaintingStyle.fill;
      canvas.drawRRect(rrect, fallbackBgPaint);
      
      final iconData = poi.category.iconData;
      final textPainter = TextPainter(textDirection: TextDirection.ltr);
      textPainter.text = TextSpan(
        text: String.fromCharCode(iconData.codePoint),
        style: TextStyle(
          fontSize: imageSize * 0.5,
          fontFamily: iconData.fontFamily,
          package: iconData.fontPackage,
          color: Colors.white,
        ),
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(
          imageRect.left + (imageRect.width - textPainter.width) / 2,
          imageRect.top + (imageRect.height - textPainter.height) / 2,
        ),
      );
    }

    // Badge eliminado de MarkerImageUtil (sólo se mostrará en el sheet)

    final picture = recorder.endRecording();
    final img = await picture.toImage(size.toInt(), size.toInt());
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
    return byteData!.buffer.asUint8List();
  }

  /// Genera un marcador especial para el campus (nivel de zoom alejado)
  static Future<Uint8List> generateCampusMarker({double size = 56}) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    
    final paint = Paint()..color = const Color(0xFF1D3557);
    canvas.drawCircle(Offset(size / 2, size / 2), size / 2, paint);
    
    final textPainter = TextPainter(textDirection: TextDirection.ltr);
    textPainter.text = TextSpan(
      text: String.fromCharCode(Icons.account_balance_rounded.codePoint),
      style: TextStyle(
        fontSize: size * 0.6,
        fontFamily: Icons.account_balance_rounded.fontFamily,
        package: Icons.account_balance_rounded.fontPackage,
        color: Colors.white,
      ),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset((size - textPainter.width) / 2, (size - textPainter.height) / 2));
    
    final picture = recorder.endRecording();
    final img = await picture.toImage(size.toInt(), size.toInt());
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
    return byteData!.buffer.asUint8List();
  }
}
