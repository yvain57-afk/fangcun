import { useState } from 'react';
import { ArrowLeft, Moon, Footprints, Wind, Coffee, ChevronRight } from 'lucide-react';
import { WEEK, SCENARIOS } from '../models/mock.js';
import { totalDrinks } from '../models/drinks.js';
import { formatTime } from '../models/breathing.js';

export default function TrendsView({ scenario, log, sessions, onBack, onDrinks }) {
  const [selected, setSelected] = useState(6);
  const day = WEEK[selected];
  const state = day.today ? scenario : day.state;
  const data = SCENARIOS[state];
  const totals = totalDrinks(log.entries);
  return <div className="trends-view view-enter"><button className="back-button" onClick={onBack}><ArrowLeft size={20} />返回</button><span className="eyebrow">慢慢看见，自己的节奏</span><h1>这一周的你</h1><p className="page-intro">每一天不同，也都值得被看见。</p>
    <section className="week-card"><div className="section-heading"><h2>9.11 — 9.17</h2><span className="week-pill">周视图</span></div><div className="week-chart" role="group" aria-label="选择日期查看状态">
      {WEEK.map((entry, index) => { const s = entry.today ? scenario : entry.state; return <button key={entry.day} className={`day-bar ${s} ${selected === index ? 'selected' : ''}`} aria-pressed={selected === index} aria-label={`9月${entry.day}日 ${SCENARIOS[s].label}`} onClick={() => setSelected(index)}><span className="weekday">{entry.weekday}</span><div className="bar-track"><i /></div><span className="date-number">{entry.today ? '今' : entry.day}</span></button>; })}
    </div><div className="chart-legend"><span><i className="stable" />平稳</span><span><i className="elevated" />偏高</span><span><i className="insufficient" />数据不足</span></div><p className="chart-caption">柱形表示状态类别，不是压力分数。</p></section>
    <section className="day-snapshot" aria-live="polite"><div className="section-heading"><h2>{day.date}{day.today ? ' · 今日' : ''}</h2><span className={`status-pill ${state}`}><i />{data.status}</span></div>
      <div className="snapshot-row"><Moon size={19} /><span>睡眠<strong>{day.today ? data.sleep : day.sleep}</strong></span></div>
      <div className="snapshot-row"><Footprints size={19} /><span>活动<strong>{day.today ? data.movement : day.activity}</strong></span></div>
      <div className="snapshot-row"><Wind size={19} /><span>留给自己的时间<strong>{day.today ? sessions.length ? `已记录 ${sessions.length} 次 · ${formatTime(sessions.reduce((n, s) => n + s.duration, 0))}` : '今天还没有练习记录' : day.practice}</strong></span></div>
      <div className="snapshot-row"><Coffee size={19} /><span>生活记录<strong>{day.today ? log.entries.length ? `总液体 ${totals.fluidMl} ml · 咖啡因 ${totals.caffeineMg} mg` : '今天还没有饮品记录' : day.drinks}</strong></span></div>
      {day.today && <button className="inline-link" onClick={onDrinks}>补充或修改今天的饮品<ChevronRight size={17} /></button>}
    </section><p className="data-disclosure">过去 6 天为内置示例；今日快照联动当前演示情景和本机记录。空缺的日子不会补成平稳。</p>
  </div>;
}
