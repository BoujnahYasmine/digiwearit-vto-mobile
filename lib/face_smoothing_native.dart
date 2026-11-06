import 'package:flutter/foundation.dart' show defaultTargetPlatform;
import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'face_smoothing_mask.dart';
import 'camera_service.dart';
import 'image_orientation_normalizer.dart';
import 'photo_check.dart';

/// Face box and contour points, in the detector's image space.
typedef _Landmarks = ({
  Rect bounds,
  Map<FaceContourType, List<Offset>> contours,
});

class FaceSmoothing {
  bool get _isIOS => defaultTargetPlatform == TargetPlatform.iOS;
  bool get _isAndroid => defaultTargetPlatform == TargetPlatform.android;
  bool get supported => _isAndroid || _isIOS;
  CameraController? _camera;
  FaceDetector? _detector;
  final _revision = ValueNotifier<int>(0);
  Path? _mask;
  MakeupShapes? _shapes;
  double _strength = 0;
  bool _enabled = false;

  /// Light foundation on the face skin, and blush + sheer lipstick on top.
  bool _foundation = false, _makeup = false;
  bool get makeupSupported => supported;
  int _epoch = 0;
  Future<void>? _processing, _starting;
  Future<void> _stopping = Future.value();
  DateTime _last = DateTime.fromMillisecondsSinceEpoch(0);
  Timer? _expiry;

  /// Last steadied landmarks of the live preview (detector image space).
  _Landmarks? _previous;

  void bind(CameraController camera) {
    _camera = camera;
  }

  void _clear() {
    _expiry?.cancel();
    _mask = null;
    _shapes = null;
    _previous = null;
    _revision.value++;
  }

  void setStrength(double value) {
    _strength = value.clamp(0, 1);
    _revision.value++;
  }

  void setMakeup({required bool foundation, required bool color}) {
    _foundation = foundation;
    _makeup = color;
    if (!foundation && !color) _shapes = null;
    _revision.value++;
  }

  Future<bool> start(double strength) async {
    final epoch = ++_epoch;
    await _stopping;
    if (epoch != _epoch) return false;
    final camera = _camera;
    if (!supported || camera == null || !camera.value.isInitialized) {
      return false;
    }
    _enabled = true;
    setStrength(strength);
    _detector = FaceDetector(
      options: FaceDetectorOptions(
        enableContours: true,
        performanceMode: FaceDetectorMode.fast,
      ),
    );
    final ready = Completer<bool>();
    try {
      _starting = camera.startImageStream((frame) {
        if (!_enabled ||
            epoch != _epoch ||
            _processing != null ||
            DateTime.now().difference(_last).inMilliseconds < 120) {
          return;
        }
        _last = DateTime.now();
        _processing = _detect(
          frame,
          camera,
          epoch,
          ready,
        ).whenComplete(() => _processing = null);
      });
      await _starting;
      final available = await ready.future.timeout(
        const Duration(seconds: 8),
        onTimeout: () => false,
      );
      if (epoch != _epoch) return false;
      if (!available) {
        await stop();
        return false;
      }
      return true;
    } catch (_) {
      if (epoch == _epoch) await stop();
      return false;
    }
  }

  Future<void> _detect(
    CameraImage frame,
    CameraController camera,
    int epoch,
    Completer<bool> ready,
  ) async {
    try {
      final orientation = camera.value.deviceOrientation;
      final sensor = camera.description.sensorOrientation;
      const orientations = {
        DeviceOrientation.portraitUp: 0,
        DeviceOrientation.landscapeLeft: 90,
        DeviceOrientation.portraitDown: 180,
        DeviceOrientation.landscapeRight: 270,
      };
      final device = orientations[orientation]!;
      final front =
          camera.description.lensDirection == CameraLensDirection.front;
      final degrees = _isIOS
          ? sensor
          : (front ? sensor + device : sensor - device + 360) % 360;
      final rotation = InputImageRotationValue.fromRawValue(degrees);
      final format = InputImageFormatValue.fromRawValue(frame.format.raw);
      if (rotation == null ||
          frame.planes.length != 1 ||
          (_isAndroid && format != InputImageFormat.nv21) ||
          (_isIOS && format != InputImageFormat.bgra8888)) {
        if (!ready.isCompleted) ready.complete(false);
        _clear();
        return;
      }
      _measureLight(frame);
      final faces = await _detector!.processImage(
        InputImage.fromBytes(
          bytes: frame.planes.first.bytes,
          metadata: InputImageMetadata(
            size: Size(frame.width.toDouble(), frame.height.toDouble()),
            rotation: rotation,
            format: format!,
            bytesPerRow: frame.planes.first.bytesPerRow,
          ),
        ),
      );
      if (!_enabled || epoch != _epoch) return;
      if (!ready.isCompleted) ready.complete(true);
      if (orientation != camera.value.deviceOrientation) {
        _clear();
        return;
      }
      final face = _mainFace(faces);
      // A missed frame keeps the last overlay; the expiry clears it only when
      // the face is really gone, so the effect does not blink.
      if (face == null) return;
      final landmarks = _steady(_landmarks(face));
      final mask = _faceMask(landmarks);
      if (mask == null) return;
      // Same image-to-preview transform as the ML Kit Flutter camera example.
      final sideways = degrees == 90 || degrees == 270;
      final width = sideways && _isAndroid ? frame.height : frame.width;
      final height = sideways && _isAndroid ? frame.width : frame.height;
      final flip = degrees == 270 || (!sideways && front);
      final toPreview = Float64List.fromList([
        (flip ? -1 : 1) / width,
        0,
        0,
        0,
        0,
        1 / height,
        0,
        0,
        0,
        0,
        1,
        0,
        flip ? 1 : 0,
        0,
        0,
        1,
      ]);
      _mask = mask.transform(toPreview);
      _shapes = _makeupFor(landmarks)?.transform(toPreview);
      _revision.value++;
      _expiry?.cancel();
      _expiry = Timer(const Duration(milliseconds: 900), _clear);
    } catch (_) {
      if (!ready.isCompleted) ready.complete(false);
      if (epoch == _epoch) _clear();
    }
  }

