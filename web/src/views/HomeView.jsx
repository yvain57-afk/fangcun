import { useCallback, useState } from 'react';
import { ArrowUpRight, ChevronRight, Droplets, Moon, Heart, ArrowRight, Wind, X } from 'lucide-react';
import Companions from '../components/Companions.jsx';
import Modal from '../components/Modal.jsx';
import { companionScene } from '../models/companionScenes.js';
import { SCENARIOS } from '../models/mock.js';
import { totalDrinks } from '../models/drinks.js';

export default function HomeView({ scenario, setScenario, onStart, onEvidence, onDrinks, onTrends, log, reduced, sessions }) {
  const data = SCENARIOS[scenario];
  const totals = totalDrinks(log.entries);
  const [showCompanions, setShowCompanions] = useState(false);
  const [replay, setReplay] = useState(0);
  const closeCompanions = useCallback(() => setShowCompanions(false), []);
  const companion = companionScene({ mood: scenario });
  return <div className="home-view view-enter">
    <div className="scenario-control"><span>演示情景</span><div className="scenario-tabs" role="group" aria-label="切换演示情景">{Object.entries(SCENARIOS).map(([key, value]) => <button key={key} aria-pressed={scenario === key} onClick={() => setScenario(key)}>{value.label}</button>)}</div></div>
    <section className={`hero-card ${scenario}`} aria-labelledby="home-conclusion">
      <div className="hero-topline"><span className={`status-pill ${scenario}`}><i />{data.status}</span><span className="eyebrow">今日 · 09:41</span></div>
      <h1 id="home-conclusion">{data.title}</h1>
      <div className="hero-body"><p className="hero-subtitle">{data.description}</p><button className="companion-peek" aria-label={scenario === 'stable' ? '看看猫狗的陪伴动作' : scenario === 'elevated' ? '看看小狗的陪伴动作' : '看看猫咪的陪伴动作'} onClick={() => setShowCompanions(true)}><Companions key={scenario} mood={scenario} reduced={reduced} /><span>{scenario === 'stable' ? '看看它们' : '看看它'} ↗</span></button></div>
      <p className="hero-evidence"><span className="small-dot" />{data.evidence}</p>
    </section>
    <button className="primary-button breath-cta" onClick={onStart}><span className="button-icon"><Wind size={23} /></span><span>开始 5 分钟呼吸<small>双吸一呼 · 留一点时间给自己</small></span><ArrowUpRight size={22} /></button>
    <section className="evidence-section"><div className="section-heading"><h2>身体给的线索</h2><span>示例数据</span></div>
      <button className="evidence-card" onClick={onEvidence} aria-label="为什么这样判断">
        <div className="evidence-metrics"><div><span><Moon size={15} />昨晚睡眠</span><strong>{data.sleep}</strong></div><div><span><Heart size={15} />身体恢复</span><strong>{data.recovery}</strong></div></div>
        <div className="evidence-link"><span>为什么这样判断</span><ChevronRight size={17} /></div>
      </button>
    </section>
    <button className="drink-entry" onClick={onDrinks}><span className="drink-entry-icon"><Droplets size={23} /></span><span><strong>今天喝了什么？</strong><small>{log.entries.length ? `已记 ${log.entries.length} 杯 · 总液体 ${totals.fluidMl} ml` : '水、咖啡，或是别的什么'}</small></span><span className="entry-plus">＋</span></button>
    {sessions.length > 0 && <div className="home-completion"><span className="stamp-check">✓</span><p>今天，已经为自己留了片刻。<small>练习已记录；压力结论等待新数据更新。</small></p><ArrowRight size={17} /></div>}
    <button className="history-entry" onClick={onTrends}>看看这一周的节奏<ArrowRight size={17} /></button>
    <p className="home-signoff">不必把每一天，都过得很用力。</p>
    {showCompanions && <Modal label="猫狗的此刻" reduced={reduced} onClose={closeCompanions} className="companion-modal"><button className="icon-button companion-close" aria-label="关闭角色预览" onClick={closeCompanions}><X size={20} /></button><div className="companion-portrait"><Companions mood={scenario} reduced={reduced} replay={replay} /></div><h2>{scenario === 'elevated' ? '先靠一会儿。' : scenario === 'insufficient' ? '慢慢认识你的节奏。' : '就这样，待一会儿。'}</h2><p>{companion.label}。</p><div className="companion-preview-actions">{!reduced && <button className="secondary-button" onClick={() => setReplay(value => value + 1)}>再看一次动作</button>}<button className="secondary-button" onClick={closeCompanions}>回到今日</button></div></Modal>}
  </div>;
}
