import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:digiwearit2/try_on_session.dart';
import 'package:digiwearit2/experience_failure.dart';
import 'package:digiwearit2/result_screen.dart';
import 'package:digiwearit2/rating_sheet.dart';
import 'package:digiwearit2/customer_profile.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'fixtures.dart';

void main() {
  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    CustomerProfile.instance = CustomerProfile();
  });
  test('gate requires completed generation and successful payment', () {
    final gate = RevealGate();
    gate.generation = GenerationStatus.completed;
    expect(gate.canReveal, isFalse);
    gate.payment = PaymentStatus.failed;
    expect(gate.canReveal, isFalse);
    gate.payment = PaymentStatus.paid;
    expect(gate.canReveal, isTrue);
    gate.generation = GenerationStatus.processing;
    expect(gate.canReveal, isFalse);
    expect(explainFailure(TimeoutException('x')), Friendly.slow);
  });
  testWidgets(
    'email retries then rating can be skipped and finish opens the styles',
    (tester) async {
      viewport(tester, const Size(390, 844));
      final bytes = await photo(tester);
      var sends = 0;
      await tester.pumpWidget(
        MaterialApp(
          initialRoute: '/result',
          routes: {
            '/': (_) => const Scaffold(body: Text('Clean home')),
            '/style': (_) => const Scaffold(body: Text('Styles')),
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
      expect(find.text(Friendly.slow), findsOneWidget);
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
      expect(find.text('Styles'), findsOneWidget);
      expect(find.byType(ResultScreen), findsNothing);
    },
  );
  testWidgets('rating is asked once and the saved email is reused', (
    tester,
  ) async {
    viewport(tester, const Size(390, 844));
    final bytes = await photo(tester);
    final emails = <String>[];
    Future<void> sendOnce(String id) async {
      await tester.pumpWidget(
        app(
          ResultScreen(
            key: ValueKey(id),
            images: [bytes],
            outfitName: 'Caftan',
            resultId: id,
            emailSender: (email, b, id) async => emails.add(email),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('result-email')));
      await tester.pumpAndSettle();
    }

    await sendOnce('first');
    await tester.enterText(find.byType(TextFormField), 'client@example.com');
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('email-action')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('email-action')));
    await tester.pumpAndSettle();
    expect(find.byType(RatingSheet), findsOneWidget);
    expect(CustomerProfile.instance.email, 'client@example.com');
    await tester.pumpWidget(const SizedBox());

    await sendOnce('second');
    expect(
      tester.widget<TextFormField>(find.byType(TextFormField)).controller!.text,
      'client@example.com',
    );
    await tester.tap(find.byKey(const ValueKey('email-action')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('email-action')));
    await tester.pumpAndSettle();
    expect(find.byType(RatingSheet), findsNothing);
    expect(emails, ['client@example.com', 'client@example.com']);
  });
  testWidgets('rating supports a choice and a bounded optional comment', (
    tester,
  ) async {
    await tester.pumpWidget(
      app(Scaffold(body: RatingSheet(sender: (_) async {}))),
    );
    await tester.tap(find.byKey(const ValueKey('rating-5')));
    await tester.pump();
    expect(find.text('Satisfait'), findsOneWidget);
    expect(tester.widget<TextField>(find.byType(TextField)).maxLength, 150);
    await tester.tap(find.text('Envoyer mon avis'));
    await tester.pumpAndSettle();
    expect(find.text('Merci pour votre avis 💜'), findsOneWidget);
  });
}