  /// Live lighting tip for the framing screen; null when the light is fine.
  final lighting = ValueNotifier<LightingIssue?>(null);
  LightingIssue? _lightCandidate;
  int _lightVotes = 0;

  /// Samples the frame's brightness (NV21 luma on Android, BGRA on iOS) and
  /// changes the tip only after three agreeing frames, so it never blinks.
  void _measureLight(CameraImage frame) {
    final plane = frame.planes.first;
    final bytes = plane.bytes;
    const columns = 48;
    final rows = (columns * frame.height / frame.width).round().clamp(1, 96);
    final stats = lumaStats(columns, rows, (x, y) {
      final px = x * frame.width ~/ columns, py = y * frame.height ~/ rows;
      if (_isAndroid) return bytes[py * plane.bytesPerRow + px];
      final i = py * plane.bytesPerRow + px * 4;
      return (bytes[i + 2] * .299 + bytes[i + 1] * .587 + bytes[i] * .114)
          .round();
    });
    final issue = assessLuma(stats);
    if (issue == _lightCandidate) {
      _lightVotes++;
    } else {
      _lightCandidate = issue;
      _lightVotes = 1;
    }
    if (_lightVotes >= 3) lighting.value = issue;
  }

  /// Largest face, only when it looks roughly at the camera.
  Face? _mainFace(List<Face> faces) {
    if (faces.isEmpty) return null;
    final face = faces.reduce(
      (a, b) =>
          a.boundingBox.width * a.boundingBox.height >
              b.boundingBox.width * b.boundingBox.height
          ? a
          : b,
    );
    if ((face.headEulerAngleY ?? 0).abs() > 25 ||
        (face.headEulerAngleZ ?? 0).abs() > 25) {
      return null;
    }
    return face;
  }

  static _Landmarks _landmarks(Face face) => (
    bounds: face.boundingBox,
    contours: {
      for (final type in FaceContourType.values)
        type:
            face.contours[type]?.points
                .map((p) => Offset(p.x.toDouble(), p.y.toDouble()))
                .toList() ??
            const <Offset>[],
    },
  );

  /// Glides the live overlay toward each new detection instead of jumping,
  /// which hides detector jitter; a large move (new face) snaps at once.
  _Landmarks _steady(_Landmarks next) {
    final previous = _previous;
    if (previous == null ||
        (previous.bounds.center - next.bounds.center).distance >
            next.bounds.width * .25) {
      return _previous = next;
    }
    const follow = .45;
    Offset lerp(Offset a, Offset b) => Offset.lerp(a, b, follow)!;
    return _previous = (
      bounds: Rect.lerp(previous.bounds, next.bounds, follow)!,
      contours: {
        for (final MapEntry(key: type, value: points) in next.contours.entries)
          type: previous.contours[type]?.length == points.length
              ? [
                  for (var i = 0; i < points.length; i++)
                    lerp(previous.contours[type]![i], points[i]),
                ]
              : points,
      },
    );
  }

  Path? _faceMask(_Landmarks face) {
    final outline = face.contours[FaceContourType.face] ?? const [];
    if (outline.isEmpty) return null;
    return faceSkinMask(face.bounds, outline, [
      for (final MapEntry(key: type, value: points) in face.contours.entries)
        if (type != FaceContourType.face) points,
    ]);
  }

