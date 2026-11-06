import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter_test/flutter_test.dart';
import 'package:digiwearit2/mirror/mirror_image_format.dart';

Future<Uint8List> photo(int w, int h) async {
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder);
  canvas.drawColor(const ui.Color(0xffff0000), ui.BlendMode.src);
  final picture = recorder.endRecording();
  final image = await picture.toImage(w, h);
  final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
  image.dispose();
  picture.dispose();
  return bytes!.buffer.asUint8List();
}

void main() {
  testWidgets(
    'result preserves capture dimensions and fits without stretching',
    (tester) async {
      await tester.runAsync(() async {
        for (final size in [(120, 80), (80, 120)]) {
          final result = await matchCapturedFormat(
            await photo(40, 40),
            await photo(size.$1, size.$2),
          );
          final codec = await ui.instantiateImageCodec(result);
          final image = (await codec.getNextFrame()).image;
          expect(image.width, size.$1);
          expect(image.height, size.$2);
          final pixels = (await image.toByteData())!.buffer.asUint8List();
          // Square content remains square, with padding along the longer axis.
          final edge = 4 * ((size.$2 ~/ 2) * size.$1);
          expect(pixels[edge], size.$1 > size.$2 ? 17 : 255);
          image.dispose();
          codec.dispose();
        }
      });
    },
  );
}
