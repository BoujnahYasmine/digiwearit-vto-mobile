import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:digiwearit2/outfit_screen.dart';
import 'package:digiwearit2/outfit_selection.dart';
import 'fixtures.dart';

void main() {
  for (final size in phones) {
    testWidgets('each outfit card has its own try-on button at $size', (
      tester,
    ) async {
      viewport(tester, size);
      OutfitSelection? result;
      await tester.pumpWidget(
        app(
          OutfitScreen(
            outfits: Stream.value([
              model('a', 'Caftan A'),
              model('b', 'Caftan B'),
              model('c', 'Jellaba C'),
            ]),
          ),
          routes: {
            '/try-on': (context) {
              result =
                  ModalRoute.of(context)!.settings.arguments as OutfitSelection;
              return const Scaffold();
            },
          },
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Choisissez une tenue'), findsOneWidget);
      expect(
        find.text('Continuer'),
        findsNothing,
        reason: 'no Continue button',
      );
      expect(find.text('Essayer'), findsNWidgets(2), reason: 'one per card');
      visible(tester, find.text('Essayer').first);
      await tester.tap(find.text('Essayer').first);
      await tester.pumpAndSettle();
      expect(result!.outfits.length, 2);
      expect(result!.outfit.id, 'a');
      expect(tester.takeException(), isNull);
    });
  }
  testWidgets('empty catalogue shows no try-on button', (tester) async {
    await tester.pumpWidget(app(OutfitScreen(outfits: Stream.value([]))));
    await tester.pumpAndSettle();
    expect(find.text('Essayer'), findsNothing);
    expect(
      find.text('Aucune tenue disponible dans cette collection.'),
      findsOneWidget,
    );
  });
}
