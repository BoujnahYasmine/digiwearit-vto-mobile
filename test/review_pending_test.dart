import 'dart:async';
import 'package:digiwearit2/capture_processing.dart';
import 'package:digiwearit2/mobile_layout.dart';
import 'package:digiwearit2/photo_review_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'fixtures.dart';

void main() {
  testWidgets('review opens on the raw photo and continues once prepared', (
    tester,
  ) async {
    viewport(tester, const Size(390, 844));
    final bytes = await photo(tester);
    final ready = Completer<ProcessedCapture>();
    var continued = 0;
    await tester.pumpWidget(
      app(
        PhotoReviewScreen(
          bytes: bytes,
          pending: ready.future,
          previewMirrored: true,
          onContinue: (_, _) async => continued++,
        ),
      ),
    );
    await tester.pump();
    expect(find.byKey(const ValueKey('review-photo')), findsOneWidget);
    DigiButton button() =>
        tester.widget<DigiButton>(find.byKey(const ValueKey('photo-continue')));
    expect(button().onPressed, isNull);
    expect(button().label, contains('Continuer'));

    ready.complete((bytes: bytes, check: (lighting: null, quality: null)));
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 300)),
    );
    await tester.pump();
    expect(button().onPressed, isNotNull);
    await tester.tap(find.byKey(const ValueKey('photo-continue')));
    await tester.pump();
    expect(continued, 1);
    expect(find.text('…'), findsNothing);
  });
}
