import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:digiwearit2/digiwearit_watermark.dart';

import 'fixtures.dart';

void main() {
  testWidgets('watermark is embedded in a same-size branded PNG', (
    tester,
  ) async {
    final original = await photo(tester);
    late Uint8List branded;
    await tester.runAsync(() async {
      branded = await DigiwearitWatermark().apply(original);
    });
    expect(branded, isNot(equals(original)));
    await tester.runAsync(() async {
      final originalCodec = await ui.instantiateImageCodec(original);
      final brandedCodec = await ui.instantiateImageCodec(branded);
      final originalFrame = await originalCodec.getNextFrame();
      final brandedFrame = await brandedCodec.getNextFrame();
      expect(brandedFrame.image.width, originalFrame.image.width);
      expect(brandedFrame.image.height, originalFrame.image.height);
      originalFrame.image.dispose();
      brandedFrame.image.dispose();
      originalCodec.dispose();
      brandedCodec.dispose();
    });
  });
}
