import 'package:digiwearit2/outfit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:digiwearit2/style_screen.dart';
import 'package:digiwearit2/style_selection.dart';
import 'fixtures.dart';

void main() {
  testWidgets('live catalogues merge without removing existing styles', (
    tester,
  ) async {
    viewport(tester, phones.first);
    await tester.pumpWidget(
      app(
        StyleScreen(
          catalogues: Stream.value(const [
            LookCategory(
              id: 'new',
              name: 'Japonais',
              gender: '',
              active: true,
              description: 'Collection kimono',
            ),
            LookCategory(
              id: 'existing',
              name: 'Moroccan',
              gender: '',
              active: true,
              description: 'Nouvelle description',
            ),
            LookCategory(
              id: 'hidden',
              name: 'Brouillon',
              gender: '',
              active: false,
            ),
          ]),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('style-Marocain')), findsOneWidget);
    expect(find.text('Nouvelle description'), findsOneWidget);
    expect(find.byKey(const ValueKey('style-Moroccan')), findsNothing);
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('style-Japonais')),
      120,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Collection kimono'), findsOneWidget);
    expect(find.byKey(const ValueKey('style-Brouillon')), findsNothing);
    expect(tester.takeException(), isNull);
  });

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
