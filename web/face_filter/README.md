# Face-only smoothing (web)

Opt-in controls on the shared public/partner PhotoScreen: off, light, medium.
Cheek and central forehead masks come from local MediaPipe landmarks. No face
means the original frame. Eyes, mouth, clothing and background are not blurred.
Capture uses the same canvas at camera resolution (PNG); gallery is unchanged.
Failure falls back to an unfiltered photo with a message. Android and iOS use
a separate ML Kit implementation in lib/face_smoothing_native.dart.

The model is lazy-loaded; frames and landmarks stay in this browser. CPU inference
is throttled to about 12 frames/sec. Check performance on target hardware.
Stop/restart Flutter and reload the browser after changing the web scripts.

Third party: @mediapipe/tasks-vision 0.10.32 (Apache-2.0, see vendor/LICENSE).
Runtime: https://cdn.jsdelivr.net/npm/@mediapipe/tasks-vision@0.10.32/
Model: https://storage.googleapis.com/mediapipe-models/face_landmarker/face_landmarker/float16/1/face_landmarker.task

Checks: node --test web/face_filter/smoothing.test.mjs
Manual acceptance: enable each strength, move/turn away, switch cameras, capture,
retake, leave the screen. Confirm no lingering overlay, unchanged clothing/eyes,
and photo appearance matches preview. Test public and partner flows.
Browser support requires WebAssembly SIMD; unsupported browsers retain the original camera.
Browser smoke test: node test/web_face_smoothing_smoke.mjs (Edge on Windows, synthetic video; does not validate smoothing quality on a real face).
