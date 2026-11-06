// ignore_for_file: depend_on_referenced_packages
import 'package:digiwearit2/experience_failure.dart';
import 'package:camera_platform_interface/camera_platform_interface.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:digiwearit2/photo_screen.dart';
import 'package:digiwearit2/outfit_selection.dart';
import 'fixtures.dart';

class EmptyCamera extends CameraPlatform {
  @override
  Future<List<CameraDescription>> availableCameras() async => [];
}

void main() {
  setUp(() => CameraPlatform.instance = EmptyCamera());
  for (final size in phones) {
    testWidgets('camera shutter is visible at $size without scrolling', (
      tester,
    ) async {
      viewport(tester, size);
      await tester.pumpWidget(
        app(
          PhotoScreen(
            selection: OutfitSelection(
              outfit: model('a', 'Caftan'),
              gender: 'femme',
              style: 'maroccain',
              english: false,
            ),
            onContinue: (_, bytes) async {},
          ),
        ),
      );
      await tester.pumpAndSettle();
      visible(tester, find.byKey(const ValueKey('camera-shutter')));
      expect(find.byType(SingleChildScrollView), findsNothing);
      expect(find.byKey(const ValueKey('camera-body-guide')), findsOneWidget);
      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is Image &&
              widget.image is AssetImage &&
              (widget.image as AssetImage).assetName ==
                  'assets/welcome_boutique.png',
        ),
        findsNothing,
      );
      expect(find.text('Prendre la photo'), findsNothing);
      expect(find.text(Friendly.cameraUnavailable), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
