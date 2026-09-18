import { useCallback, useEffect, useRef, useState } from 'react';
import { useReducedMotion } from 'framer-motion';
import { Sun, Moon, Type, Home, Wind, Settings, Wifi, BatteryFull, ArrowUpRight } from 'lucide-react';
import HomeView from './views/HomeView.jsx';
import EvidenceView from './views/EvidenceView.jsx';
import PracticeView from './views/PracticeView.jsx';
import TrendsView from './views/TrendsView.jsx';
import SettingsView from './views/SettingsView.jsx';
import BreathingSessionView from './views/BreathingSessionView.jsx';
import CompletionView from './views/CompletionView.jsx';
import DrinkLogSheet from './components/DrinkLogSheet.jsx';
import BrandMark from './components/BrandMark.jsx';
import { EMPTY_LOG, changeLog, validLog, localDayKey } from './models/drinks.js';

function readSaved(key, fallback, valid = () => true) {
  try { const value = JSON.parse(localStorage.getItem(key)); return value !== null && valid(value) ? value : fallback; } catch { return fallback; }
}
const DAY = localDayKey();
const LOG_KEY = `fangcun:drinks:v2:${DAY}`;
const SESSION_KEY = `fangcun:sessions:v1:${DAY}`;

export default function App() {
  const [theme, setTheme] = useState(() => readSaved('fangcun:theme', 'light', v => ['light', 'dark'].includes(v)));
  const [large, setLarge] = useState(() => readSaved('fangcun:large', false, v => typeof v === 'boolean'));
  const systemReduced = useReducedMotion();
  const [reduceOverride, setReduceOverride] = useState(null);
  const reduced = reduceOverride ?? systemReduced ?? false;
  const [coffeeMg, setCoffeeMg] = useState(() => readSaved('fangcun:coffee', 140, n => Number.isFinite(n) && n >= 0 && n <= 500));
  const [scenario, setScenario] = useState('stable');
  const [tab, setTab] = useState('home');
  const [page, setPage] = useState(null);
  const [drinksOpen, setDrinksOpen] = useState(false);
  const [log, setLog] = useState(() => readSaved(LOG_KEY, EMPTY_LOG, validLog));
  const [sessions, setSessions] = useState(() => readSaved(SESSION_KEY, [], v => Array.isArray(v) && v.every(s => typeof s.id === 'string' && Number.isFinite(s.duration) && s.duration >= 0 && s.duration <= 300)));
  const [storageOK, setStorageOK] = useState(true);
  const [session, setSession] = useState(null);
  const [result, setResult] = useState(null);
  const scroll = useRef(null);
  const startTrigger = useRef(null);
  useEffect(() => {
    try {
      localStorage.setItem(LOG_KEY, JSON.stringify(log)); localStorage.setItem(SESSION_KEY, JSON.stringify(sessions));
      localStorage.setItem('fangcun:theme', JSON.stringify(theme)); localStorage.setItem('fangcun:large', JSON.stringify(large)); localStorage.setItem('fangcun:coffee', JSON.stringify(coffeeMg)); setStorageOK(true);
    } catch { setStorageOK(false); }
  }, [log, sessions, theme, large, coffeeMg]);
  useEffect(() => { document.documentElement.dataset.theme = theme; document.documentElement.dataset.large = String(large); document.documentElement.dataset.reduced = String(reduced); }, [theme, large, reduced]);
  useEffect(() => { scroll.current?.scrollTo({ top: 0 }); }, [tab, page]);
  const openDrinks = useCallback(() => setDrinksOpen(true), []);
  const closeDrinks = useCallback(() => setDrinksOpen(false), []);
  const dispatchDrink = useCallback(action => setLog(old => changeLog(old, action)), []);
  const start = useCallback(() => { startTrigger.current = document.activeElement; setSession({ id: crypto.randomUUID() }); }, []);
  const finish = useCallback(({ duration, completed }) => {
    const record = { id: session?.id, duration, completed, date: new Date().toISOString() };
    if (duration > 0) setSessions(old => old.some(s => s.id === record.id) ? old : [...old, record]);
    setResult(record); setSession(null);
  }, [session?.id]);
  function returnHome(feedback) {
    if (feedback && result) setSessions(old => old.map(s => s.id === result.id ? { ...s, feedback } : s));
    setResult(null); setTab('home'); setPage(null);
    requestAnimationFrame(() => { scroll.current?.scrollTo({ top: 0 }); document.querySelector('.breath-cta')?.focus({ preventScroll: true }); });
  }
  function chooseTab(next) { setTab(next); setPage(null); }
  const settingsProps = { theme, setTheme, large, setLarge, reduced, setReduceOverride, coffeeMg, setCoffeeMg, onTrends: () => setPage('trends') };
  return <main className="prototype-stage">
    <aside className="design-intro"><span className="intro-label"><i />方寸 · 交互设计预览</span><h1>给自己<br />留一点<span>空白。</span></h1><p>看懂身体的信号，<br />再轻轻回到自己的节奏。</p><div className="intro-divider" /><div className="intro-palette"><i /><i /><i /><span>双色版画 · 安静陪伴</span></div><p className="intro-caption">方案 A 的清晰骨架<br />＋ 方案 B 的情境姿态</p><a className="reference-link" href="/reference.png" target="_blank" rel="noreferrer">查看最初的角色参考<ArrowUpRight size={15} /></a><a className="reference-link" href="/character-studio.html" target="_blank" rel="noreferrer">猫狗形态与动效工作台<ArrowUpRight size={15} /></a><a className="reference-link" href="/brand-studio.html" target="_blank" rel="noreferrer">方寸的寓意与标志<ArrowUpRight size={15} /></a></aside>
    <div className="preview-column"><div className="preview-label"><span>FANGCUN</span><span>可交互 · 示例数据</span></div>
      <div className={`phone-frame ${session || result ? 'immersive' : ''}`}>
        <div className="app-content" inert={session || result ? true : undefined}>
          <div className="status-bar" aria-hidden="true"><span>9:41</span><div><span className="signal">▂▄▆</span><Wifi size={14} /><BatteryFull size={19} /></div></div>
          <header className="app-header"><div className="brand-lockup"><BrandMark /><div><strong>方寸</strong><span>FANGCUN</span></div></div><div className="appearance-controls"><button className={`icon-button ${large ? 'selected' : ''}`} aria-label="切换大字号" aria-pressed={large} onClick={() => setLarge(!large)}><Type size={19} /><sup>＋</sup></button><button className="icon-button" aria-label="切换深浅色模式" aria-pressed={theme === 'dark'} onClick={() => setTheme(theme === 'dark' ? 'light' : 'dark')}>{theme === 'dark' ? <Sun size={20} /> : <Moon size={19} />}</button></div></header>
          <div className="app-scroll" ref={scroll}>
            {!page && tab === 'home' && <HomeView scenario={scenario} setScenario={setScenario} onStart={start} onEvidence={() => setPage('evidence')} onDrinks={openDrinks} onTrends={() => setPage('trends')} log={log} reduced={reduced} sessions={sessions} />}
            {!page && tab === 'practice' && <PracticeView onStart={start} reduced={reduced} />}
            {!page && tab === 'settings' && <SettingsView {...settingsProps} />}
            {page === 'evidence' && <EvidenceView scenario={scenario} onBack={() => setPage(null)} onStart={start} />}
            {page === 'trends' && <TrendsView scenario={scenario} log={log} sessions={sessions} onBack={() => setPage(null)} onDrinks={openDrinks} />}
          </div>
          <nav className="tab-bar" aria-label="主要导航">{[{ id: 'home', label: '今日', Icon: Home }, { id: 'practice', label: '练习', Icon: Wind }, { id: 'settings', label: '设置', Icon: Settings }].map(({ id, label, Icon }) => <button key={id} aria-current={tab === id ? 'page' : undefined} className={tab === id ? 'active' : ''} onClick={() => chooseTab(id)}><Icon size={21} strokeWidth={tab === id ? 2 : 1.6} /><span>{label}</span><i /></button>)}</nav>
          <div className="home-indicator" aria-hidden="true"><i /></div>
        </div>
        {session && <BreathingSessionView key={session.id} reduced={reduced} onFinish={finish} />}
        {result && <CompletionView result={result} onReturn={returnHome} reduced={reduced} storageOK={storageOK} />}
        <div id="overlay-host" />
        {drinksOpen && <DrinkLogSheet log={log} dispatch={dispatchDrink} onClose={closeDrinks} reduced={reduced} storageOK={storageOK} coffeeMg={coffeeMg} />}
      </div>
      <div className="preview-footer"><span>手机内可滚动、点击与记录</span><label><input type="checkbox" checked={reduced} onChange={e => setReduceOverride(e.target.checked)} />减少动态效果</label></div>
    </div>
    <aside className="test-guide"><span className="eyebrow">TRY A LITTLE</span><h2>从这里，感受方寸</h2><ol><li><span>01</span><p>换一种今日状态<small>平稳、偏高，或数据不足</small></p></li><li><span>02</span><p>记一杯甜拿铁<small>看看复合汇总，再撤销一次</small></p></li><li><span>03</span><p>跟着呼吸片刻<small>暂停、继续，也可以随时结束</small></p></li><li><span>04</span><p>试试夜间与大字<small>右上角即可切换</small></p></li></ol><div className="guide-footnote"><span>一切都可以慢慢来。</span><p>只使用示例健康数据。饮品与练习记录留在当前浏览器。</p></div></aside>
  </main>;
}
