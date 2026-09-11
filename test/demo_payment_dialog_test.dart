import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:digiwearit2/demo_payment_dialog.dart';
import 'fixtures.dart';

void main() {
  for (final outcome in ['paid', 'failed', 'cancel']) {
    testWidgets('demo modal $outcome preserves underlying screen', (
      tester,
    ) async {
      viewport(tester, const Size(320, 568));
      String? result;
      var processing = false;
      await tester.pumpWidget(
        app(
          Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () async => result = await showDemoPayment(
                  context,
                  onProcessing: () => processing = true,
                ),
                child: const Text('Generation remains here'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Generation remains here'));
      await tester.pumpAndSettle();
      expect(find.text('Generation remains here'), findsOneWidget);
      expect(find.byType(SingleChildScrollView), findsNothing);
      visible(tester, find.byKey(const ValueKey('confirm-demo-payment')));
      if (outcome == 'paid') {
        await tester.tap(find.byKey(const ValueKey('confirm-demo-payment')));
        await tester.pump();
        expect(find.text('Confirmation…'), findsOneWidget);
        expect(processing, isTrue);
        expect(result, isNull);
        await tester.pump(const Duration(milliseconds: 750));
      } else {
        await tester.tap(
          find.text(outcome == 'failed' ? 'Simuler un refus' : 'Annuler'),
        );
      }
      await tester.pumpAndSettle();
      expect(result, outcome == 'cancel' ? isNull : outcome);
      expect(find.byType(DemoPaymentDialog), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }
}
