import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:digiwearit2/model_screen.dart';
import 'package:digiwearit2/outfit_selection.dart';
import 'fixtures.dart';

void main() {
  for (final size in phones) {
    for (final scale in [1.0, 2.0]) {
      testWidgets('model CTA visible at $size scale $scale', (tester) async {
        viewport(tester, size);
        final a = model('a', 'Caftan A'), b = model('b', 'Caftan B');
        OutfitSelection? result;
        await tester.pumpWidget(
          app(
            ModelScreen(
              selection: OutfitSelection(
                outfit: a,
                outfits: [a, b],
                gender: 'femme',
                style: 'maroccain',
                english: false,
              ),
            ),
            scale: scale,
            routes: {
              '/try-on': (context) {
                result =
                    ModalRoute.of(context)!.settings.arguments
                        as OutfitSelection;
                return const Scaffold();
              },
            },
          ),
        );
        await tester.pumpAndSettle();
        visible(tester, find.byKey(const ValueKey('model-continue')));
        expect(find.byIcon(Icons.favorite_border), findsNothing);
        expect(find.byType(DropdownButtonFormField<String>), findsNothing);
        await tester.tap(find.byKey(const ValueKey('model-next')));
        await tester.tap(find.byKey(const ValueKey('model-continue')));
        await tester.pumpAndSettle();
        expect(result!.outfit.id, 'b');
        expect(tester.takeException(), isNull);
      });
    }
  }
}
