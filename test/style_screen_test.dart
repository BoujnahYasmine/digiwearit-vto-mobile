import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:digiwearit2/style_screen.dart';
import 'package:digiwearit2/style_selection.dart';
import 'fixtures.dart';

void main() {
  for (final size in phones) {
    testWidgets('style CTA visible and choices carried at $size', (
      tester,
    ) async {
      viewport(tester, size);
      StyleSelection? selection;
      await tester.pumpWidget(
        app(
          const StyleScreen(selection: StyleSelection(gender: 'homme')),
          routes: {
            '/outfits': (context) {
              selection =
                  ModalRoute.of(context)!.settings.arguments as StyleSelection;
              return const Scaffold();
            },
          },
        ),
      );
      await tester.pumpAndSettle();
      visible(tester, find.byKey(const ValueKey('style-continue')));
      await tester.tap(find.byKey(const ValueKey('style-Espagnol')));
      await tester.tap(find.byKey(const ValueKey('style-continue')));
      await tester.pumpAndSettle();
      expect(selection!.style, 'Espagnol');
      expect(selection!.gender, 'homme');
      expect(tester.takeException(), isNull);
    });
  }
}
