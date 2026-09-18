import { Moon, Type, Feather, ChartColumn, ChevronRight, Coffee, ShieldCheck, MonitorSmartphone } from 'lucide-react';
import BrandMark from '../components/BrandMark.jsx';
export default function SettingsView({ theme, setTheme, large, setLarge, reduced, setReduceOverride, coffeeMg, setCoffeeMg, onTrends }) {
  return <div className="settings-view view-enter"><span className="eyebrow">舒服的方式，由你决定</span><h1>设置</h1><p className="page-intro">少一点打扰，多一点自在。</p>
    <section className="settings-group"><h2>显示与动效</h2>
      <button className="settings-row" onClick={() => setTheme(theme === 'dark' ? 'light' : 'dark')} aria-pressed={theme === 'dark'}><Moon size={20} /><span>深色模式</span><i className={`switch ${theme === 'dark' ? 'on' : ''}`} /></button>
      <button className="settings-row" onClick={() => setLarge(!large)} aria-pressed={large}><Type size={20} /><span>较大字号</span><i className={`switch ${large ? 'on' : ''}`} /></button>
      <button className="settings-row" onClick={() => setReduceOverride(!reduced)} aria-pressed={reduced}><Feather size={20} /><span>减少动态效果</span><i className={`switch ${reduced ? 'on' : ''}`} /></button>
    </section>
    <section className="settings-group"><h2>记录与预设</h2><button className="settings-row" onClick={onTrends}><ChartColumn size={20} /><span>历史与趋势</span><ChevronRight size={18} /></button><label className="settings-row coffee-setting"><Coffee size={20} /><span>每杯咖啡因<small>仅影响之后新增的咖啡记录</small></span><input aria-label="每杯咖啡因毫克数" type="number" min="0" max="500" step="10" value={coffeeMg} onChange={e => { const n = Number(e.target.value); if (Number.isFinite(n)) setCoffeeMg(Math.max(0, Math.min(500, n))); }} /><small>mg</small></label></section>
    <section className="privacy-card"><ShieldCheck size={23} /><div><h2>你的记录，留在本机</h2><p>饮品和练习保存在当前浏览器。没有账号，不上传健康数据。</p></div></section>
    <section className="prototype-note"><MonitorSmartphone size={20} /><p>交互测试原型 · v0.1<br /><span>健康结论使用示例数据，尚未连接 Apple 健康。浏览器不模拟原生 Taptic 触感。</span></p></section>
    <div className="settings-brand"><BrandMark />方寸<span>给自己，留一点空间。</span><a href="/brand-studio.html">方寸的寓意与设计 ↗</a></div>
  </div>;
}
