import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:digiwearit2/result_screen.dart';
import 'package:digiwearit2/delivery_screen.dart';
import 'fixtures.dart';

void main() {
  testWidgets('email CTA stays above keyboard without resizing the result', (
    tester,
  ) async {
    viewport(tester, const Size(320, 568));
    final bytes = await photo(tester);
    await tester.pumpWidget(
      app(
        ResultScreen(
          images: [bytes],
          outfitName: 'Caftan',
          resultId: 'keyboard',
          emailSender: (email, bytes, id) async {},
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('result-email')));
    await tester.pumpAndSettle();
    tester.view.viewInsets = const FakeViewPadding(bottom: 260);
    addTearDown(tester.view.resetViewInsets);
    await tester.pumpAndSettle();
    visible(tester, find.byKey(const ValueKey('email-action')));
    expect(
      tester.getRect(find.byKey(const ValueKey('email-action'))).bottom,
      lessThanOrEqualTo(308),
    );
    expect(tester.takeException(), isNull);
  });
  for (final size in phones) {
    for (final scale in [1.0, 2.0]) {
      testWidgets('result has visible email action $size $scale', (
        tester,
      ) async {
        viewport(tester, size);
        final bytes = await photo(tester);
        await tester.pumpWidget(
          app(
            ResultScreen(
              images: [bytes],
              outfitName: 'Caftan A',
              resultId: 'r',
            ),
            scale: scale,
          ),
        );
        await tester.pumpAndSettle();
        visible(tester, find.byKey(const ValueKey('result-email')));
        expect(find.byType(SingleChildScrollView), findsNothing);
        expect(find.text('Télécharger'), findsNothing);
        expect(find.byIcon(Icons.favorite_border), findsNothing);
        expect(
          tester.widget<Image>(find.byKey(const ValueKey('result-photo'))).fit,
          BoxFit.contain,
        );
        await tester.tap(find.byKey(const ValueKey('result-email')));
        await tester.pumpAndSettle();
        expect(find.byType(DeliverySheet), findsOneWidget);
        expect(find.byType(ResultScreen), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  }
}
