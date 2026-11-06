import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

/// Preserves the full generated image on the captured photo's pixel canvas.
Future<Uint8List> matchCapturedFormat(
  Uint8List result,
  Uint8List captured,
) async {
  Future<ui.Image> decode(Uint8List bytes) async {
    final codec = await ui.instantiateImageCodec(bytes);
    try {
      return (await codec.getNextFrame()).image;
    } finally {
      codec.dispose();
    }
  }

  final original = await decode(captured);
  ui.Image? generated;
  ui.Image? output;
  ui.Picture? picture;
  try {
    generated = await decode(result);
    if (original.width == generated.width &&
        original.height == generated.height)
      return result;
    final width = original.width.toDouble(),
        height = original.height.toDouble();
    final scale = math.min(width / generated.width, height / generated.height);
    final w = generated.width * scale, h = generated.height * scale;
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);
    canvas.drawColor(const ui.Color(0xff11101b), ui.BlendMode.src);
    canvas.drawImageRect(
      generated,
      ui.Rect.fromLTWH(
        0,
        0,
        generated.width.toDouble(),
        generated.height.toDouble(),
      ),
      ui.Rect.fromLTWH((width - w) / 2, (height - h) / 2, w, h),
      ui.Paint()..filterQuality = ui.FilterQuality.high,
    );
    picture = recorder.endRecording();
    output = await picture.toImage(original.width, original.height);
    final bytes = await output.toByteData(format: ui.ImageByteFormat.png);
    if (bytes == null) throw StateError('Result encoding failed');
    return bytes.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes);
  } finally {
    output?.dispose();
    picture?.dispose();
    generated?.dispose();
    original.dispose();
  }
}
