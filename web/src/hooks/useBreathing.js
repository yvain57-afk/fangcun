import { useEffect, useRef, useState, useCallback } from 'react';
import { useMotionValue } from 'framer-motion';
import { phaseAt, SESSION_SECONDS } from '../models/breathing.js';

export default function useBreathing(reduced) {
  const [elapsed, setElapsed] = useState(0);
  const [running, setRunning] = useState(true);
  const [backgroundPaused, setBackgroundPaused] = useState(false);
  const [resetVersion, setResetVersion] = useState(0);
  const elapsedRef = useRef(0);
  const scale = useMotionValue(phaseAt(0).scale);
  useEffect(() => {
    if (!running) return;
    let frame;
    const start = performance.now();
    const previous = elapsedRef.current;
    let lastUpdate = -1;
    function tick(now) {
      const time = Math.min(SESSION_SECONDS, previous + (now - start) / 1000);
      elapsedRef.current = time;
      // Reduced motion uses this same phase signal for opacity, never geometric scaling.
      scale.set(phaseAt(time).scale);
      if (time - lastUpdate > .07 || time === SESSION_SECONDS) { setElapsed(time); lastUpdate = time; }
      if (time < SESSION_SECONDS) frame = requestAnimationFrame(tick);
      else setRunning(false);
    }
    frame = requestAnimationFrame(tick);
    return () => cancelAnimationFrame(frame);
  }, [running, reduced, scale, resetVersion]);
  useEffect(() => {
    function onVisibility() {
      if (document.hidden && running) { setRunning(false); setBackgroundPaused(true); }
    }
    document.addEventListener('visibilitychange', onVisibility);
    return () => document.removeEventListener('visibilitychange', onVisibility);
  }, [running]);
  const pause = useCallback(() => { setRunning(false); setElapsed(elapsedRef.current); }, []);
  const resume = useCallback(() => { setBackgroundPaused(false); setRunning(true); }, []);
  const reset = useCallback(() => { elapsedRef.current = 0; setElapsed(0); scale.set(phaseAt(0).scale); setBackgroundPaused(false); setRunning(true); setResetVersion(v => v + 1); }, [scale]);
  return { elapsed, elapsedRef, phase: phaseAt(elapsed), running, pause, resume, reset, scale, backgroundPaused };
}
