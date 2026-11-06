import 'package:camera/camera.dart';
import 'package:flutter/widgets.dart';
import 'photo_check.dart';
import 'dart:typed_data';

class FaceSmoothing {
  void bind(CameraController camera) {}
  Widget preview(Widget child) => child;
  bool get supported => false;
  Future<bool> start(double strength) async => false;
  void setStrength(double value) {}
  bool get makeupSupported => false;

  /// No live frames here; the taken photo is checked instead.
  final lighting = ValueNotifier<LightingIssue?>(null);
  void setMakeup({required bool foundation, required bool color}) {}
  Future<void> stop() async {}
  Future<Uint8List> capture() => Future.error(UnsupportedError('Web only'));
}
