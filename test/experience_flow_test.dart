import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:digiwearit2/experience_session.dart';
import 'package:digiwearit2/experience_failure.dart';
import 'package:digiwearit2/result_screen.dart';
import 'package:digiwearit2/rating_sheet.dart';
import 'fixtures.dart';

void main() {
  test('gate supports both orders and failed payments', () {
    final gate = RevealGate(covered: false);
    gate.generation = GenerationStatus.completed;
    expect(gate.canReveal, isFalse);
    gate.payment = PaymentStatus.failed;
    expect(gate.canReveal, isFalse);
    gate.payment = PaymentStatus.demoPaid;
    expect(gate.canReveal, isTrue);
    gate.generation = GenerationStatus.processing;
    expect(gate.canReveal, isFalse);
    final shop = RevealGate(covered: true);
    shop.generation = GenerationStatus.completed;
    expect(shop.canReveal, isTrue);
    expect(explainFailure(TimeoutException('x')), contains('connexion'));
  });
  testWidgets(
    'email retries then rating can be skipped and finish clears routes',
    (tester) async {
      viewport(tester, const Size(390, 844));
      final bytes = await photo(tester);
      var sends = 0;
      await tester.pumpWidget(
        MaterialApp(
          initialRoute: '/result',
          routes: {
            '/': (_) => const Scaffold(body: Text('Clean home')),
            '/result': (_) => ResultScreen(
              images: [bytes],
              outfitName: 'Caftan',
              resultId: 'r',
              emailSender: (email, b, id) async {
                expect(email, 'customer@example.com');
                sends++;
                if (sends == 1) throw TimeoutException('x');
              },
            ),
          },
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('result-email')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField), 'bad');
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('email-action')));
      await tester.pumpAndSettle();
      expect(sends, 0);
      await tester.enterText(
        find.byType(TextFormField),
        'customer@example.com',
      );
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('email-action')));
      await tester.pumpAndSettle();
      expect(find.textContaining('trop de temps'), findsOneWidget);
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('email-action')));
      await tester.pumpAndSettle();
      expect(sends, 2);
      expect(find.text('Photo envoyée !'), findsOneWidget);
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('email-action')));
      await tester.pumpAndSettle();
      expect(find.byType(RatingSheet), findsOneWidget);
      await tester.tap(find.text('Passer'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Terminer'));
      await tester.pumpAndSettle();
      expect(find.text('Clean home'), findsOneWidget);
      expect(find.byType(ResultScreen), findsNothing);
    },
  );
  testWidgets('rating supports stars and a bounded optional comment', (
    tester,
  ) async {
    await tester.pumpWidget(app(const Scaffold(body: RatingSheet())));
    await tester.tap(find.byKey(const ValueKey('rating-4')));
    await tester.pump();
    expect(find.text('Très bien'), findsOneWidget);
    expect(tester.widget<TextField>(find.byType(TextField)).maxLength, 150);
    await tester.tap(find.text('Envoyer mon avis'));
    await tester.pumpAndSettle();
    expect(find.text('Merci pour votre avis 💜'), findsOneWidget);
  });
}
