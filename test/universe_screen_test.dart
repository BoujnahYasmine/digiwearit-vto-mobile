import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:digiwearit2/universe_screen.dart';
import 'package:digiwearit2/style_selection.dart';
import 'fixtures.dart';

void main() {
  for (final size in phones) {
    testWidgets('gender action visible and selection carried at $size', (
      tester,
    ) async {
      viewport(tester, size);
      StyleSelection? selection;
      await tester.pumpWidget(
        app(
          const UniverseScreen(),
          routes: {
            '/style': (context) {
              selection =
                  ModalRoute.of(context)!.settings.arguments as StyleSelection;
              return const Scaffold();
            },
          },
        ),
      );
      await tester.pumpAndSettle();
      visible(tester, find.byKey(const ValueKey('universe-homme')));
      await tester.tap(find.byKey(const ValueKey('universe-homme')));
      await tester.pumpAndSettle();
      expect(selection!.gender, 'homme');
      expect(tester.takeException(), isNull);
    });
  }
}
