import 'dart:ui';

import 'package:digiwearit2/face_smoothing_mask.dart';
import 'package:flutter_test/flutter_test.dart';

MakeupShapes? shapes({
  bool foundation = true,
  bool color = true,
}) => makeupShapes(
  bounds: const Rect.fromLTWH(0, 0, 200, 260),
  outline: const [
    Offset(100, 0),
    Offset(200, 80),
    Offset(190, 200),
    Offset(100, 260),
    Offset(10, 200),
    Offset(0, 80),
  ],
  eyesAndBrows: const [
    [Offset(50, 100), Offset(80, 95), Offset(80, 110)],
    [Offset(120, 95), Offset(150, 100), Offset(120, 110)],
  ],
  // Contours given in mixed orders, as detectors may report them.
  upperLipTop: const [Offset(60, 190), Offset(100, 180), Offset(140, 190)],
  upperLipBottom: const [Offset(140, 198), Offset(100, 196), Offset(60, 198)],
  lowerLipTop: const [Offset(60, 198), Offset(100, 202), Offset(140, 198)],
  lowerLipBottom: const [Offset(140, 200), Offset(100, 215), Offset(60, 200)],
  foundation: foundation,
  color: color,
);

void main() {
  test('foundation covers the skin but leaves eyes and lips bare', () {
    final skin = shapes()!.skin;
    expect(skin.contains(const Offset(100, 60)), isTrue); // forehead
    expect(skin.contains(const Offset(50, 160)), isTrue); // cheek
    expect(skin.contains(const Offset(65, 102)), isFalse); // eye
    expect(skin.contains(const Offset(100, 185)), isFalse); // lips
    expect(skin.contains(const Offset(5, 10)), isFalse); // outside face
  });

  test('lipstick covers the lips but not the open mouth or the chin', () {
    final lips = shapes()!.lips;
    expect(lips.contains(const Offset(100, 185)), isTrue);
    expect(lips.contains(const Offset(100, 208)), isTrue);
    expect(lips.contains(const Offset(100, 199)), isFalse);
    expect(lips.contains(const Offset(100, 230)), isFalse);
  });

  test('blush sits on both cheeks, away from the nose', () {
    final cheeks = shapes()!.cheeks;
    expect(cheeks.contains(const Offset(54, 166)), isTrue);
    expect(cheeks.contains(const Offset(146, 166)), isTrue);
    expect(cheeks.contains(const Offset(100, 166)), isFalse);
  });

  test('without color (homme) only the foundation remains', () {
    final plain = shapes(color: false)!;
    expect(plain.lips.getBounds().isEmpty, isTrue);
    expect(plain.cheeks.getBounds().isEmpty, isTrue);
    expect(plain.skin.contains(const Offset(50, 160)), isTrue);
  });

  test('missing lip contours give no makeup', () {
    expect(
      makeupShapes(
        bounds: const Rect.fromLTWH(0, 0, 200, 260),
        outline: const [],
        eyesAndBrows: const [],
        upperLipTop: const [],
        upperLipBottom: const [],
        lowerLipTop: const [],
        lowerLipBottom: const [],
      ),
      isNull,
    );
  });
}
