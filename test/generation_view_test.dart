import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:digiwearit2/generation_view.dart';
import 'fixtures.dart';

void main() {
  for (final size in phones) {
    for (final scale in [1.0, 2.0]) {
      testWidgets('payment stays actionable during generation $size $scale', (
        tester,
      ) async {
        viewport(tester, size);
        final bytes = await photo(tester);
        var payments = 0;
        await tester.pumpWidget(
          app(
            GenerationView(
              photo: bytes,
              outfitName: 'Caftan A',
              outfitUrl: '',
              busy: true,
              stage: 1,
              checkout: true,
              onGenerate: () {},
              onPay: () => payments++,
            ),
            scale: scale,
          ),
        );
        await tester.pump(const Duration(milliseconds: 100));
        visible(tester, find.byKey(const ValueKey('demo-pay')));
        await tester.tap(find.byKey(const ValueKey('demo-pay')));
        expect(payments, 1);
        expect(find.text('Virement bancaire'), findsNothing);
        expect(find.textContaining('%'), findsNothing);
        expect(tester.takeException(), isNull);
      });
    }
  }
  testWidgets('covered partner skips payment', (tester) async {
    final bytes = await photo(tester);
    await tester.pumpWidget(
      app(
        GenerationView(
          photo: bytes,
          outfitName: 'Caftan',
          outfitUrl: '',
          busy: true,
          stage: 1,
          covered: true,
          paid: true,
          onGenerate: () {},
        ),
      ),
    );
    await tester.pump();
    expect(find.byKey(const ValueKey('demo-pay')), findsNothing);
    expect(find.text('Inclus dans votre abonnement'), findsOneWidget);
  });
}
