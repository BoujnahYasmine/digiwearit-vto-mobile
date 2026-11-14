import 'dart:typed_data';

import 'package:digiwearit2/beauty_filter.dart';
import 'package:digiwearit2/capture_processing.dart';
import 'package:digiwearit2/image_orientation_normalizer.dart';
import 'package:digiwearit2/photo_check.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as image;

Uint8List photo(int width, int height) {
  final picture = image.Image(width: width, height: height);
  for (final p in picture) {
    // Left half dark, right half light, with texture: flips are visible.
    final light = p.x > width ~/ 2 ? 180 : 60;
    p
      ..r = (light + (p.x * 7 + p.y * 3) % 40).clamp(0, 255)
      ..g = (light + (p.y * 5) % 30).clamp(0, 255)
      ..b = light;
  }
  return Uint8List.fromList(image.encodeJpg(picture, quality: 95));
}

void main() {
  test('one pass gives the same photo and check as the old step-by-step '
      'pipeline, and is faster', () {
    final raw = photo(1080, 1920);

    final oldWatch = Stopwatch()..start();
    final upright = const ImageOrientationNormalizer().normalize(raw);
    final unmirrored = const ImageOrientationNormalizer().flipHorizontal(
      upright,
    );
    final oldCheck = checkPhoto(unmirrored);
    final oldBytes = BeautyFilter.apply(unmirrored);
    oldWatch.stop();

    final newWatch = Stopwatch()..start();
    final shot = processCapture((bytes: raw, flip: true, eclat: true));
    newWatch.stop();

    expect(shot.check, oldCheck);
    final a = image.decodeJpg(oldBytes)!, b = image.decodeJpg(shot.bytes)!;
    expect((b.width, b.height), (a.width, a.height));
    // The flip happened: the dark half is now on the right.
    expect(b.getPixel(50, 960).r, greaterThan(b.getPixel(1030, 960).r));
    // Same colours (JPEG re-encoding differs by a few levels only; the old
    // pipeline encoded three times).
    for (final (x, y) in [(100, 100), (540, 960), (1000, 1800)]) {
      expect((b.getPixel(x, y).r - a.getPixel(x, y).r).abs(), lessThan(12));
    }
    // ignore: avoid_print
    print(
      'old pipeline ${oldWatch.elapsedMilliseconds} ms, '
      'one pass ${newWatch.elapsedMilliseconds} ms',
    );
    expect(newWatch.elapsed, lessThan(oldWatch.elapsed));
  });

  test('without Éclat and flip the photo is only straightened', () {
    final raw = photo(720, 1280);
    final shot = processCapture((bytes: raw, flip: false, eclat: false));
    final b = image.decodeJpg(shot.bytes)!;
    expect(b.getPixel(50, 640).r, lessThan(b.getPixel(700, 640).r));
  });

  test('an unreadable still is an error, not a blank photo', () {
    expect(
      () => processCapture((
        bytes: Uint8List.fromList([1, 2, 3]),
        flip: false,
        eclat: true,
      )),
      throwsFormatException,
    );
  });
}
