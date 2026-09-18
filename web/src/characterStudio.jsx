import React, { useState } from 'react';
import { createRoot } from 'react-dom/client';
import { useReducedMotion } from 'framer-motion';
import CharacterArtwork from './components/CharacterArtwork.jsx';
import useBreathing from './hooks/useBreathing.js';
import './tokens.css';
import { CHARACTER_ARTWORKS } from './models/characterAssets.js';
import './characterStudio.css';

const entries = [
 ['dog-greeting', '重新认识小狗', '小狗 · 单独出场', '圆脸、短爪和两只垂耳，轻轻歪头看向你。'],
 ['cat-curious', '猫咪的观察时间', '猫咪独处 · 首页数据不足', '歪头看一眼小纸页，慢慢等身体的线索。'],
 ['breathing', '跟着一口呼吸', '猫咪独处 · 全屏练习', '保留这只猫咪，胸腹跟着双吸一呼起伏。'],
 ['dog-rest', '小狗陪你歇歇', '小狗独处 · 首页偏高 / 提前结束', '前爪收好，安静趴下来，身体缓缓起伏。'],
 ['dog-drink', '小狗陪你记一杯', '小狗独处 · 饮品记录', '坐在水杯旁，收到记录后轻轻点一下头。'],
 ['duo-calm', '偶尔，一起待着', '双角色 · 首页平稳', '猫咪和新小狗肩并肩，尾巴偶尔轻摆。'],
 ['duo-complete', '留给彼此的小回应', '双角色 · 练习完整结束', '练习结束时碰一下爪，不必一直成双出现。'],
];
function SceneCard({ entry, reduced, timer }) {
 const [asset, title, place, description] = entry;
 const [paused, setPaused] = useState(false), [replay, setReplay] = useState(0);
 const isPaused = timer ? !timer.running : paused;

 return <article><div className="card-top"><span>{place}</span><span className="art-number">0{entries.indexOf(entry)+1}</span></div>
 <div className="art-preview"><CharacterArtwork asset={asset} scene={asset === 'breathing' ? 'breathing' : asset} reduced={reduced} paused={isPaused} replay={replay} reaction={asset === 'dog-drink' ? replay+1 : 0} breath={asset === 'breathing' ? timer?.scale : undefined} phase={timer?.phase.id} /></div>
 <h2>{title}</h2><p>{description}</p><footer><button onClick={() => { setReplay(v=>v+1); setPaused(false); timer?.reset(); }}>重播动作</button><button aria-pressed={isPaused} onClick={() => {setPaused(!isPaused); isPaused ? timer?.resume() : timer?.pause();}}>{isPaused ? '继续' : '暂停'}</button><a href={CHARACTER_ARTWORKS[asset].src} target="_blank" rel="noreferrer">看原画 ↗</a></footer>
 {asset === 'breathing' && <div className="breathing-label">{isPaused ? '已暂停' : timer.phase.label} · 4 秒吸气 / 1 秒补吸 / 7 秒呼气</div>}
 </article>;
}
function Studio() {
 const systemReduced=useReducedMotion(),[reduceOverride,setReduceOverride]=useState(null),[dark,setDark]=useState(false);
 const reduced=reduceOverride??systemReduced??false;
 const timer = useBreathing(reduced);
 return <div className="studio" data-theme={dark?'dark':'light'}><header><div><span className="kicker">FANGCUN / CHARACTER STUDIES 04</span><h1>各自可爱，<br/><em>也会一起陪你。</em></h1><p>猫咪保留，小狗重新设计。给它们各自的出场时刻。</p></div><div className="studio-tools"><a href="/">打开 App 原型 ↗</a><button onClick={()=>setDark(!dark)}>{dark?'浅色背景':'深色背景'}</button><label><input type="checkbox" checked={reduced} onChange={e=>setReduceOverride(e.target.checked)} />减少动态效果</label></div></header><main>{entries.map(entry=><SceneCard key={entry[0]} entry={entry} reduced={reduced} timer={entry[0] === 'breathing' ? timer : undefined} />)}</main><div className="studio-note">新画稿由 imagegen 基于猫咪与新小狗参考生成；呼吸猫咪沿用原画。动作使用原画局部变形。小幅动作请点击重播观察；减少动态效果时保留静态画稿。</div></div>;
}
createRoot(document.getElementById('root')).render(<Studio/>);
