import { useEffect, useRef, useState } from 'react';
import { artworkForScene } from '../models/characterMotion.js';
import { createArtworkRenderer } from './artworkRenderer.js';
import { CHARACTER_ARTWORKS } from '../models/characterAssets.js';
import { MOTION } from '../models/motionTokens.js';
import './characterArtwork.css';

export default function CharacterArtwork({ scene = 'home', mood = 'stable', reduced = false, paused = false, phase = 'inhale', breath, reaction = 0, className = '', asset: assetOverride, replay = 0 }) {
  const asset = assetOverride ?? artworkForScene(scene, mood);
  const artwork = CHARACTER_ARTWORKS[asset];
  const src = artwork.src;
  const canvas = useRef(null), root = useRef(null), latest = useRef(null), refresh = useRef(null);
  const [ready, setReady] = useState(false);
  latest.current = { reduced, paused, breath, reaction, replay };

  useEffect(() => {
    let disposed = false, contextLost = false, renderer, frame;
    let visible = true, time = 0, last = null, lastPaint = 0, paints = 0, blendTime = MOTION.feedbackBlend;
    let resetKey = `${replay}-${reaction}`, dirty = true;
    const element = root.current, currentCanvas = canvas.current;
    const picture = new Image();
    setReady(false);
    const blocked = () => document.hidden || !visible || !!element.closest('[inert]');
    function stop() { cancelAnimationFrame(frame); frame = null; last = null; }
    function wake() {
      if (!disposed && !contextLost && renderer && !frame && !blocked()) frame = requestAnimationFrame(tick);
    }
    function changed() { dirty = true; last = null; if (blocked()) stop(); else wake(); }
    function tick(now) {
      frame = null;
      if (disposed || contextLost || !renderer || blocked()) { last = null; return; }
      const state = latest.current;
      const still = state.paused || state.reduced || (asset === 'breathing' && !state.breath);
      const delta = last !== null && !still ? Math.min((now - last) / 1000, .1) : 0;
      time += delta;
      blendTime += delta;
      last = now;
      const key = `${state.replay}-${state.reaction}`;
      if (key !== resetKey) {
        // Start a new response from the currently drawn pose, even during a rapid second tap.
        renderer.retarget();
        time = 0; blendTime = 0; resetKey = key; dirty = true;
      }
      if (dirty || (!still && now - lastPaint >= 1000 / 30)) {
        const strength = state.breath ? Math.max(0, Math.min(1, (state.breath.get() - .64) / .36)) : 0;
        renderer.draw({ asset, time, breath: strength, reduced: state.reduced, reaction: state.reaction > 0, blend: state.reduced ? 1 : Math.min(1, blendTime / MOTION.feedbackBlend) });
        currentCanvas.dataset.motionTime = time.toFixed(3);
        currentCanvas.dataset.breath = strength.toFixed(4);
        currentCanvas.dataset.drawCount = String(++paints);
        lastPaint = now; dirty = false;
      }
      // Paused and reduced-motion artwork consumes no idle animation frames.
      const finished = (asset === 'dog-drink' && time >= (state.reaction > 0 ? .85 : 1.8)) || (asset === 'duo-complete' && time >= 1.3);
      if (!still && !finished) frame = requestAnimationFrame(tick);
      else last = null;
    }
    refresh.current = changed;
    const observer = new IntersectionObserver(entries => { visible = entries[0].isIntersecting; changed(); });
    observer.observe(element);
    const resize = new ResizeObserver(changed); resize.observe(element);
    // Modals and full-screen practice mark their background inert. Freeze those pets too.
    const inertObserver = new MutationObserver(changed);
    for (let node = element.parentElement; node; node = node.parentElement) inertObserver.observe(node, { attributes: true, attributeFilter: ['inert'] });
    document.addEventListener('visibilitychange', changed);
    const lost = event => { event.preventDefault(); contextLost = true; stop(); if (!disposed) setReady(false); };
    const restored = () => {
      if (disposed) return;
      contextLost = false;
      renderer?.dispose();
      try { renderer = createArtworkRenderer(currentCanvas, picture); setReady(!!renderer); changed(); } catch { setReady(false); }
    };
    currentCanvas.addEventListener('webglcontextlost', lost);
    currentCanvas.addEventListener('webglcontextrestored', restored);
    picture.onload = () => {
      if (disposed) return;
      try {
        renderer = createArtworkRenderer(currentCanvas, picture);
        if (renderer) {
          renderer.draw({ asset, time: 0, breath: 0, reduced: true });
          setReady(true); changed();
        }
      } catch { setReady(false); }
    };
    picture.src = src;
    return () => {
      disposed = true; stop(); refresh.current = null;
      observer.disconnect(); resize.disconnect(); inertObserver.disconnect();
      document.removeEventListener('visibilitychange', changed);
      currentCanvas.removeEventListener('webglcontextlost', lost);
      currentCanvas.removeEventListener('webglcontextrestored', restored);
      renderer?.dispose();
    };
  }, [src, asset]);
  useEffect(() => { refresh.current?.(); }, [reduced, paused, replay, reaction, breath]);

  const pose = scene === 'rest' ? 'rest' : asset === 'breathing' && paused ? 'pause' : asset === 'dog-drink' && reaction ? 'acknowledge' : artwork.pose;
  return <span ref={root} className={`companions character-artwork ${className}`} data-scene={scene} data-artwork={asset} data-character={artwork.cast} data-pose={pose} data-still={reduced || paused} data-phase={scene === 'breathing' ? (paused ? 'paused' : phase) : undefined} data-renderer={ready ? 'webgl' : 'image'} aria-hidden="true">
    <img src={src} alt="" className="artwork-fallback" style={{ visibility: ready ? 'hidden' : 'visible' }} draggable="false" />
    <canvas ref={canvas} className="artwork-canvas" style={{ visibility: ready ? 'visible' : 'hidden' }} />
  </span>;
}
