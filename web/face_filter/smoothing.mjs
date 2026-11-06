// Conservative skin regions: cheeks and central forehead, excluding facial features.
export const SKIN_REGIONS = [
  [50, 101, 205, 187, 147, 123, 116, 117, 118, 119, 100],
  [280, 330, 425, 411, 376, 352, 345, 346, 347, 348, 329],
  [109, 108, 151, 337, 338, 10],
];
export function skinPolygons(landmarks, width, height) {
  if (!landmarks || landmarks.length < 468) return [];
  return SKIN_REGIONS.map(indices => indices.map(i => ({
    x: landmarks[i]?.x * width, y: landmarks[i]?.y * height,
  }))).filter(points => points.every(p => Number.isFinite(p.x) && Number.isFinite(p.y)));
}
export function clampStrength(value) {
  return Number.isFinite(value) ? Math.max(0, Math.min(1, value)) : 0;
}
export function drawSmoothed(source, output, layer, landmarks, strength) {
  const ctx = output.getContext('2d');
  const w = output.width, h = output.height;
  ctx.clearRect(0, 0, w, h);
  ctx.drawImage(source, 0, 0, w, h);
  strength = clampStrength(strength);
  const polygons = skinPolygons(landmarks, w, h);
  if (!strength || !polygons.length) return;
  layer.width = w; layer.height = h;
  const fx = layer.getContext('2d');
  // Softening is mild and blended; original detail remains visible.
  fx.filter = `blur(${Math.max(.6, w / 720 * (0.7 + strength * 1.3))}px)`;
  fx.drawImage(source, 0, 0, w, h);
  fx.filter = 'none';
  const path = new Path2D();
  for (const points of polygons) {
    path.moveTo(points[0].x, points[0].y);
    for (const p of points.slice(1)) path.lineTo(p.x, p.y);
    path.closePath();
  }
  ctx.save(); ctx.clip(path); ctx.globalAlpha = strength * .45;
  ctx.drawImage(layer, 0, 0); ctx.restore();
}
