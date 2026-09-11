import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:digiwearit2/outfit_screen.dart';
import 'package:digiwearit2/outfit_selection.dart';
import 'package:digiwearit2/mobile_layout.dart';
import 'fixtures.dart';

void main() {
  for (final size in phones) {
    testWidgets('category CTA fixed at $size', (tester) async {
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
            '/model': (context) {
              result =
                  ModalRoute.of(context)!.settings.arguments as OutfitSelection;
              return const Scaffold();
            },
          },
        ),
      );
      await tester.pumpAndSettle();
      visible(tester, find.byKey(const ValueKey('outfit-continue')));
      await tester.tap(find.byKey(const ValueKey('outfit-continue')));
      await tester.pumpAndSettle();
      expect(result!.outfits.length, 2);
      expect(tester.takeException(), isNull);
    });
  }
  testWidgets('empty catalogue cannot continue', (tester) async {
    await tester.pumpWidget(app(OutfitScreen(outfits: Stream.value([]))));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<DigiButton>(find.byKey(const ValueKey('outfit-continue')))
          .onPressed,
      isNull,
    );
  });
}
