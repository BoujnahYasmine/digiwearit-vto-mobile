import 'dart:typed_data';

import 'package:digiwearit2/result_photo.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as image;

import 'fixtures.dart';

void main() {
  for (final example in [
    (
      name: 'portrait is shown whole',
      width: 90,
      height: 160,
      fit: BoxFit.contain,
    ),
    (
      name: 'landscape stays landscape',
      width: 160,
      height: 90,
      fit: BoxFit.contain,
    ),
    (
      name: 'very tall portrait is not severely cropped',
      width: 40,
      height: 200,
      fit: BoxFit.contain,
    ),
  ]) {
    testWidgets(example.name, (tester) async {
      viewport(tester, const Size(390, 844));
      final bytes = Uint8List.fromList(
        image.encodePng(
          image.Image(width: example.width, height: example.height),
        ),
      );
      await tester.pumpWidget(app(Scaffold(body: ResultPhoto(bytes: bytes))));
      await tester.runAsync(
        () => precacheImage(
          MemoryImage(bytes),
          tester.element(find.byType(ResultPhoto)),
        ),
      );
      await tester.pumpAndSettle();
      final foreground = find.byKey(const ValueKey('result-photo'));
      expect(tester.widget<Image>(foreground).fit, example.fit);
      expect(tester.getSize(foreground), const Size(390, 844));
      expect(find.byType(ImageFiltered), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('changing result uses the new image aspect ratio', (
    tester,
  ) async {
    viewport(tester, const Size(390, 844));
    for (final size in [const Size(90, 160), const Size(160, 90)]) {
      final bytes = Uint8List.fromList(
        image.encodePng(
          image.Image(width: size.width.toInt(), height: size.height.toInt()),
        ),
      );
      await tester.pumpWidget(app(Scaffold(body: ResultPhoto(bytes: bytes))));
      await tester.runAsync(
        () => precacheImage(
          MemoryImage(bytes),
          tester.element(find.byType(ResultPhoto)),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        tester.widget<Image>(find.byKey(const ValueKey('result-photo'))).fit,
        BoxFit.contain,
      );
    }
  });
}
