import { drawSmoothed, clampStrength } from './smoothing.mjs';
const base = new URL('./vendor/', import.meta.url);
let detectorPromise, active = null, generation = 0;
function detector() {
  return detectorPromise ??= import(new URL('vision_bundle.mjs', base).href).then(async ({FaceLandmarker, FilesetResolver}) => {
    if (!await FilesetResolver.isSimdSupported()) throw new Error('Face smoothing requires WebAssembly SIMD');
    const vision = await FilesetResolver.forVisionTasks(new URL('wasm/', base).href);
    return FaceLandmarker.createFromOptions(vision, {
      baseOptions: {modelAssetPath: new URL('face_landmarker.task', base).href, delegate: 'CPU'},
      runningMode: 'VIDEO', numFaces: 1,
      minFaceDetectionConfidence: .7, minFacePresenceConfidence: .7, minTrackingConfidence: .7,
    });
  }).catch(error => { detectorPromise = null; throw error; });
}
function videos(root = document) {
  const found = [...root.querySelectorAll('video')];
  for (const el of root.querySelectorAll('*')) if (el.shadowRoot) found.push(...videos(el.shadowRoot));
  return found.filter(v => v.srcObject && v.readyState >= 2 && v.videoWidth && v.isConnected);
}
function stop() {
  generation++;
  if (active) { cancelAnimationFrame(active.frame); active.canvas.remove(); active = null; }
}
let lastDetectionTime = 0;
function render(state) {
  const {video, canvas, layer, detector, input} = state;
  input.width = 320; input.height = Math.max(1, Math.round(320 * video.videoHeight / video.videoWidth));
  input.getContext('2d').drawImage(video, 0, 0, input.width, input.height);
  const timestamp = Math.max(performance.now(), lastDetectionTime + .01);
  lastDetectionTime = timestamp;
  const landmarks = detector.detectForVideo(input, timestamp).faceLandmarks[0];
  if (canvas.width !== video.videoWidth || canvas.height !== video.videoHeight) {
    canvas.width = video.videoWidth; canvas.height = video.videoHeight;
  }
  drawSmoothed(video, canvas, layer, landmarks, state.strength);
  const style = getComputedStyle(video);
  canvas.style.transform = style.transform;
  canvas.style.objectFit = style.objectFit;
  canvas.style.objectPosition = style.objectPosition;
}
window.digiFaceFilter = {
  async start(strength) {
    stop(); const epoch = generation;
    const model = await detector();
    if (epoch !== generation) return false;
    const candidates = videos();
    if (candidates.length !== 1) return false;
    const video = candidates[0], canvas = document.createElement('canvas');
    const parent = video.parentElement;
    if (!parent) return false;
    // The camera plugin owns a full-size div with the video as its only child.
    canvas.style.cssText = 'position:absolute;inset:0;width:100%;height:100%;object-fit:contain;pointer-events:none;';
    parent.style.position = 'relative';
    const state = {video,canvas,layer:document.createElement('canvas'),input:document.createElement('canvas'),detector:model,strength:clampStrength(strength),frame:0,last:0};
    render(state); parent.append(canvas); active = state;
    function tick(now) {
      if (active !== state) return;
      if (!video.isConnected || !video.srcObject) { stop(); return; }
      if (now - state.last >= 80 && !document.hidden) {
        try { render(state); state.last = now; }
        catch { stop(); return; }
      }
      state.frame = requestAnimationFrame(tick);
    }
    state.frame = requestAnimationFrame(tick);
    return true;
  },
  strength(value) { if(active) active.strength = clampStrength(value); },
  stop,
  async capture() {
    if (!active) throw new Error('Face filter unavailable');
    const state = active;
    render(state);
    const blob = await new Promise(resolve => state.canvas.toBlob(resolve, 'image/png'));
    if (!blob) throw new Error('Could not capture filtered frame');
    return new Uint8Array(await blob.arrayBuffer());
  },
};
