import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as image;

/// Lighting problems that spoil a try-on photo.
enum LightingIssue { tooDark, tooBright, backlit }

/// Brightness of a picture, from 0 (black) to 255 (white): the whole frame,
/// its middle (where the customer stands), its edges, and the share of
/// burnt-out pixels.
typedef LumaStats = ({
  double mean,
  double center,
  double border,
  double clipped,
});

/// Shared rule for the live camera and the taken photo. Darkness first, then
/// backlight (customer much darker than a bright background), then glare.
LightingIssue? assessLuma(LumaStats stats) {
  if (stats.mean < 60) return LightingIssue.tooDark;
  if (stats.border > 140 && stats.center < stats.border * .6) {
    return LightingIssue.backlit;
  }
  if (stats.mean > 215 || stats.clipped > .25) return LightingIssue.tooBright;
  return null;
}

/// Measures [luma] (one value per sample, row by row) on a [width] grid.
/// The middle is the central 40 % square, which stays centered whatever the
/// sensor rotation; the edges are the outer 15 % on every side.
LumaStats lumaStats(int width, int height, int Function(int x, int y) luma) {
  var total = 0.0, centerSum = 0.0, borderSum = 0.0;
  var count = 0, centerCount = 0, borderCount = 0, clipped = 0;
  for (var y = 0; y < height; y++) {
    final fy = y / height;
    for (var x = 0; x < width; x++) {
      final fx = x / width;
      final value = luma(x, y);
      total += value;
      count++;
      if (value >= 245) clipped++;
      if (fx >= .3 && fx < .7 && fy >= .3 && fy < .7) {
        centerSum += value;
        centerCount++;
      } else if (fx < .15 || fx >= .85 || fy < .15 || fy >= .85) {
        borderSum += value;
        borderCount++;
      }
    }
  }
  double average(double sum, int n) => n == 0 ? 0 : sum / n;
  return (
    mean: average(total, count),
    center: average(centerSum, centerCount),
    border: average(borderSum, borderCount),
    clipped: count == 0 ? 0 : clipped / count,
  );
}

/// Camera-quality problems that spoil a try-on photo.
enum CameraQualityIssue { lowResolution, blurry }

/// Result of the automatic check of a taken photo.
typedef PhotoCheck = ({LightingIssue? lighting, CameraQualityIssue? quality});

/// Below this short side (720p) faces and fabrics lose too much detail.
const minimumShortSide = 700;

/// Sharpness under which a photo reads as blurred (customer moved or the
/// camera did not focus). Conservative so normal photos are never flagged.
const blurThreshold = 12.0;

/// Checks a taken photo (JPEG/PNG, before any beauty filter) for light and
/// camera quality; pure, for compute. An unreadable photo is not judged.
PhotoCheck checkPhoto(Uint8List bytes) {
  image.Image? decoded;
  try {
    decoded = image.decodeImage(bytes);
  } catch (_) {
    decoded = null;
  }
  if (decoded == null) return (lighting: null, quality: null);
  return (lighting: _lighting(decoded), quality: _quality(decoded));
}

LightingIssue? assessPhotoLighting(Uint8List bytes) =>
    checkPhoto(bytes).lighting;

LightingIssue? _lighting(image.Image photo) {
  final small = image.copyResize(photo, width: 96);
  return assessLuma(
    lumaStats(small.width, small.height, (x, y) {
      final p = small.getPixel(x, y);
      return (p.r * .299 + p.g * .587 + p.b * .114).round();
    }),
  );
}

CameraQualityIssue? _quality(image.Image photo) {
  final shortSide = photo.width < photo.height ? photo.width : photo.height;
  if (shortSide < minimumShortSide) return CameraQualityIssue.lowResolution;
  final score = sharpness(photo);
  // Logged while testing to tune [blurThreshold] on real photos.
  if (kDebugMode) {
    debugPrint(
      "Digiwearit photo quality: ${photo.width}x${photo.height}, "
      "sharpness ${score.toStringAsFixed(1)}",
    );
  }
  return score < blurThreshold ? CameraQualityIssue.blurry : null;
}

/// Variance of the Laplacian (edge strength) over the middle of the photo,
/// where the customer stands, at a fixed 256 px width so every camera is
/// judged alike. Low values mean no crisp edges, i.e. a blurred photo.
double sharpness(image.Image photo) {
  final small = image.grayscale(image.copyResize(photo, width: 256));
  int luma(int x, int y) => small.getPixel(x, y).r.toInt();
  var sum = 0.0, squares = 0.0;
  var count = 0;
  final x0 = (small.width * .2).round(), x1 = (small.width * .8).round();
  final y0 = (small.height * .1).round(), y1 = (small.height * .9).round();
  for (var y = y0 + 1; y < y1 - 1; y++) {
    for (var x = x0 + 1; x < x1 - 1; x++) {
      final edge =
          luma(x - 1, y) +
          luma(x + 1, y) +
          luma(x, y - 1) +
          luma(x, y + 1) -
          4 * luma(x, y);
      sum += edge;
      squares += edge * edge;
      count++;
    }
  }
  if (count == 0) return 0;
  final mean = sum / count;
  return squares / count - mean * mean;
}

/// Short advice shown to the customer for a lighting [issue].
String lightingAdvice(
  LightingIssue issue, {
  required bool english,
}) => switch (issue) {
  LightingIssue.tooDark =>
    english
        ? '💡 Low light: face a window or a lamp.'
        : '💡 Lumière faible : placez-vous face à une fenêtre ou une lampe.',
  LightingIssue.tooBright =>
    english
        ? '☀️ Too much light: avoid direct sun or a spotlight on you.'
        : '☀️ Trop de lumière : évitez le soleil ou un spot directement sur vous.',
  LightingIssue.backlit =>
    english
        ? '🪟 Backlit: don’t stand with a window behind you, face the light.'
        : '🪟 Contre-jour : ne restez pas dos à une fenêtre, mettez-vous face à la lumière.',
};

/// Short advice shown to the customer for a camera-quality [issue].
String qualityAdvice(
  CameraQualityIssue issue, {
  required bool english,
}) => switch (issue) {
  CameraQualityIssue.blurry =>
    english
        ? '📷 Blurry photo: hold still during the countdown and clean the lens.'
        : '📷 Photo floue : restez immobile pendant le compte à rebours et nettoyez l’objectif.',
  CameraQualityIssue.lowResolution =>
    english
        ? '📷 Low camera quality: the try-on will be less precise.'
        : '📷 Qualité de caméra faible : l’essayage sera moins précis.',
};

/// Amber tip shown on the camera and review screens.
class PhotoTip extends StatelessWidget {
  const PhotoTip(this.message, {super.key});
  final String message;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
    decoration: BoxDecoration(
      color: const Color(0xeefff1d6),
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: const Color(0xfff0b860)),
    ),
    child: Text(
      message,
      textAlign: TextAlign.center,
      maxLines: 3,
      style: const TextStyle(
        color: Color(0xff5a3a00),
        fontSize: 12.5,
        fontWeight: FontWeight.w600,
      ),
    ),
  );
}
