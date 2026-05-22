import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';

String _formatBytes(int bytes) {
  if (bytes <= 0) return '0 B';
  const suffixes = ['B', 'KB', 'MB', 'GB'];
  final i = (log(bytes) / log(1024)).floor();
  final size = bytes / pow(1024, i);
  return '${size.toStringAsFixed(1)} ${suffixes[i]}';
}

Future<File?> compressImageFile(
  File inputFile, {
  required int maxWidth,
  required int maxHeight,
  required int quality,
  int targetSizeInBytes = 1024 * 1024,
  int minQuality = 60,
}) async {
  try {
    final originalBytes = await inputFile.length();
    final tempDir = await Directory.systemTemp.createTemp('polired_compress_');
    final targetPath = '${tempDir.path}/compressed_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(10000)}.jpg';

    final compressedXFile = await FlutterImageCompress.compressAndGetFile(
      inputFile.path,
      targetPath,
      quality: quality,
      minWidth: maxWidth,
      minHeight: maxHeight,
      format: CompressFormat.jpeg,
      keepExif: false,
    );

    if (compressedXFile == null) {
      debugPrint('[ImageCompression] compressAndGetFile returned null for ${inputFile.path}');
      return null;
    }

    final compressedFile = File(compressedXFile.path);
    var compressedBytes = await compressedFile.length();
    if (compressedBytes > targetSizeInBytes && quality > minQuality) {
      final lowerQuality = max(minQuality, quality - 10);
      final secondTargetPath = '${tempDir.path}/compressed_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(10000)}.jpg';
      final compressedXFile2 = await FlutterImageCompress.compressAndGetFile(
        inputFile.path,
        secondTargetPath,
        quality: lowerQuality,
        minWidth: maxWidth,
        minHeight: maxHeight,
        format: CompressFormat.jpeg,
        keepExif: false,
      );
      if (compressedXFile2 != null) {
        final compressedFile2 = File(compressedXFile2.path);
        final secondSize = await compressedFile2.length();
        if (secondSize < compressedBytes) {
          compressedBytes = secondSize;
          debugPrint('[ImageCompression] original=${_formatBytes(originalBytes)} compressed=${_formatBytes(compressedBytes)} reduction=${((1 - compressedBytes / originalBytes) * 100).toStringAsFixed(1)}% path=${compressedFile2.path}');
          return compressedFile2;
        }
      }
    }

    debugPrint('[ImageCompression] original=${_formatBytes(originalBytes)} compressed=${_formatBytes(compressedBytes)} reduction=${((1 - compressedBytes / originalBytes) * 100).toStringAsFixed(1)}% path=${compressedFile.path}');
    return compressedFile;
  } catch (e, stack) {
    debugPrint('[ImageCompression] Error compressing ${inputFile.path}: $e\n$stack');
    return null;
  }
}

Future<File?> compressPostImageFile(File file) async {
  return compressImageFile(
    file,
    maxWidth: 1080,
    maxHeight: 1080,
    quality: 75,
    targetSizeInBytes: 1024 * 1024,
    minQuality: 65,
  );
}

Future<File?> compressProfileImageFile(File file) async {
  return compressImageFile(
    file,
    maxWidth: 512,
    maxHeight: 512,
    quality: 70,
    targetSizeInBytes: 300 * 1024,
    minQuality: 60,
  );
}
