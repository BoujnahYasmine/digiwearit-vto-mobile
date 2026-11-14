import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:digiwearit2/universe_screen.dart';
import 'package:digiwearit2/style_selection.dart';
import 'package:digiwearit2/mobile_layout.dart';
import 'fixtures.dart';

void main() {
  testWidgets(
    'partner selection uses its callback instead of the public style route',
    (tester) async {
      String? gender;
      bool? english;
      await tester.pumpWidget(
        app(
          UniverseScreen(
            onSelected: (selected, language) {
              gender = selected;
              english = language;
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('universe-femme')));
      await tester.pumpAndSettle();
      expect(gender, 'femme');
      expect(english, false);
      expect(tester.takeException(), isNull);
    },
  );
  for (final size in phones) {
    testWidgets('footer slogan is centred at $size', (tester) async {
      viewport(tester, size);
      await tester.pumpWidget(app(const UniverseScreen()));
      await tester.pumpAndSettle();
      // The letter spacing after the last letter is invisible: measure the
      // visible text, i.e. the box minus that trailing spacing.
      final box = tester.getRect(find.byKey(const ValueKey('footer-slogan')));
      final visibleCentre = box.left + (box.width - 3) / 2;
      expect((visibleCentre - size.width / 2).abs(), lessThan(3));
    });
    testWidgets('shared footer slogan is centred at $size', (tester) async {
      viewport(tester, size);
      await tester.pumpWidget(
        app(
          const Scaffold(
            body: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [Spacer(), DigiSlogan()],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final box = tester.getRect(find.text(DigiSlogan.text));
      final visibleCentre = box.left + (box.width - 3) / 2;
      expect((visibleCentre - size.width / 2).abs(), lessThan(3));
    });
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
