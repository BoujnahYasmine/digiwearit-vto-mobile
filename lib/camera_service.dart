import 'package:flutter/foundation.dart';

import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';

import 'image_orientation_normalizer.dart';

class CameraService {
  CameraService({ImageOrientationNormalizer? orientationNormalizer})
    : _orientationNormalizer =
          orientationNormalizer ?? const ImageOrientationNormalizer();

  final ImageOrientationNormalizer _orientationNormalizer;

  Future<List<CameraDescription>> devices() => availableCameras();

  /// Best first: 1080p gives the AI (which returns ~1 MP) enough face and
  /// fabric detail while staying light on low-end phones (4K would only add
  /// weight); 720p is the automatic fallback for cameras that refuse 1080p.
  static const qualities = [ResolutionPreset.veryHigh, ResolutionPreset.high];

  CameraController controller(
    CameraDescription device, {
    ResolutionPreset quality = ResolutionPreset.veryHigh,
  }) => CameraController(
    device,
    quality,
    enableAudio: false,
    imageFormatGroup: kIsWeb
        ? ImageFormatGroup.unknown
        : defaultTargetPlatform == TargetPlatform.iOS
        ? ImageFormatGroup.bgra8888
        : ImageFormatGroup.nv21,
  );

  /// Opens [device] at the best quality it accepts, trying [qualities] in
  /// order. A refused permission is never retried; [release] disposes a
  /// camera that failed to start.
  Future<CameraController> open(
    CameraDescription device, {
    required Future<void> Function(CameraController) release,
  }) async {
    for (final quality in qualities) {
      final camera = controller(device, quality: quality);
      try {
        await initialize(camera);
        return camera;
      } on CameraException catch (error) {
        await release(camera);
        final denied = error.code.toLowerCase().contains('denied');
        if (denied || quality == qualities.last) rethrow;
        debugPrint('Camera refused $quality, trying lower: ${error.code}');
      }
    }
    throw StateError('unreachable');
  }

  Future<void> initialize(CameraController controller) async {
    await controller.initialize();
    try {
      await controller.setZoomLevel(await controller.getMinZoomLevel());
    } catch (_) {
      // Some camera implementations do not expose zoom.
    }
  }

  Future<XFile> capture(CameraController controller) =>
      controller.takePicture();

  Future<XFile?> pickPhoto() => ImagePicker().pickImage(
    source: ImageSource.gallery,
    // Preserve original pixels and EXIF until normalization.
  );

  Future<Uint8List> normalizedBytes(XFile file) async =>
      _orientationNormalizer.normalizeForUpload(await file.readAsBytes());

  /// Upright still from the live camera, never mirrored.
  Future<Uint8List> captureBytes(CameraController controller) async =>
      unmirrorStill(
        await normalizedBytes(await capture(controller)),
        controller.description,
      );
}

/// The web plugin (every non-back camera) and CameraX on Android (front
/// camera, its default) save mirrored stills; flip them back to the photo as
/// taken. Stills from other cameras and platforms are returned unchanged.
Future<Uint8List> unmirrorStill(
  Uint8List upright,
  CameraDescription camera,
) async {
  final mirrored = kIsWeb
      ? camera.lensDirection != CameraLensDirection.back
      : defaultTargetPlatform == TargetPlatform.android &&
            camera.lensDirection == CameraLensDirection.front;
  if (!mirrored) return upright;
  return compute(const ImageOrientationNormalizer().flipHorizontal, upright);
}