  MakeupShapes? _makeupFor(_Landmarks face) {
    if (!_foundation && !_makeup) return null;
    List<Offset> points(FaceContourType type) =>
        face.contours[type] ?? const [];
    Offset? single(FaceContourType type) {
      final found = points(type);
      return found.isEmpty ? null : found.first;
    }

    return makeupShapes(
      bounds: face.bounds,
      outline: points(FaceContourType.face),
      eyesAndBrows: [
        for (final type in const [
          FaceContourType.leftEye,
          FaceContourType.rightEye,
          FaceContourType.leftEyebrowTop,
          FaceContourType.leftEyebrowBottom,
          FaceContourType.rightEyebrowTop,
          FaceContourType.rightEyebrowBottom,
        ])
          points(type),
      ],
      foundation: _foundation,
      color: _makeup,
      upperLipTop: points(FaceContourType.upperLipTop),
      upperLipBottom: points(FaceContourType.upperLipBottom),
      lowerLipTop: points(FaceContourType.lowerLipTop),
      lowerLipBottom: points(FaceContourType.lowerLipBottom),
      leftCheek: single(FaceContourType.leftCheek),
      rightCheek: single(FaceContourType.rightCheek),
    );
  }

  Future<void> _stopStream(CameraController? camera) async {
    try {
      await _starting;
    } catch (_) {
      /* Camera may have closed. */
    }
    if (camera?.value.isStreamingImages == true) {
      try {
        await camera!.stopImageStream();
      } catch (_) {
        /* Already disposed. */
      }
    }
    await _processing;
  }

  Future<void> stop() {
    ++_epoch;
    _enabled = false;
    _lightVotes = 0;
    lighting.value = null;
    _clear();
    final camera = _camera;
    final previous = _stopping;
    return _stopping = () async {
      await previous;
      await _stopStream(camera);
      final detector = _detector;
      _detector = null;
      try {
        await detector?.close();
      } catch (_) {
        /* Native teardown must not block camera disposal. */
      }
    }();
  }

  Future<Uint8List> capture() async {
    final camera = _camera;
    if (camera == null || !_enabled) throw StateError('Filter unavailable');
    _enabled = false;
    ++_epoch;
    _clear();
    await _stopStream(camera);
    final file = await camera.takePicture();
    final bytes = await unmirrorStill(
      await const ImageOrientationNormalizer().normalizeForUpload(
        await file.readAsBytes(),
      ),
      camera.description,
    );
    // Detect on the upright full-resolution still, not old preview coordinates.
    final directory = await Directory.systemTemp.createTemp('digiwearit-face-');
    try {
      final photo = File('${directory.path}/photo.jpg');
      await photo.writeAsBytes(bytes, flush: true);
      try {
        final faces = await _detector!.processImage(
          InputImage.fromFilePath(photo.path),
        );
        final detected = _mainFace(faces);
        if (detected == null) return bytes;
        final face = _landmarks(detected);
        var result = bytes;
        final mask = _faceMask(face);
        if (mask != null) {
          result = await smoothCapturedImage(result, mask, _strength);
        }
        final makeup = _makeupFor(face);
        if (makeup != null) result = await applyMakeupToImage(result, makeup);
        return result;
      } catch (_) {
        return bytes;
      }
    } finally {
      await directory.delete(recursive: true);
    }
  }

  Widget preview(Widget child) => ValueListenableBuilder<int>(
    valueListenable: _revision,
    child: child,
    builder: (context, _, original) => LayoutBuilder(
      builder: (context, constraints) {
        final mask = _mask;
        return Stack(
          fit: StackFit.expand,
          children: [
            original!,
            if (_enabled && mask != null && _strength > 0)
              IgnorePointer(
                child: ClipPath(
                  clipper: _SkinClipper(mask),
                  child: BackdropFilter(
                    filter: ui.ImageFilter.blur(
                      sigmaX: smoothingSigma(constraints.maxWidth, _strength),
                      sigmaY: smoothingSigma(constraints.maxWidth, _strength),
                    ),
                    child: const SizedBox.expand(),
                  ),
                ),
              ),
            if (_enabled && _shapes != null)
              IgnorePointer(
                child: CustomPaint(painter: _MakeupPainter(_shapes!)),
              ),
          ],
        );
      },
    ),
  );
}

class _SkinClipper extends CustomClipper<Path> {
  const _SkinClipper(this.mask);
  final Path mask;
  @override
  Path getClip(Size size) => mask.transform(
    Float64List.fromList([
      size.width,
      0,
      0,
      0,
      0,
      size.height,
      0,
      0,
      0,
      0,
      1,
      0,
      0,
      0,
      0,
      1,
    ]),
  );
  @override
  bool shouldReclip(_SkinClipper oldClipper) => oldClipper.mask != mask;
}

class _MakeupPainter extends CustomPainter {
  const _MakeupPainter(this.shapes);
  final MakeupShapes shapes;
  @override
  void paint(Canvas canvas, Size size) => paintMakeup(
    canvas,
    shapes.transform(
      Float64List.fromList([
        size.width,
        0,
        0,
        0,
        0,
        size.height,
        0,
        0,
        0,
        0,
        1,
        0,
        0,
        0,
        0,
        1,
      ]),
    ),
  );
  @override
  bool shouldRepaint(_MakeupPainter oldDelegate) =>
      oldDelegate.shapes != shapes;
}
