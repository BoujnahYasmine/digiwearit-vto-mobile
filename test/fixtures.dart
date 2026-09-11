import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:digiwearit2/catalogue_images.dart';
import 'package:digiwearit2/outfit.dart';

Outfit model(
  String id,
  String name, {
  String gender = 'femme',
  String category = 'maroccain',
}) => Outfit(
  id: id,
  name: name,
  gender: gender,
  category: category,
  thumbnailUrl: catalogueImages.keys.first,
  fullImageUrl: catalogueImages.keys.first,
  imageUrls: [],
  backgroundUrl: '',
  makeupAllowed: false,
  extraPrompt: '',
  active: true,
  color: Colors.purple,
  description: 'Description du modèle',
  tags: ['Cérémonie'],
);
Future<Uint8List> photo(WidgetTester tester) async {
  late Uint8List bytes;
  await tester.runAsync(() async {
    final r = ui.PictureRecorder();
    Canvas(r).drawRect(
      const Rect.fromLTWH(0, 0, 80, 120),
      Paint()..color = Colors.purple,
    );
    final p = r.endRecording();
    final image = await p.toImage(80, 120);
    bytes = (await image.toByteData(
      format: ui.ImageByteFormat.png,
    ))!.buffer.asUint8List();
    image.dispose();
    p.dispose();
  });
  return bytes;
}

void viewport(WidgetTester tester, Size size) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Widget app(
  Widget home, {
  double scale = 1,
  Map<String, WidgetBuilder> routes = const {},
}) => MaterialApp(
  home: home,
  routes: routes,
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(scale)),
    child: child!,
  ),
);
void visible(WidgetTester tester, Finder finder) {
  expect(finder.hitTestable(), findsOneWidget);
  final rect = tester.getRect(finder);
  expect(rect.top, greaterThanOrEqualTo(0));
  expect(rect.bottom, lessThanOrEqualTo(tester.view.physicalSize.height + 1));
}

const phones = [Size(320, 568), Size(390, 844), Size(848, 1000)];
