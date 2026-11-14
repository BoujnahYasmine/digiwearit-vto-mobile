import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

/// Conservative cheek/forehead areas with all detected facial features excluded.
/// Coordinates use the detector's image space; callers normalize for preview.
Path faceSkinMask(
  Rect bounds,
  List<Offset> outline,
  List<List<Offset>> features,
) {
  if (outline.length < 3 || bounds.isEmpty) return Path();
  final oval = Path()..addPolygon(outline, true);
  final skin = Path();
  for (final region in const [
    Rect.fromLTWH(.12, .48, .24, .22),
    Rect.fromLTWH(.64, .48, .24, .22),
    Rect.fromLTWH(.34, .14, .32, .16),
  ]) {
    skin.addOval(
      Rect.fromLTWH(
        bounds.left + region.left * bounds.width,
        bounds.top + region.top * bounds.height,
        region.width * bounds.width,
        region.height * bounds.height,
      ),
    );
  }
  var result = Path.combine(PathOperation.intersect, skin, oval);
  for (final points in features) {
    if (points.isEmpty) continue;
    var box = Rect.fromPoints(points.first, points.first);
    for (final p in points) {
      box = box.expandToInclude(Rect.fromPoints(p, p));
    }
    result = Path.combine(
      PathOperation.difference,
      result,
      Path()..addRect(box.inflate(bounds.width * .035)),
    );
  }
  return result;
}

double smoothingSigma(double width, double strength) =>
    width / 720 * strength.clamp(0, 1) * 1.6;

Future<Uint8List> smoothCapturedImage(
  Uint8List bytes,
  Path mask,
  double strength,
) async {
  if (mask.getBounds().isEmpty || strength <= 0) return bytes;
  final codec = await ui.instantiateImageCodec(bytes);
  final frame = await codec.getNextFrame();
  codec.dispose();
  final original = frame.image;
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  canvas.drawImage(original, Offset.zero, Paint());
  canvas.save();
  canvas.clipPath(mask);
  final sigma = smoothingSigma(original.width.toDouble(), strength);
  canvas.drawImage(
    original,
    Offset.zero,
    Paint()..imageFilter = ui.ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
  );
  canvas.restore();
  final picture = recorder.endRecording();
  try {
    final output = await picture.toImage(original.width, original.height);
    try {
      final encoded = await output.toByteData(format: ui.ImageByteFormat.png);
      if (encoded == null) throw StateError('Could not encode smoothed photo');
      return encoded.buffer.asUint8List(
        encoded.offsetInBytes,
        encoded.lengthInBytes,
      );
    } finally {
      output.dispose();
    }
  } finally {
    picture.dispose();
    original.dispose();
  }
}

/// Beauty areas in the detector's image space: the face skin for a light
/// foundation (eyes, brows and lips left bare), plus — when [color] is on —
/// a soft blush oval per cheek. No lipstick: the lips keep their own color.
class MakeupShapes {
  const MakeupShapes(this.skin, this.cheeks, this.faceWidth);
  final Path skin, cheeks;
  final double faceWidth;

  /// Same affine matrix as the skin mask (normalize, mirror, scale to view).
  MakeupShapes transform(Float64List matrix) => MakeupShapes(
    skin.transform(matrix),
    cheeks.transform(matrix),
    faceWidth * matrix[0].abs(),
  );
}

