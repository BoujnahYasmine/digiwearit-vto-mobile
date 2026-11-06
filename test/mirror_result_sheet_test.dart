import 'package:digiwearit2/rating_sheet.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:digiwearit2/mirror/mirror_result_screen.dart';
import 'package:digiwearit2/mirror/mirror_tryon_controller.dart';
import 'package:digiwearit2/delivery_screen.dart';
import 'mirror_tryon_controller_test.dart' as f;

void main() {
  testWidgets('result panel drags down and up and delivery uses branded bytes', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final photo = base64Decode(
      'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=',
    );
    final branded = photo.sublist(0);
    final controller = MirrorTryOnController(
      sessionService: f.FakeSession(),
      contentService: f.FakeContent(f.contentWithOne('c1', 'o1')),
      generationService: f.FakeGeneration(),
      watermark: (_) async => branded,
    );
    await controller.loadContent();
    controller.selectCatalogue('c1');
    controller.selectOutfit('o1');
    await controller.confirmPhoto(photo);
    await tester.pumpWidget(
      MaterialApp(home: MirrorResultScreen(controller: controller)),
    );
    await tester.pumpAndSettle();
    final scroll = find.descendant(
      of: find.byKey(const ValueKey('mirror-result-sheet')),
      matching: find.byType(SingleChildScrollView),
    );
    final initial = tester.getTopLeft(scroll).dy;
    await tester.dragFrom(
      tester.getTopLeft(scroll) + const Offset(100, 22),
      const Offset(0, 320),
    );
    await tester.pumpAndSettle();
    expect(tester.getTopLeft(scroll).dy, greaterThan(initial));
    await tester.dragFrom(
      tester.getTopLeft(scroll) + const Offset(100, 22),
      const Offset(0, -500),
    );
    await tester.pumpAndSettle();
    expect(tester.getTopLeft(scroll).dy, lessThan(initial));
    await tester.ensureVisible(
      find.byKey(const ValueKey('mirror-result-email')),
    );
    await tester.tap(find.byKey(const ValueKey('mirror-result-email')));
    await tester.pumpAndSettle();
    expect(
      tester.widget<DeliverySheet>(find.byType(DeliverySheet)).bytes,
      same(branded),
    );
    expect(find.byKey(const ValueKey('mirror-result-sheet')), findsNothing);
    await tester.tap(find.byTooltip('Fermer'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('mirror-result-sheet')), findsOneWidget);
    await tester.ensureVisible(find.textContaining('accueil'));
    await tester.tap(find.textContaining('accueil'));
    await tester.pumpAndSettle();
    expect(find.byType(RatingSheet), findsOneWidget);
    expect(
      tester.widget<RatingSheet>(find.byType(RatingSheet)).sender,
      isNotNull,
    );
    expect(find.byKey(const ValueKey('mirror-result-sheet')), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
