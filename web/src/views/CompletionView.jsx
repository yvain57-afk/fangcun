import { useState } from 'react';
import { Check, ArrowRight } from 'lucide-react';
import Companions from '../components/Companions.jsx';
import BrandMark from '../components/BrandMark.jsx';
import { formatTime } from '../models/breathing.js';

export default function CompletionView({ result, onReturn, reduced, storageOK }) {
  const [feedback, setFeedback] = useState('');
  return <section className="completion-view view-enter" aria-label="练习记录结果"><div className="completion-signature"><BrandMark /><span>方寸 · 片刻</span></div>
    <Companions scene={result.completed ? 'complete' : 'rest'} reduced={reduced} />
    <span className="eyebrow">一小段时间，也算数</span>
    <h1>{result.completed ? '这 5 分钟，属于你。' : '这次，就到这里。'}</h1>
    <p>生理性叹息 · {formatTime(result.duration)}</p>
    <span className="save-status"><Check size={15} />{result.duration === 0 ? '尚未产生练习记录' : storageOK ? '已记录在本机' : '已记在本次会话，浏览器暂不能持久保存'}</span>
    <div className="feedback-card"><h2>现在感觉如何？<small>可跳过</small></h2><div>{['轻松一些', '差不多'].map(label => <button key={label} aria-pressed={feedback === label} onClick={() => setFeedback(feedback === label ? '' : label)}>{label}</button>)}</div></div>
    <button className="primary-button" onClick={() => onReturn(feedback)}>返回今日首页<ArrowRight size={19} /></button><p className="completion-note">压力结论等待新数据更新。<br />这次练习没有写入 Apple 健康。</p>
  </section>;
}
