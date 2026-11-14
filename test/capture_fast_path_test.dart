import 'dart:typed_data';

import 'package:digiwearit2/capture_processing.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as image;

void main() {
  test('large stills are shrunk to maxPhotoSide in the preparation pass', () {
    final big = image.Image(width: 3000, height: 4000);
    final bytes = prepareStill((
      bytes: Uint8List.fromList(image.encodeJpg(big)),
      flip: true,
    ));
    final out = image.decodeJpg(bytes)!;
    expect(out.height, maxPhotoSide);
    expect(out.width, 1500);
  });

  test('retouched raw pixels become the review photo without a decode', () {
    const w = 640, h = 960;
    final rgba = Uint8List(w * h * 4);
    for (var i = 0; i < rgba.length; i += 4) {
      rgba
        ..[i] = 120
        ..[i + 1] = 110
        ..[i + 2] = 100
        ..[i + 3] = 255;
    }
    final shot = processRawCapture((
      rgba: rgba,
      width: w,
      height: h,
      eclat: false,
    ));
    final out = image.decodeJpg(shot.bytes)!;
    expect((out.width, out.height), (w, h));
    expect((out.getPixel(10, 10).r - 120).abs(), lessThan(4));
  });
}
