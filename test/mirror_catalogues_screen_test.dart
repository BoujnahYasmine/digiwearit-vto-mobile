import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:digiwearit2/mirror/mirror_catalogues_screen.dart';
import 'package:digiwearit2/mirror/mirror_content.dart';
import 'package:digiwearit2/mirror/mirror_tryon_controller.dart';
import 'partner_mode_test.dart' as fakes;

void main() {
  testWidgets(
    'enterprise catalogues are filtered and selected before continuing',
    (tester) async {
      final controller = MirrorTryOnController(
        sessionService: fakes.FakeSession(),
        contentService: fakes.FakeContent(
          const MirrorContent(
            enterpriseId: 'acme',
            enterpriseName: 'Acme Boutique',
            catalogues: [
              MirrorCatalogue(
                id: 'women',
                name: 'Acme Femme',
                gender: 'female',
                outfits: [
                  MirrorOutfit(
                    id: 'f',
                    name: 'Female outfit',
                    imageUrl: '',
                    gender: 'female',
                  ),
                ],
              ),
              MirrorCatalogue(
                id: 'men',
                name: 'Acme Homme',
                outfits: [
                  MirrorOutfit(
                    id: 'm',
                    name: 'Male outfit',
                    imageUrl: '',
                    gender: 'male',
                  ),
                ],
              ),
              MirrorCatalogue(
                id: 'all',
                name: 'Acme Mixte',
                outfits: [
                  MirrorOutfit(
                    id: 'af',
                    name: 'Female',
                    imageUrl: '',
                    gender: 'female',
                  ),
                  MirrorOutfit(
                    id: 'am',
                    name: 'Male',
                    imageUrl: '',
                    gender: 'male',
                  ),
                ],
              ),
              MirrorCatalogue(id: 'empty', name: 'Empty catalogue'),
            ],
          ),
        ),
        generationService: fakes.FakeGeneration(),
      );
      await controller.loadContent();
      await tester.pumpWidget(
        MaterialApp(
          home: MirrorCataloguesScreen(controller: controller, gender: 'femme'),
          routes: {
            '/mirror/outfits': (_) =>
                const Scaffold(body: Text('Enterprise outfits')),
          },
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Acme Boutique'), findsOneWidget);
      expect(controller.allowMakeup, false);
      await tester.tap(find.byKey(const ValueKey('mirror-allow-makeup')));
      await tester.pump();
      expect(controller.allowMakeup, true);
      expect(find.text('Acme Femme'), findsOneWidget);
      expect(find.text('Acme Homme'), findsNothing);
      expect(find.text('Acme Mixte'), findsOneWidget);
      expect(find.text('Empty catalogue'), findsNothing);
      expect(
        controller.visibleCatalogues
            .firstWhere((c) => c.id == 'all')
            .outfits
            .map((o) => o.id),
        ['af'],
      );
      await tester.tap(find.byKey(const ValueKey('mirror-catalogue-continue')));
      await tester.pumpAndSettle();
      expect(find.text('Enterprise outfits'), findsNothing);
      await tester.tap(find.byKey(const ValueKey('mirror-catalogue-women')));
      await tester.pumpAndSettle();
      expect(find.text('Enterprise outfits'), findsNothing);
      await tester.tap(find.byKey(const ValueKey('mirror-catalogue-continue')));
      await tester.pumpAndSettle();
      expect(controller.selectedCatalogueId, 'women');
      expect(controller.selectedCatalogue!.outfits.single.id, 'f');
      expect(find.text('Enterprise outfits'), findsOneWidget);
      controller.setGender('homme');
      expect(controller.allowMakeup, false);
      expect(controller.visibleCatalogues.map((c) => c.id), ['men', 'all']);
      controller.selectCatalogue('all');
      expect(controller.selectedCatalogue!.outfits.map((o) => o.id), ['am']);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('empty enterprise never falls back to public styles', (
    tester,
  ) async {
    final controller = MirrorTryOnController(
      sessionService: fakes.FakeSession(),
      contentService: fakes.FakeContent(
        const MirrorContent(
          enterpriseId: 'empty',
          enterpriseName: 'Empty Boutique',
        ),
      ),
      generationService: fakes.FakeGeneration(),
    );
    await controller.loadContent();
    await tester.pumpWidget(
      MaterialApp(
        home: MirrorCataloguesScreen(controller: controller, gender: 'homme'),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.text('Aucune collection disponible pour ce choix.'),
      findsOneWidget,
    );
    expect(find.text('Marocain'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
