import 'dart:typed_data';

import 'package:digiwearit2/beauty_filter.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as image;

void main() {
  test('captured photo gets the same light as the live preview layer', () {
    const a = BeautyFilter.overlay;
    int blend(num channel, double light) =>
        (channel * (1 - a.a) + light * 255 * a.a).round();
    for (final (r, g, b) in [(0, 0, 0), (200, 120, 100)]) {
      final source = image.Image(width: 16, height: 16);
      for (final p in source) {
        p
          ..r = r
          ..g = g
          ..b = b;
      }
      final bytes = BeautyFilter.apply(
        Uint8List.fromList(image.encodePng(source)),
      );
      // Camera photos always leave the filter as compact JPEG.
      expect(image.findFormatForData(bytes), image.ImageFormat.jpg);
      final pixel = image.decodeImage(bytes)!.getPixel(8, 8);
      expect(pixel.r, closeTo(blend(r, a.r), 3));
      expect(pixel.g, closeTo(blend(g, a.g), 3));
      expect(pixel.b, closeTo(blend(b, a.b), 3));
    }
  });
}
