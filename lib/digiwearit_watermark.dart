import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/services.dart';

/// Adds the Digiwearit mark after AI generation, preserving image dimensions.
class DigiwearitWatermark {
  DigiwearitWatermark({Future<ByteData> Function(String key)? logoLoader})
    : logoLoader = logoLoader ?? rootBundle.load;

  final Future<ByteData> Function(String key) logoLoader;
  static const logoAsset = 'lib/logo digiwearit.png';

  Future<Uint8List> apply(Uint8List generatedImage) async {
    final sourceCodec = await ui.instantiateImageCodec(generatedImage);
    final sourceFrame = await sourceCodec.getNextFrame();
    final source = sourceFrame.image;
    ui.Image? logo;
    ui.Picture? picture;
    ui.Image? branded;
    try {
      final logoData = await logoLoader(logoAsset);
      final logoCodec = await ui.instantiateImageCodec(
        logoData.buffer.asUint8List(
          logoData.offsetInBytes,
          logoData.lengthInBytes,
        ),
      );
      final logoFrame = await logoCodec.getNextFrame();
      logo = logoFrame.image;
      logoCodec.dispose();
      final width = source.width.toDouble();
      final padding = (width * .025).clamp(4.0, 72.0);
      final watermarkWidth = (width * .13).clamp(28.0, 280.0);
      final watermarkHeight = watermarkWidth * logo.height / logo.width;
      final destination = ui.Rect.fromLTWH(
        width - watermarkWidth - padding,
        source.height - watermarkHeight - padding,
        watermarkWidth,
        watermarkHeight,
      );
      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);
      canvas.drawImage(source, ui.Offset.zero, ui.Paint());
      final backing = destination.inflate(padding * .22);
      canvas.drawRRect(
        ui.RRect.fromRectAndRadius(
          backing,
          ui.Radius.circular(backing.height / 3),
        ),
        ui.Paint()..color = const ui.Color(0x4D11101B),
      );
      canvas.drawImageRect(
        logo,
        ui.Rect.fromLTWH(0, 0, logo.width.toDouble(), logo.height.toDouble()),
        destination,
        ui.Paint()
          ..filterQuality = ui.FilterQuality.high
          ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 2),
      );
      picture = recorder.endRecording();
      branded = await picture.toImage(source.width, source.height);
      final data = await branded.toByteData(format: ui.ImageByteFormat.png);
      if (data == null) throw StateError('Could not encode branded image');
      return data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
    } finally {
      branded?.dispose();
      picture?.dispose();
      logo?.dispose();
      source.dispose();
      sourceCodec.dispose();
    }
  }
}
