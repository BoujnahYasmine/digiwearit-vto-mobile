import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:digiwearit2/rating_sheet.dart';
import 'package:digiwearit2/mobile_layout.dart';
import 'fixtures.dart';

void main() {
  for (final size in phones) {
    testWidgets('rating closes as skip and fits $size', (tester) async {
      viewport(tester, size);
      var sends = 0;
      await tester.pumpWidget(
        app(
          Scaffold(
            body: RatingSheet(
              sender: (_) async {
                sends++;
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(SingleChildScrollView), findsNothing);
      expect(
        tester
            .widget<DigiButton>(find.byKey(const ValueKey('rating-submit')))
            .onPressed,
        isNull,
      );
      await tester.tap(find.byKey(const ValueKey('rating-close')));
      await tester.pumpAndSettle();
      expect(find.text('Terminer'), findsOneWidget);
      expect(sends, 0);
      expect(tester.takeException(), isNull);
    });
  }
  testWidgets('rating sends minimal metadata without requiring a comment', (
    tester,
  ) async {
    Map<String, dynamic>? sent;
    await tester.pumpWidget(
      app(
        Scaffold(
          body: RatingSheet(
            tryOnId: 'try-1',
            outfitId: 'outfit-2',
            sender: (value) async {
              sent = value;
            },
          ),
        ),
      ),
    );
    await tester.tap(find.byKey(const ValueKey('rating-5')));
    await tester.pumpAndSettle();
    expect(find.text('Excellent ✨'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('rating-submit')));
    await tester.pumpAndSettle();
    expect(sent!['rating'], 5);
    expect(sent!['comment'], '');
    expect(sent!['tryOnId'], 'try-1');
    expect(sent!['outfitId'], 'outfit-2');
    expect(DateTime.tryParse(sent!['timestamp'] as String), isNotNull);
    expect(sent!.keys.toSet(), {
      'rating',
      'comment',
      'tryOnId',
      'outfitId',
      'timestamp',
    });
    expect(find.text('Merci pour votre avis 💜'), findsOneWidget);
  });
}
