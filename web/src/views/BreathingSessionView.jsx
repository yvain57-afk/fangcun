import { useCallback, useEffect, useRef, useState } from 'react';
import { motion, useTransform } from 'framer-motion';
import { X, Pause, Play, Wind } from 'lucide-react';
import Modal from '../components/Modal.jsx';
import Companions from '../components/Companions.jsx';
import useBreathing from '../hooks/useBreathing.js';
import { formatTime, SESSION_SECONDS, PHASES } from '../models/breathing.js';

export default function BreathingSessionView({ reduced, onFinish }) {
  const { elapsed, elapsedRef, phase, running, pause, resume, scale, backgroundPaused } = useBreathing(reduced);
  const [confirmExit, setConfirmExit] = useState(false);
  const previousRunning = useRef(false);
  const finished = useRef(false);
  const ringOpacity = useTransform(scale, [.64, 1], [.35, .85]);
  const heading = useRef(null);
  useEffect(() => { heading.current?.focus(); }, []);
  useEffect(() => {
    if (elapsed >= SESSION_SECONDS && !finished.current) {
      finished.current = true;
      onFinish({ duration: SESSION_SECONDS, completed: true });
    }
  }, [elapsed, onFinish]);
  const askExit = useCallback(() => { previousRunning.current = running; pause(); setConfirmExit(true); }, [running, pause]);
  const cancelExit = useCallback(() => { setConfirmExit(false); if (previousRunning.current) resume(); }, [resume]);
  function exit() {
    if (finished.current) return;
    finished.current = true;
    onFinish({ duration: Math.floor(elapsedRef.current), completed: false });
  }
  useEffect(() => {
    function handle(event) { if (event.key === 'Escape' && !confirmExit) { event.preventDefault(); askExit(); } }
    document.addEventListener('keydown', handle);
    return () => document.removeEventListener('keydown', handle);
  }, [askExit, confirmExit]);
  return <section className="breathing-session" aria-label="全屏呼吸练习" data-testid="breathing-session">
    <header className="session-header"><button className="text-button" onClick={askExit}><X size={20} />结束练习</button><span className="session-badge"><Wind size={15} />双吸一呼</span></header>
    <div className="session-content">
      <span className="eyebrow">这一刻，只需要呼吸</span>
      <h1 ref={heading} tabIndex={-1}>给自己，留一口气。</h1>
      <div className="breathing-stage" aria-hidden="true">
        <div className="breath-guide-ring outer" /><div className="breath-guide-ring inner" />
        <motion.div className="breath-expansion" style={reduced ? { opacity: ringOpacity } : { scale }} />
        <div className="breathing-pet"><Companions solo scene="breathing" phase={phase.id} paused={!running} breath={scale} reduced={reduced} /></div>
      </div>
      <div className="phase-readout" aria-live="polite" aria-atomic="true"><h2 data-testid="phase-label">{running ? phase.label : '停一下，也很好'}</h2><p>{running ? phase.hint : backgroundPaused ? '离开页面时已暂停，准备好再继续。' : '计时和节拍都已暂停，按自己的节奏来。'}</p></div>
      <div className="phase-track" aria-label={`第 ${phase.cycle} 轮，共 25 轮`}>{PHASES.map((p, i) => <div key={p.id} className={phase.phaseIndex === i ? 'active' : ''}><i /><span>{['吸气', '补吸', '呼气'][i]}</span></div>)}</div>
      <div className="session-timer"><span data-testid="remaining-time" role="timer" aria-label="剩余时间">{formatTime(SESSION_SECONDS - elapsed)}</span><small>剩余时间 · 第 {phase.cycle} / 25 轮</small></div>
      <div className="session-progress" role="progressbar" aria-valuenow={Math.floor(elapsed)} aria-valuemin={0} aria-valuemax={SESSION_SECONDS} aria-label="练习进度"><span style={{ width: `${elapsed / SESSION_SECONDS * 100}%` }} /></div>
      <button className="primary-button pause-button" onClick={running ? pause : resume}>{running ? <Pause size={20} /> : <Play size={20} />}{running ? '暂停练习' : '继续练习'}</button>
      <p className="session-safety">不用刻意吸满。不舒服时，随时恢复自然呼吸。</p>
    </div>
    {confirmExit && <Modal label="结束这次练习" onClose={cancelExit} reduced={reduced} className="confirmation-modal"><div className="confirm-content"><span className="small-stamp">歇一歇</span><h2>今天先到这里，也可以。</h2><p>已练习 {formatTime(elapsedRef.current)}，计时已暂停。<br />这段留给自己的时间，会被好好记下。</p><button className="primary-button" onClick={cancelExit}>继续练习</button><button className="secondary-button" onClick={exit}>结束并记录</button></div></Modal>}
  </section>;
}
