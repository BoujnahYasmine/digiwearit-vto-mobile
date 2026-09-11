import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';

class CameraService {
  Future<List<CameraDescription>> devices() => availableCameras();
  CameraController controller(CameraDescription device) =>
      CameraController(device, ResolutionPreset.high, enableAudio: false);
  Future<void> initialize(CameraController controller) async {
    await controller.initialize();
    try {
      await controller.setZoomLevel(await controller.getMinZoomLevel());
    } catch (_) {
      /* Some web cameras do not support zoom. */
    }
  }

  Future<XFile> capture(CameraController controller) =>
      controller.takePicture();
  Future<XFile?> pickPhoto() => ImagePicker().pickImage(
    source: ImageSource.gallery,
    imageQuality: 95,
    requestFullMetadata: false,
  );
}
