import 'dart:typed_data';

import 'package:image/image.dart' as image;

import 'beauty_filter.dart';
import 'photo_check.dart';

/// What [processCapture] needs: the still as saved by the camera, whether it
/// must be mirror-flipped back, and whether the Éclat light is applied.
typedef CaptureJob = ({Uint8List bytes, bool flip, bool eclat});

/// The photo shown for review, and its automatic light/quality check.
typedef ProcessedCapture = ({Uint8List bytes, PhotoCheck check});

/// Already-decoded pixels (RGBA, opaque) from the GPU retouch pass.
typedef RawCaptureJob = ({Uint8List rgba, int width, int height, bool eclat});

/// Longest side kept for a camera photo: plenty for the try-on (the result
/// is ~1 MP), and keeps every later step fast on modest phones.
const maxPhotoSide = 2000;

image.Image _upright(Uint8List bytes, {required bool flip}) {
  image.Image? decoded;
  try {
    decoded = image.decodeImage(bytes);
  } catch (_) {
    decoded = null;
  }
  if (decoded == null) throw const FormatException('Unsupported image data');
  // The JPEG decoder already applies EXIF; this handles other decoders once.
  var photo = image.bakeOrientation(decoded);
  photo.exif = image.ExifData();
  if (flip) photo = image.flipHorizontal(photo);
  final longest = photo.width > photo.height ? photo.width : photo.height;
  if (longest > maxPhotoSide) {
    photo = photo.width >= photo.height
        ? image.copyResize(photo, width: maxPhotoSide)
        : image.copyResize(photo, height: maxPhotoSide);
  }
  return photo;
}

ProcessedCapture _finish(image.Image photo, bool eclat) {
  final check = checkImage(photo);
  if (eclat) BeautyFilter.applyTo(photo);
  return (
    bytes: Uint8List.fromList(image.encodeJpg(photo, quality: 92)),
    check: check,
  );
}

/// Turns a camera still into the review photo in a single pass: one decode,
/// orientation, un-mirroring, the light/quality check (on the original
/// pixels), the Éclat light, one JPEG encode. Pure, for compute.
ProcessedCapture processCapture(CaptureJob job) =>
    _finish(_upright(job.bytes, flip: job.flip), job.eclat);

/// Upright, un-mirrored JPEG of a camera still in one pass, for the face
/// detector and the retouch. Pure, for compute.
Uint8List prepareStill(({Uint8List bytes, bool flip}) job) =>
    Uint8List.fromList(
      image.encodeJpg(_upright(job.bytes, flip: job.flip), quality: 90),
    );

/// [processCapture] for pixels that are already decoded and upright.
ProcessedCapture processRawCapture(RawCaptureJob job) => _finish(
  image.Image.fromBytes(
    width: job.width,
    height: job.height,
    bytes: job.rgba.buffer,
    bytesOffset: job.rgba.offsetInBytes,
    numChannels: 4,
    order: image.ChannelOrder.rgba,
  ),
  job.eclat,
);
