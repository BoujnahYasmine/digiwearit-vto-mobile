import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:digiwearit2/face_smoothing_mask.dart';

void main() {
  final outline = [
    const Offset(160, 160),
    const Offset(560, 160),
    const Offset(560, 560),
    const Offset(160, 560),
  ];
  test('Skin mask excludes background and facial features', () {
    final mask = faceSkinMask(
      const Rect.fromLTWH(160, 160, 400, 400),
      outline,
      [
        [const Offset(240, 380), const Offset(272, 412)],
      ],
    );
    expect(mask.contains(const Offset(10, 10)), isFalse);
    expect(mask.contains(const Offset(360, 540)), isFalse);
    expect(mask.contains(const Offset(256, 396)), isFalse);
    expect(mask.contains(const Offset(464, 396)), isTrue);
    expect(mask.contains(const Offset(360, 240)), isTrue);
    expect(faceSkinMask(Rect.zero, [], []).getBounds().isEmpty, isTrue);
  });
  testWidgets(
    'Saved photo softens skin pixels but preserves pixels outside the mask',
    (tester) async {
      await tester.runAsync(() async {
        final recorder = ui.PictureRecorder();
        final canvas = Canvas(recorder);
        for (var x = 0; x < 720; x++) {
          canvas.drawRect(
            Rect.fromLTWH(x.toDouble(), 0, 1, 720),
            Paint()..color = x.isEven ? Colors.black : Colors.white,
          );
        }
        final picture = recorder.endRecording();
        final original = await picture.toImage(720, 720);
        picture.dispose();
        final png = (await original.toByteData(
          format: ui.ImageByteFormat.png,
        ))!.buffer.asUint8List();
        final mask = faceSkinMask(
          const Rect.fromLTWH(160, 160, 400, 400),
          outline,
          [],
        );
        expect(await smoothCapturedImage(png, Path(), .7), same(png));
        expect(await smoothCapturedImage(png, mask, 0), same(png));
        final output = await smoothCapturedImage(png, mask, .7);
        final codec = await ui.instantiateImageCodec(output);
        final image = (await codec.getNextFrame()).image;
        codec.dispose();
        expect(image.width, 720);
        expect(image.height, 720);
        final pixels = (await image.toByteData(
          format: ui.ImageByteFormat.rawRgba,
        ))!;
        expect(pixels.getUint8((10 * 720 + 10) * 4), 0);
        expect(pixels.getUint8((10 * 720 + 11) * 4), 255);
        final skin = pixels.getUint8((396 * 720 + 464) * 4);
        expect(skin, greaterThan(0));
        expect(skin, lessThan(255));
        image.dispose();
        original.dispose();
      });
    },
  );
}
