import { useState } from 'react';
import { Coffee, Droplets, Wine, CupSoda, Minus, Plus, Undo2, X, Check } from 'lucide-react';
import Modal from './Modal.jsx';
import Companions from './Companions.jsx';
import { PRESETS, countCategory, totalDrinks } from '../models/drinks.js';

export default function DrinkLogSheet({ log, dispatch, onClose, reduced, storageOK, coffeeMg }) {
  const [coffee, setCoffee] = useState('coffee');
  const [announcement, setAnnouncement] = useState('');
  const [reaction, setReaction] = useState(0);
  const totals = totalDrinks(log.entries);
  const rows = [
    { category: 'water', preset: 'water', label: '白水', Icon: Droplets },
    { category: 'coffee', preset: coffee, label: '咖啡', Icon: Coffee },
    { category: 'alcohol', preset: 'beer', label: '酒精', Icon: Wine },
    { category: 'sugary', preset: 'soda', label: '糖饮', Icon: CupSoda },
  ];
  function act(action, label) {
    dispatch({ ...action, coffeeMg });
    setAnnouncement(label);
    setReaction(value => value + 1);
  }
  return <Modal label="今日饮品记录" onClose={onClose} reduced={reduced} className="drink-modal">
    <div className="sheet-handle" />
    <header className="sheet-heading"><div><h2>今天喝了什么？</h2><p className="drink-response" role="status" aria-live="polite" aria-atomic="true">{announcement || '大概记一下，就很好。'}</p></div><Companions solo="dog" scene={reaction ? 'recorded' : 'drink'} reaction={reaction} reduced={reduced} className="drink-companion" /><button className="icon-button" aria-label="关闭饮品记录" onClick={onClose}><X size={20} /></button></header>
    <div className="drink-scroll">
      {rows.map(({ category, preset, label, Icon }) => <div className="drink-row" key={category}>
        <span className={`drink-icon ${category}`}><Icon size={20} strokeWidth={1.6} /></span>
        <div className="drink-description"><div className="drink-name">{label}{category === 'coffee' && <select aria-label="咖啡类型" value={coffee} onChange={e => setCoffee(e.target.value)}><option value="coffee">美式</option><option value="sweetCoffee">甜拿铁</option></select>}</div><small>{category === 'coffee' ? `300 ml · 约 ${coffeeMg} mg${coffee === 'sweetCoffee' ? ' · 含糖' : ''}` : PRESETS[preset].size}</small></div>
        <div className="stepper" aria-label={`${label}杯数`}>
          <button aria-label={`减少${label}`} disabled={!countCategory(log.entries, category)} onClick={() => act({ type: 'remove', category }, `已减少一杯${label}`)}><Minus size={16} /></button>
          <output aria-label={`${label}数量`}>{countCategory(log.entries, category)}</output>
          <button aria-label={`增加${label}`} onClick={() => act({ type: 'add', preset }, `已增加一杯${PRESETS[preset].name}`)}><Plus size={16} /></button>
        </div>
      </div>)}
      <p className="sheet-footnote">每杯只计一次；液体量含各类饮品。成分为预设估算。</p>
      {!storageOK && <p className="storage-note" role="status">浏览器暂不能保存，刷新后本次记录可能丢失。</p>}
    </div>
      <div className="drink-totals" aria-label="饮品实时汇总">
        <div><strong data-testid="total-fluid">{totals.fluidMl}<small> ml</small></strong><span>总液体</span></div>
        <div><strong data-testid="total-caffeine">{totals.caffeineMg}<small> mg</small></strong><span>咖啡因</span></div>
        <div><strong data-testid="total-alcohol">{totals.alcoholG}<small> g</small></strong><span>酒精</span></div>
        <div><strong data-testid="total-sugar">{totals.sugarServings}<small> 份</small></strong><span>含糖饮品</span></div>
      </div>
    <footer className="sheet-actions"><button className="undo-button" disabled={!log.history.length} onClick={() => act({ type: 'undo' }, '已撤销上一笔')}><Undo2 size={16} />撤销上一笔</button><button className="compact-primary" onClick={onClose}><Check size={17} />记好了</button></footer>
  </Modal>;
}
