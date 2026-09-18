import { ArrowLeft, Moon, Activity, Footprints, Clock3 } from 'lucide-react';
import { SCENARIOS } from '../models/mock.js';

export default function EvidenceView({ scenario, onBack, onStart }) {
  const data = SCENARIOS[scenario];
  return <div className="detail-view view-enter"><button className="back-button" onClick={onBack}><ArrowLeft size={20} />返回今日</button>
    <span className="eyebrow">看懂身体的线索</span><h1>为什么<br />这样判断？</h1><p className="page-intro">{data.description}</p>
    <div className={`conclusion-inline ${scenario}`}><span className={`status-pill ${scenario}`}><i />{data.status}</span><span>以当前可用数据为依据</span></div>
    <article className="detail-block"><Moon size={23} /><div><h2>昨晚的睡眠</h2><strong>{data.sleep}</strong><p>{data.sleepNote}。</p></div></article>
    <article className="detail-block"><Activity size={23} /><div><h2>身体的恢复</h2><div className="detail-numbers"><span>静息心率<strong>{data.heartRate}</strong></span><span>HRV<strong>{data.hrv}</strong></span></div><p>{data.recoveryNote}。</p></div></article>
    <article className="detail-block"><Footprints size={23} /><div><h2>活动与训练背景</h2><strong>{data.movement}</strong><p>运动记录帮助理解恢复背景，不单独决定压力结论。</p></div></article>
    <div className="data-caption"><Clock3 size={16} /><p>示例时间：9 月 17 日 09:41<br /><span>本页为内置演示数据，未连接 Apple 健康。身体负荷也不能概括全部感受。</span></p></div>
    <button className="primary-button" onClick={onStart}>从 5 分钟呼吸开始<span>↗</span></button>
  </div>;
}