MakeupShapes? makeupShapes({
  required Rect bounds,
  required List<Offset> outline,
  required List<List<Offset>> eyesAndBrows,
  required List<Offset> upperLipTop,
  required List<Offset> upperLipBottom,
  required List<Offset> lowerLipTop,
  required List<Offset> lowerLipBottom,
  Offset? leftCheek,
  Offset? rightCheek,
  bool foundation = true,
  bool color = false,
}) {
  if (bounds.isEmpty || upperLipTop.length < 3 || lowerLipBottom.length < 3) {
    return null;
  }
  // Upper edge left to right, then lower edge back, whatever order the
  // detector reports the contour points in.
  List<Offset> ring(List<Offset> top, List<Offset> bottom) => [
    ...([...top]..sort((a, b) => a.dx.compareTo(b.dx))),
    ...([...bottom]..sort((a, b) => b.dx.compareTo(a.dx))),
  ];
  final outer = Path()..addPolygon(ring(upperLipTop, lowerLipBottom), true);
  final w = bounds.width, h = bounds.height;

  var skin = Path();
  if (foundation && outline.length >= 3) {
    skin = Path()..addPolygon(outline, true);
    final bare = Path()..addPath(outer, Offset.zero);
    for (final points in eyesAndBrows) {
      if (points.isEmpty) continue;
      var box = Rect.fromPoints(points.first, points.first);
      for (final p in points) {
        box = box.expandToInclude(Rect.fromPoints(p, p));
      }
      bare.addOval(box.inflate(w * .03));
    }
    skin = Path.combine(PathOperation.difference, skin, bare);
  }

  final cheeks = Path();
  if (color) {
    for (final (point, fallback) in [
      (leftCheek, Offset(bounds.left + w * .27, bounds.top + h * .64)),
      (rightCheek, Offset(bounds.left + w * .73, bounds.top + h * .64)),
    ]) {
      cheeks.addOval(
        Rect.fromCenter(
          center: point ?? fallback,
          width: w * .24,
          height: h * .15,
        ),
      );
    }
  }
  return MakeupShapes(skin, cheeks, w);
}

const _foundation = Color(0x24F6DDCB);
const _blush = Color(0x26F2708C);

/// Paints a light foundation, then blush; shared by the
/// live preview and the photo.
void paintMakeup(Canvas canvas, MakeupShapes shapes) {
  final soft = shapes.faceWidth;
  // Soft edges so the even tone melts into the hairline, jaw and features.
  canvas.drawPath(
    shapes.skin,
    Paint()
      ..color = _foundation
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, soft * .03),
  );
  canvas.drawPath(
    shapes.cheeks,
    Paint()
      ..color = _blush
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, soft * .06),
  );
}

Future<Uint8List> applyMakeupToImage(
  Uint8List bytes,
  MakeupShapes shapes,
) async {
  final codec = await ui.instantiateImageCodec(bytes);
  final frame = await codec.getNextFrame();
  codec.dispose();
  final original = frame.image;
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  canvas.drawImage(original, Offset.zero, Paint());
  paintMakeup(canvas, shapes);
  final picture = recorder.endRecording();
  try {
    final output = await picture.toImage(original.width, original.height);
    try {
      final encoded = await output.toByteData(format: ui.ImageByteFormat.png);
      if (encoded == null) throw StateError('Could not encode makeup photo');
      return encoded.buffer.asUint8List(
        encoded.offsetInBytes,
        encoded.lengthInBytes,
      );
    } finally {
      output.dispose();
    }
  } finally {
    picture.dispose();
    original.dispose();
  }
}

/// Skin smoothing and makeup in one GPU pass, returned as raw RGBA pixels so
/// the photo is not re-encoded and decoded again before the review.
Future<({Uint8List rgba, int width, int height})> retouchPixels(
  Uint8List bytes, {
  Path? mask,
  double strength = 0,
  MakeupShapes? makeup,
}) async {
  final codec = await ui.instantiateImageCodec(bytes);
  final frame = await codec.getNextFrame();
  codec.dispose();
  final original = frame.image;
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  canvas.drawImage(original, Offset.zero, Paint());
  if (mask != null && !mask.getBounds().isEmpty && strength > 0) {
    final sigma = smoothingSigma(original.width.toDouble(), strength);
    canvas
      ..save()
      ..clipPath(mask)
      ..drawImage(
        original,
        Offset.zero,
        Paint()
          ..imageFilter = ui.ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
      )
      ..restore();
  }
  if (makeup != null) paintMakeup(canvas, makeup);
  final picture = recorder.endRecording();
  try {
    final output = await picture.toImage(original.width, original.height);
    try {
      final data = await output.toByteData(format: ui.ImageByteFormat.rawRgba);
      if (data == null) throw StateError('Could not read retouched photo');
      return (
        rgba: data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
        width: output.width,
        height: output.height,
      );
    } finally {
      output.dispose();
    }
  } finally {
    picture.dispose();
    original.dispose();
  }
}
