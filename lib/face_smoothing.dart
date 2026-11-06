export 'face_smoothing_stub.dart'
    if (dart.library.io) 'face_smoothing_native.dart'
    if (dart.library.js_interop) 'face_smoothing_web.dart';
