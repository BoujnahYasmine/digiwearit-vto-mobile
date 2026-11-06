import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as image;
import 'package:digiwearit2/camera_service.dart';
import 'package:digiwearit2/image_orientation_normalizer.dart';

const colors = [
  [240, 20, 20],
  [20, 240, 20],
  [20, 20, 240],
  [240, 240, 20],
];
const corners = {
  1: [0, 1, 2, 3],
  2: [1, 0, 3, 2],
  3: [3, 2, 1, 0],
  4: [2, 3, 0, 1],
  5: [0, 2, 1, 3],
  6: [2, 0, 3, 1],
  7: [3, 1, 2, 0],
  8: [1, 3, 0, 2],
};

Uint8List exifPhoto(int orientation) {
  final raw = image.Image(width: 80, height: 40);
  for (final pixel in raw) {
    final c = colors[(pixel.y < 20 ? 0 : 2) + (pixel.x < 40 ? 0 : 1)];
    pixel.setRgb(c[0], c[1], c[2]);
  }
  raw.exif.imageIfd.orientation = orientation;
  return Uint8List.fromList(image.encodeJpg(raw, quality: 100));
}

void expectOrientation(Uint8List bytes, int orientation) {
  // Inspect the encoded header as well as decoded pixels, so the test cannot
  // pass merely because a display decoder honors a leftover EXIF tag.
  final info = image.JpegDecoder().startDecode(bytes)!;
  final swapped = orientation >= 5;
  expect(info.width, swapped ? 40 : 80);
  expect(info.height, swapped ? 80 : 40);
  expect(image.decodeJpgExif(bytes)?.imageIfd.hasOrientation ?? false, isFalse);
  final decoded = image.decodeJpg(bytes)!;
  final points = [
    [decoded.width ~/ 4, decoded.height ~/ 4],
    [decoded.width * 3 ~/ 4, decoded.height ~/ 4],
    [decoded.width ~/ 4, decoded.height * 3 ~/ 4],
    [decoded.width * 3 ~/ 4, decoded.height * 3 ~/ 4],
  ];
  for (var i = 0; i < points.length; i++) {
    final actual = decoded.getPixel(points[i][0], points[i][1]);
    final expected = colors[corners[orientation]![i]];
    expect(actual.r, closeTo(expected[0], 12));
    expect(actual.g, closeTo(expected[1], 12));
    expect(actual.b, closeTo(expected[2], 12));
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  for (var orientation = 1; orientation <= 8; orientation++) {
    test('EXIF $orientation preserves dimensions and every corner', () {
      final bytes = const ImageOrientationNormalizer().normalize(
        exifPhoto(orientation),
      );
      expectOrientation(bytes, orientation);
      expectOrientation(
        const ImageOrientationNormalizer().normalize(bytes),
        orientation,
      );
    });
    test(
      'camera/gallery file EXIF $orientation is normalized before use',
      () async {
        final file = XFile.fromData(
          exifPhoto(orientation),
          mimeType: 'image/jpeg',
        );
        final bytes = await CameraService().normalizedBytes(file);
        expectOrientation(bytes, orientation);
      },
    );
  }

  test('upright portrait PNG retains dimensions and alpha', () async {
    final raw = image.Image(width: 40, height: 80, numChannels: 4);
    raw.setPixelRgba(10, 20, 10, 20, 30, 128);
    final normalized = await const ImageOrientationNormalizer()
        .normalizeForUpload(Uint8List.fromList(image.encodePng(raw)));
    final decoded = image.decodePng(normalized)!;
    expect(decoded.width, 40);
    expect(decoded.height, 80);
    expect(decoded.getPixel(10, 20).a, 128);
    expect(decoded.getPixel(0, 0).a, 0);
  });

  test('invalid input is rejected instead of uploading raw bytes', () async {
    await expectLater(
      const ImageOrientationNormalizer().normalizeForUpload(
        Uint8List.fromList([1, 2, 3]),
      ),
      throwsFormatException,
    );
  });
}
