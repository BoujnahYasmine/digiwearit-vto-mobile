@TestOn('browser')
library;

import 'dart:js_interop';

import 'package:digiwearit2/image_orientation_browser.dart';
import 'package:digiwearit2/image_orientation_normalizer.dart';
import 'package:flutter_test/flutter_test.dart';

import 'image_orientation_normalizer_test.dart'
    show exifPhoto, expectOrientation;

@JS('window.createImageBitmap')
external JSFunction? get createImageBitmap;

@JS('window.createImageBitmap')
external set createImageBitmap(JSFunction? value);

void main() {
  test('browser bitmap/canvas applies EXIF itself', () async {
    for (var orientation = 1; orientation <= 8; orientation++) {
      final bytes = await normalizeWithBitmap(exifPhoto(orientation));
      expect(bytes, isNotNull, reason: 'Chrome must exercise the bitmap path');
      expectOrientation(bytes!, orientation);
    }
  });

  test('missing createImageBitmap uses EXIF-aware fallback', () async {
    final original = createImageBitmap;
    try {
      createImageBitmap = null;
      final bytes = await const ImageOrientationNormalizer().normalizeForUpload(
        exifPhoto(6),
      );
      expectOrientation(bytes, 6);
    } finally {
      createImageBitmap = original;
    }
  });
}
