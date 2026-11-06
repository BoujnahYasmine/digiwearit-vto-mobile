import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as image;

import 'image_orientation_browser_stub.dart'
    if (dart.library.js_interop) 'image_orientation_browser.dart'
    as browser;

/// Applies EXIF to pixels before preview and upload; output needs no EXIF.
class ImageOrientationNormalizer {
  const ImageOrientationNormalizer();

  Future<Uint8List> normalizeForUpload(Uint8List source) async {
    if (kDebugMode) {
      try {
        final decoder = image.findDecoderForData(source);
        final info = decoder?.startDecode(source);
        debugPrint(
          'Digiwearit captured pixels: ${info?.width}x${info?.height}',
        );
      } catch (_) {
        // Diagnostics must never prevent decoding a supported browser image.
      }
    }
    final browserBytes = await browser.normalizeWithBitmap(source);
    if (browserBytes != null) return browserBytes;
    return compute(normalize, source);
  }

  /// Mirror-flips an already upright image; orientation is left untouched.
  Uint8List flipHorizontal(Uint8List source) {
    final decoded = image.decodeImage(source);
    if (decoded == null) throw const FormatException('Unsupported image data');
    final flipped = image.flipHorizontal(decoded);
    if (image.findFormatForData(source) == image.ImageFormat.png) {
      return Uint8List.fromList(image.encodePng(flipped));
    }
    return Uint8List.fromList(image.encodeJpg(flipped, quality: 92));
  }

  Uint8List normalize(Uint8List source) {
    image.Image? decoded;
    try {
      decoded = image.decodeImage(source);
    } catch (_) {
      throw const FormatException('Invalid image data');
    }
    if (decoded == null) {
      throw const FormatException('Unsupported image data');
    }
    // The JPEG decoder already applies EXIF and clears its orientation tag.
    // bakeOrientation handles tags retained by other decoders, exactly once.
    final upright = image.bakeOrientation(decoded);
    upright.exif = image.ExifData();
    if (kDebugMode) {
      debugPrint(
        'Digiwearit normalized pixels: ${upright.width}x${upright.height}',
      );
    }
    // Preserve transparency for gallery PNGs.
    if (image.findFormatForData(source) == image.ImageFormat.png) {
      return Uint8List.fromList(image.encodePng(upright));
    }
    return Uint8List.fromList(image.encodeJpg(upright, quality: 92));
  }
}
