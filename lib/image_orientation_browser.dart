import 'dart:async';
import 'dart:js_interop';

import 'package:flutter/foundation.dart';
import 'package:web/web.dart' as web;

/// A null result selects the EXIF-aware Dart decoder on older browsers.
Future<Uint8List?> normalizeWithBitmap(Uint8List source) async {
  web.ImageBitmap? bitmap;
  try {
    final blob = web.Blob([source.toJS].toJS);
    bitmap = await web.window
        .createImageBitmap(
          blob,
          web.ImageBitmapOptions(imageOrientation: 'from-image'),
        )
        .toDart;
    final canvas = web.HTMLCanvasElement()
      ..width = bitmap.width
      ..height = bitmap.height;
    if (canvas.width == 0 || canvas.height == 0) {
      throw const FormatException('Empty image');
    }
    // Bitmap dimensions are oriented pixel dimensions, never CSS dimensions.
    final context = canvas.getContext('2d') as web.CanvasRenderingContext2D;
    context.drawImage(bitmap, 0, 0);
    final png =
        source.length >= 4 &&
        source[0] == 0x89 &&
        source[1] == 0x50 &&
        source[2] == 0x4e &&
        source[3] == 0x47;
    final encoded = Completer<web.Blob?>();
    canvas.toBlob(
      ((web.Blob? result) => encoded.complete(result)).toJS,
      png ? 'image/png' : 'image/jpeg',
      0.92.toJS,
    );
    final result = await encoded.future;
    if (result == null) throw const FormatException('Could not encode image');
    if (kDebugMode) {
      debugPrint(
        'Digiwearit normalized pixels: ${canvas.width}x${canvas.height} (bitmap)',
      );
    }
    return (await result.arrayBuffer().toDart).toDart.asUint8List();
  } catch (_) {
    // Missing createImageBitmap, unsupported options, or a browser codec error.
    // Never return the unnormalized source as a fallback.
    return null;
  } finally {
    bitmap?.close();
  }
}
