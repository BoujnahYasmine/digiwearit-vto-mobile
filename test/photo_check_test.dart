import 'dart:typed_data';

import 'package:digiwearit2/photo_check.dart';
import 'package:digiwearit2/photo_review_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as image;

import 'fixtures.dart';

/// A 120x200 photo: [person] brightness in the middle, [background] around.
Uint8List scene(int background, int person) {
  final photo = image.Image(width: 120, height: 200);
  for (final p in photo) {
    final middle = p.x >= 36 && p.x < 84 && p.y >= 50 && p.y < 150;
    final v = middle ? person : background;
    p
      ..r = v
      ..g = v
      ..b = v;
  }
  return Uint8List.fromList(image.encodePng(photo));
}

/// A detailed photo (fine checkerboard), optionally blurred.
Uint8List textured(int width, int height, {int blur = 0}) {
  var photo = image.Image(width: width, height: height);
  for (final p in photo) {
    final v = ((p.x ~/ 12) + (p.y ~/ 12)).isEven ? 70 : 190;
    p
      ..r = v
      ..g = v
      ..b = v;
  }
  if (blur > 0) photo = image.gaussianBlur(photo, radius: blur);
  return Uint8List.fromList(image.encodeJpg(photo, quality: 92));
}

void main() {
  test('a well lit customer passes', () {
    expect(assessPhotoLighting(scene(120, 140)), isNull);
  });

  test('a dark room is reported', () {
    expect(assessPhotoLighting(scene(30, 40)), LightingIssue.tooDark);
  });

  test('a window behind the customer is reported as backlight', () {
    expect(assessPhotoLighting(scene(235, 70)), LightingIssue.backlit);
  });

  test('a burnt-out photo is reported as too bright', () {
    expect(assessPhotoLighting(scene(250, 250)), LightingIssue.tooBright);
  });

  test('a sharp 1080p photo passes the camera-quality check', () {
    expect(checkPhoto(textured(1080, 1920)).quality, isNull);
  });

  test('a blurred photo is reported', () {
    expect(
      checkPhoto(textured(1080, 1920, blur: 24)).quality,
      CameraQualityIssue.blurry,
    );
  });

  test('a camera below 720p is reported as low quality', () {
    expect(
      checkPhoto(textured(480, 640)).quality,
      CameraQualityIssue.lowResolution,
    );
  });

  test('an unreadable photo is not judged', () {
    expect(assessPhotoLighting(Uint8List.fromList([1, 2, 3])), isNull);
  });

  testWidgets('review screen shows the advice but still allows continuing', (
    tester,
  ) async {
    final bytes = await photo(tester);
    await tester.pumpWidget(
      app(
        PhotoReviewScreen(
          bytes: bytes,
          check: (
            lighting: LightingIssue.backlit,
            quality: CameraQualityIssue.blurry,
          ),
          onContinue: (_, _) async {},
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('photo-lighting-warning')),
      findsOneWidget,
    );
    expect(find.textContaining('Contre-jour'), findsOneWidget);
    expect(find.byKey(const ValueKey('photo-quality-warning')), findsOneWidget);
    expect(find.textContaining('Photo floue'), findsOneWidget);
    expect(find.byKey(const ValueKey('photo-continue')), findsOneWidget);
  });
}
