import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:digiwearit2/mirror/mirror_content.dart';
import 'package:digiwearit2/mirror/mirror_outfits_screen.dart';
import 'package:digiwearit2/mirror/mirror_tryon_controller.dart';
import 'partner_mode_test.dart' as f;

void main() {
  testWidgets(
    'shows selected catalogue outfits and confirms before opening camera',
    (tester) async {
      tester.view.physicalSize = const Size(330, 710);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final controller = MirrorTryOnController(
        sessionService: f.FakeSession(),
        contentService: f.FakeContent(
          const MirrorContent(
            enterpriseId: 'acme',
            enterpriseName: 'Acme',
            catalogues: [
              MirrorCatalogue(
                id: 'chosen',
                name: 'Japanese',
                outfits: [
                  MirrorOutfit(id: 'kimono', name: 'Kimono', imageUrl: ''),
                ],
              ),
              MirrorCatalogue(
                id: 'other',
                name: 'Other',
                outfits: [
                  MirrorOutfit(
                    id: 'other-outfit',
                    name: 'Other outfit',
                    imageUrl: '',
                  ),
                ],
              ),
            ],
          ),
        ),
        generationService: f.FakeGeneration(),
      );
      await controller.loadContent();
      controller.selectCatalogue('chosen');
      await tester.pumpWidget(
        MaterialApp(
          home: MirrorOutfitsScreen(controller: controller),
          routes: {
            '/mirror/camera': (_) => const Scaffold(body: Text('Camera')),
          },
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Kimono'), findsOneWidget);
      expect(find.text('Other outfit'), findsNothing);
      await tester.tap(find.byKey(const ValueKey('mirror-outfit-continue')));
      await tester.pumpAndSettle();
      expect(find.text('Camera'), findsNothing);
      await tester.tap(find.byKey(const ValueKey('mirror-outfit-kimono')));
      await tester.pumpAndSettle();
      expect(find.text('Camera'), findsNothing);
      await tester.tap(find.byKey(const ValueKey('mirror-outfit-continue')));
      await tester.pumpAndSettle();
      expect(controller.selectedOutfitId, 'kimono');
      expect(find.text('Camera'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
