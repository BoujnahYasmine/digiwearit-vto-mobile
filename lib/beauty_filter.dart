import 'dart:typed_data';

import 'package:flutter/widgets.dart';
import 'package:image/image.dart' as image;

/// "Éclat": a soft, warm light over the camera that brightens the face,
/// evens out contrast and warms the skin. The live preview shows it as a
/// translucent layer (works over native and web camera views alike) and
/// [apply] blends the captured pixels with exactly the same color, so the
/// photo sent to the try-on looks like the preview.
abstract final class BeautyFilter {
  static const _lightR = 255, _lightG = 228, _lightB = 210;
  static const _strength = .16;
  static const overlay = Color.fromRGBO(255, 228, 210, _strength);

  /// Live-preview layer, placed over the camera image.
  static Widget layer() =>
      const IgnorePointer(child: ColoredBox(color: overlay));

  /// Blends an upright JPEG/PNG with the [overlay] light and returns a JPEG;
  /// pure, for compute.
  static Uint8List apply(Uint8List source) {
    final decoded = image.decodeImage(source);
    if (decoded == null) throw const FormatException('Unsupported image data');
    const keep = 1 - _strength;
    const r = _lightR * _strength;
    const g = _lightG * _strength;
    const b = _lightB * _strength;
    for (final pixel in decoded) {
      pixel
        ..r = (pixel.r * keep + r).round().clamp(0, 255)
        ..g = (pixel.g * keep + g).round().clamp(0, 255)
        ..b = (pixel.b * keep + b).round().clamp(0, 255);
    }
    // Always JPEG: a camera photo needs no transparency, and a 1080p PNG
    // (from the smoothing/makeup step) would be several times heavier.
    return Uint8List.fromList(image.encodeJpg(decoded, quality: 92));
  }
}
