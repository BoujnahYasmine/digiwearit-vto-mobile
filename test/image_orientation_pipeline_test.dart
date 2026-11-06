import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:digiwearit2/camera_service.dart';
import 'package:digiwearit2/digiwearit_watermark.dart';
import 'package:digiwearit2/nano_banana_service.dart';
import 'package:digiwearit2/outfit_selection.dart';
import 'package:digiwearit2/photo_review_screen.dart';
import 'package:digiwearit2/try_on_session.dart';
import 'package:firebase_ai/firebase_ai.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as image;

import 'fixtures.dart';
import 'image_orientation_normalizer_test.dart'
    show exifPhoto, expectOrientation;

void main() {
  testWidgets(
    'upright preview bytes reach AI once, then watermark and result',
    (tester) async {
      late Uint8List bytes;
      await tester.runAsync(() async {
        bytes = await CameraService().normalizedBytes(
          XFile.fromData(exifPhoto(6), mimeType: 'image/jpeg'),
        );
      });
      final selection = OutfitSelection(
        outfit: model('orientation', 'Caftan'),
        gender: 'femme',
        style: 'Marocain',
        english: true,
      );
      var generations = 0;
      var watermarks = 0;
      final service = NanoBananaService(
        imageLoader: (_) async => InlineDataPart('image/png', Uint8List(1)),
      );
      final session = TryOnSession(
        generator: (request) async {
          generations++;
          final parts = await service.buildInput(request);
          final userImage = parts.whereType<InlineDataPart>().first;
          expect(userImage.bytes, same(bytes));
          expect(userImage.mimeType, 'image/jpeg');
          expectOrientation(userImage.bytes, 6);
          return [userImage.bytes];
        },
        watermark: (generated) async {
          watermarks++;
          return DigiwearitWatermark().apply(generated);
        },
      );
      addTearDown(session.dispose);
      await tester.pumpWidget(
        app(
          PhotoReviewScreen(
            bytes: bytes,
            onContinue: (_, confirmed) async =>
                session.confirm(selection, confirmed),
          ),
        ),
      );
      final preview = tester.widget<Image>(
        find.byKey(const ValueKey('review-photo')),
      );
      expect((preview.image as MemoryImage).bytes, same(bytes));
      // Exercise confirmation with the exact bytes owned by the review screen.
      await tester
          .widget<PhotoReviewScreen>(find.byType(PhotoReviewScreen))
          .onContinue(tester.element(find.byType(PhotoReviewScreen)), bytes);
      await tester.runAsync(() async {
        await Future.wait([session.generate(), session.generate()]);
        await session.generate();
      });
      expect(session.status, TryOnStatus.completed);
      expect(generations, 1);
      expect(watermarks, 1);
      final result = image.decodePng(session.results.single)!;
      expect(result.width, 40);
      expect(result.height, 80);
    },
  );
}
