import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:digiwearit2/photo_review_screen.dart';
import 'fixtures.dart';

void main() {
  for (final size in phones) {
    for (final scale in [1.0, 2.0]) {
      testWidgets('confirmation does not scroll at $size scale $scale', (
        tester,
      ) async {
        viewport(tester, size);
        final bytes = await photo(tester);
        var continued = false;
        await tester.pumpWidget(
          app(
            PhotoReviewScreen(
              bytes: bytes,
              onContinue: (_, value) async {
                expect(value, same(bytes));
                continued = true;
              },
            ),
            scale: scale,
          ),
        );
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 100)),
        );
        await tester.pumpAndSettle();
        visible(tester, find.byKey(const ValueKey('photo-continue')));
        expect(find.byType(SingleChildScrollView), findsNothing);
        expect(find.text('Recadrer'), findsNothing);
        expect(
          tester.widget<Image>(find.byKey(const ValueKey('review-photo'))).fit,
          BoxFit.cover,
        );
        expect(
          tester.getRect(find.byKey(const ValueKey('review-photo'))),
          Offset.zero & size,
        );
        await tester.tap(find.byKey(const ValueKey('photo-continue')));
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 100)),
        );
        await tester.pumpAndSettle();
        expect(continued, isTrue);
        expect(tester.takeException(), isNull);
      });
    }
  }
}
