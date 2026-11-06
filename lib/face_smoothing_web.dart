import 'package:camera/camera.dart';
import 'package:flutter/widgets.dart';
import 'photo_check.dart';
import 'dart:js_interop';
import 'dart:typed_data';

@JS('digiFaceFilter.start')
external JSPromise<JSBoolean> _start(JSNumber strength);
@JS('digiFaceFilter.strength')
external void _strength(JSNumber value);
@JS('digiFaceFilter.stop')
external void _stop();
@JS('digiFaceFilter.capture')
external JSPromise<JSUint8Array> _capture();

class FaceSmoothing {
  void bind(CameraController camera) {}
  Widget preview(Widget child) => child;
  bool get supported => true;
  Future<bool> start(double strength) async {
    try {
      return (await _start(strength.toJS).toDart).toDart;
    } catch (_) {
      return false;
    }
  }

  void setStrength(double value) => _strength(value.toJS);
  bool get makeupSupported => false;

  /// No live frames here; the taken photo is checked instead.
  final lighting = ValueNotifier<LightingIssue?>(null);
  void setMakeup({required bool foundation, required bool color}) {}
  Future<void> stop() async {
    try {
      _stop();
    } catch (_) {}
  }

  Future<Uint8List> capture() async => (await _capture().toDart).toDart;
}
