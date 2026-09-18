import { cubicBezier } from 'framer-motion';
import { MOTION } from '../models/motionTokens.js';
import { deformArtworkPoint } from '../models/characterMotion.js';

export function createArtworkRenderer(canvas, image) {
  const gl = canvas.getContext('webgl', { alpha: false, antialias: true, premultipliedAlpha: false });
  if (!gl) return null;
  const resources = [];
  const blendEase = cubicBezier(...MOTION.easeOut);
  let previousPose = null;
  function shader(type, source) {
    const item = gl.createShader(type); gl.shaderSource(item, source); gl.compileShader(item);
    if (!gl.getShaderParameter(item, gl.COMPILE_STATUS)) throw new Error('Artwork shader unavailable');
    resources.push(item); return item;
  }
  const program = gl.createProgram();
  gl.attachShader(program, shader(gl.VERTEX_SHADER, 'attribute vec2 aPosition; attribute vec2 aUV; varying vec2 vUV; uniform vec2 uFit; void main(){vUV=aUV; gl_Position=vec4(vec2(aPosition.x*2.0-1.0,1.0-aPosition.y*2.0)*uFit,0.0,1.0);}'));
  gl.attachShader(program, shader(gl.FRAGMENT_SHADER, 'precision mediump float; varying vec2 vUV; uniform sampler2D uImage; void main(){vec4 c=texture2D(uImage,vUV);gl_FragColor=vec4(mix(vec3(1.0),c.rgb,c.a),1.0);}'));
  gl.linkProgram(program);
  if (!gl.getProgramParameter(program, gl.LINK_STATUS)) throw new Error('Artwork program unavailable');
  gl.useProgram(program);
  const columns = 32, rows = 24, coordinates = [];
  for (let row = 0; row <= rows; row++) for (let col = 0; col <= columns; col++) coordinates.push([col / columns, row / rows]);
  const values = new Float32Array(coordinates.length * 4);
  const indices = [];
  for (let row = 0; row < rows; row++) for (let col = 0; col < columns; col++) {
    const i = row * (columns + 1) + col;
    indices.push(i, i + 1, i + columns + 1, i + 1, i + columns + 2, i + columns + 1);
  }
  const buffer = gl.createBuffer(); gl.bindBuffer(gl.ARRAY_BUFFER, buffer);
  gl.bufferData(gl.ARRAY_BUFFER, values.byteLength, gl.DYNAMIC_DRAW);
  const indexBuffer = gl.createBuffer(); gl.bindBuffer(gl.ELEMENT_ARRAY_BUFFER, indexBuffer);
  gl.bufferData(gl.ELEMENT_ARRAY_BUFFER, new Uint16Array(indices), gl.STATIC_DRAW);
  for (const [name, offset] of [['aPosition', 0], ['aUV', 8]]) {
    const loc = gl.getAttribLocation(program, name); gl.enableVertexAttribArray(loc); gl.vertexAttribPointer(loc, 2, gl.FLOAT, false, 16, offset);
  }
  const texture = gl.createTexture(); gl.bindTexture(gl.TEXTURE_2D, texture);
  gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.CLAMP_TO_EDGE); gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.CLAMP_TO_EDGE);
  gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.LINEAR); gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.LINEAR);
  gl.texImage2D(gl.TEXTURE_2D, 0, gl.RGBA, gl.RGBA, gl.UNSIGNED_BYTE, image);
  const fitUniform = gl.getUniformLocation(program, 'uFit');
  return {
    retarget() { previousPose = values.slice(); },
    draw(state) {
      const box = canvas.getBoundingClientRect(), ratio = Math.min(devicePixelRatio || 1, 2);
      const w = Math.max(1, Math.round(box.width * ratio)), h = Math.max(1, Math.round(box.height * ratio));
      if (canvas.width !== w || canvas.height !== h) { canvas.width = w; canvas.height = h; }
      gl.viewport(0, 0, w, h); gl.clearColor(1, 1, 1, 1); gl.clear(gl.COLOR_BUFFER_BIT);
      const imageRatio = image.width / image.height, viewRatio = w / h;
      // Zoom only into the generated paper margin, never through the character edges.
      const zoom = state.asset.startsWith('duo-') ? 1.06 : 1.03;
      gl.uniform2f(fitUniform, Math.min(1, imageRatio / viewRatio) * zoom, Math.min(1, viewRatio / imageRatio) * zoom);
      const blend = blendEase(state.blend ?? 1);
      coordinates.forEach(([x, y], index) => {
        const point = deformArtworkPoint(x, y, state);
        const i = index * 4;
        const px = previousPose ? previousPose[i] + (point[0] - previousPose[i]) * blend : point[0];
        const py = previousPose ? previousPose[i + 1] + (point[1] - previousPose[i + 1]) * blend : point[1];
        values.set([px, py, x, y], i);
      });
      if (blend >= 1) previousPose = null;
      gl.bindBuffer(gl.ARRAY_BUFFER, buffer); gl.bufferSubData(gl.ARRAY_BUFFER, 0, values);
      gl.drawElements(gl.TRIANGLES, indices.length, gl.UNSIGNED_SHORT, 0);
    },
    dispose() { gl.deleteBuffer(buffer); gl.deleteBuffer(indexBuffer); gl.deleteTexture(texture); gl.deleteProgram(program); resources.forEach(s => gl.deleteShader(s)); }
  };
}
