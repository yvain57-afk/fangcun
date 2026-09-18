import { Wind, ArrowUpRight } from 'lucide-react';
import Companions from '../components/Companions.jsx';
export default function PracticeView({ onStart, reduced }) {
  return <div className="practice-library view-enter"><span className="eyebrow">给自己，一小段空白</span><h1>从一口呼吸开始</h1><p className="page-intro">不需要准备好心情，<br />找一个舒服的姿势就行。</p>
    <section className="practice-feature"><span className="status-pill stable"><Wind size={14} />呼吸练习</span><Companions scene="practice" reduced={reduced} /><h2>生理性叹息</h2><p>轻轻吸气，再补一小口，<br />随后用更长的时间慢慢呼出。</p><div className="practice-tags"><span>5 分钟</span><span>坐着或站着</span><span>双吸一呼</span></div><button className="primary-button" onClick={onStart}>开始练习<ArrowUpRight size={20} /></button></section>
    <div className="practice-instructions"><span>01</span><p><strong>不必追求吸满</strong>舒服地跟随，比做得标准更重要。</p><span>02</span><p><strong>可以随时停下来</strong>暂停和提前结束，都会保留你的选择。</p></div>
  </div>;
}
