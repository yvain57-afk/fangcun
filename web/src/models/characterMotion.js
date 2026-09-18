// Local deformation of generated artwork, in normalized image coordinates.
// No replacement outlines, cut-apart necks, or changes to the saved source PNG.
const clamp = value => Math.max(0, Math.min(1, value));
function area(x, y, cx, cy, rx, ry) {
  const q = clamp(1 - ((x - cx) / rx) ** 2 - ((y - cy) / ry) ** 2);
  return q * q;
}
function gesture(time, duration) {
  if (time <= 0 || time >= duration) return 0;
  return Math.sin(Math.PI * time / duration) ** 2;
}
// A broad center moves the face as one piece; only the outer edge feathers into the body.
function headRegion(x, y, cx, cy, rx, ry) {
  const radius = Math.sqrt(((x - cx) / rx) ** 2 + ((y - cy) / ry) ** 2);
  const edge = clamp((1 - radius) / .4);
  return edge * edge * (3 - 2 * edge);
}
export function deformArtworkPoint(x, y, { asset, time = 0, breath = 0, reduced = false, reaction = false }) {
  if (reduced) return [x, y];
  let dx = 0, dy = 0;
  // Every scene preserves the planted feet and the outer paper edge.
  const grounded = clamp((.79 - y) / .11);
  if (asset === 'breathing') {
    const chest = area(x, y, .52, .58, .35, .32);
    const fixedFeet = clamp((.82 - y) / .16);
    dx = (x - .52) * .065 * breath * chest * fixedFeet;
    dy = -.018 * breath * chest * fixedFeet;
  } else if (asset === 'dog-greeting' || asset === 'duo-calm') {
    const hello = gesture(time % 14, 2.2);
    const wag = hello * Math.sin(time * 5);
    const tailX = asset === 'dog-greeting' ? .78 : .80;
    dx = .015 * wag * area(x, y, tailX, .74, .10, .12);
    dy = -.010 * wag * area(x, y, tailX, .74, .10, .12);
    const cx = asset === 'dog-greeting' ? .5 : .67;
    const cy = .43, angle = .025 * hello;
    const mask = headRegion(x, y, cx, cy, asset === 'dog-greeting' ? .33 : .22, .28) * grounded;
    dx += -(y - cy) * angle * mask;
    dy += (x - cx) * angle * mask;
  } else if (asset === 'dog-rest') {
    const slow = (1 - Math.cos(time * Math.PI / 4)) / 2;
    dy = -.0045 * slow * area(x, y, .72, .53, .18, .20) * grounded;
  } else if (asset === 'cat-curious') {
    const look = gesture(time % 16, 3.2);
    const head = headRegion(x, y, .54, .43, .31, .32);
    dx = (.008 - (y - .43) * .024) * head * look * grounded;
    dy = (.004 + (x - .54) * .024) * head * look * grounded;
  } else if (asset === 'dog-drink') {
    const nod = gesture(time, reaction ? .85 : 1.8);
    dy = .014 * nod * headRegion(x, y, .51, .43, .30, .30) * grounded;
  } else if (asset === 'duo-complete') {
    const touch = gesture(time, 1.3);
    dx = (x < .5 ? 1 : -1) * .007 * touch * area(x, y, .51, .61, .15, .14);
    dy = -.005 * touch * area(x, y, .51, .61, .15, .14);
  }
  return [x + dx, y + dy];
}
export function artworkForScene(scene, mood) {
  if (scene === 'breathing' || scene === 'practice') return 'breathing';
  if (scene === 'drink' || scene === 'recorded') return 'dog-drink';
  if (scene === 'complete') return 'duo-complete';
  if (scene === 'rest' || mood === 'elevated') return 'dog-rest';
  if (mood === 'insufficient') return 'cat-curious';
  return 'duo-calm';
}
