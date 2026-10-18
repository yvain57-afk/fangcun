"""Package original simulator screenshots and videos; never redraw or retouch evidence."""
from pathlib import Path
import argparse, hashlib, html, json, shutil
p=argparse.ArgumentParser();p.add_argument('--work',required=True);p.add_argument('--output',required=True);a=p.parse_args()
work=Path(a.work).resolve();out=Path(a.output).resolve();out.mkdir(parents=True,exist_ok=True)
shots=out/'screenshots';shots.mkdir(exist_ok=True);videos=out/'videos';videos.mkdir(exist_ok=True)
records={}
for manifest in sorted(work.glob('capture*/attachments/manifest.json')):
 for test in json.loads(manifest.read_text()):
  for item in test.get('attachments',[]):
   src=manifest.parent/item['exportedFileName'];name=item.get('suggestedHumanReadableName','')
   if src.suffix.lower()!='.png' or not name[:2].isdigit():continue
   name=name.split('_0_')[0].removesuffix('.png');dest=shots/(name+'.png');shutil.copy2(src,dest)
   records[name]={'name':name,'file':'screenshots/'+dest.name,'test':test.get('testIdentifier',''),'resultBundle':manifest.parent.parent.name,'sha256':hashlib.sha256(dest.read_bytes()).hexdigest()}
items=sorted(records.values(),key=lambda x:x['name'])
(out/'截图清单.json').write_text(json.dumps(items,ensure_ascii=False,indent=2)+'\n')
names=[('physiologicalSigh','生理性叹息'),('pacedBreathing','节律呼吸'),('balancedBreathing','均衡慢呼吸'),('boxBreathing','方块呼吸'),('diaphragmaticBreathing','膈肌呼吸'),('alternateNostrilBreathing','交替鼻孔呼吸'),('meditation','冥想'),('nsdr','NSDR'),('kegel','凯格尔')]
clips=[]
for i,(kind,title) in enumerate(names,1):
 src=work/'motion'/(kind+'.mp4')
 if src.exists():
  dest=videos/(f'{i:02d}-'+title+'.mp4');shutil.copy2(src,dest)
  clips.append({'name':title,'file':'videos/'+dest.name,'sha256':hashlib.sha256(dest.read_bytes()).hexdigest()})
(out/'录像清单.json').write_text(json.dumps(clips,ensure_ascii=False,indent=2)+'\n')
rows=[]
for i,r in enumerate(items,1):
 n=html.escape(r['name']);f=html.escape(r['file'])
 rows.append(f'<article data-name="{n.lower()}"><a href="{f}" target="_blank"><img loading="lazy" src="{f}" alt="{n}"></a><p>{i:03d} · {n}</p><a href="{f}" download>原始 PNG</a></article>')
vr=[]
for r in clips:
 n=html.escape(r['name']);f=html.escape(r['file']);vr.append(f'<article data-name="录像 {n}"><video controls playsinline preload="metadata" src="{f}"></video><p>{n} · 原生训练、暂停与继续</p><a href="{f}" download>下载 MP4</a></article>')
(out/'界面与动画总览.html').write_text('''<!doctype html><html lang="zh"><meta charset="UTF-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>方寸 · 整版改造复核</title><style>*{box-sizing:border-box}body{margin:0;background:#faf9f5;color:#1b355a;font:16px system-ui}header{padding:25px 5vw;background:#faf9f5f5;border-bottom:1px solid #ddd}h1{font-size:28px;margin:0 0 12px}nav{padding:12px 5vw;position:sticky;top:0;background:#faf9f5f5;z-index:1;display:flex;gap:20px;align-items:center;flex-wrap:wrap}input{font:inherit;padding:12px;width:min(500px,100%);border:1px solid #b8c2cd;border-radius:10px}h2{padding:20px 5vw 0;font-size:21px}.grid{padding:20px 5vw;display:grid;grid-template-columns:repeat(auto-fill,minmax(240px,1fr));gap:24px}article{padding:12px;background:white;border-radius:16px;min-width:0}img,video{display:block;width:100%;height:auto;border-radius:8px}p{line-height:1.6;overflow-wrap:anywhere}article p{font-size:14px}a{color:#1b355a}article[hidden]{display:none}.note{max-width:880px;color:#526580}</style><header><h1>方寸 · 整版改造复核</h1><p class="note">2026-10-19 · iPhone 18 Pro / iOS 27 模拟器 · 全部使用合成测试数据。截图与视频来自真实原生 App，没有后期重绘。录像用于检查视觉节拍，未录制设备音频和触觉。</p><p><a href="改动与验证报告.md">改动与验证报告</a> · <a href="修订执行规格.md">修订执行规格</a> · <a href="安装说明.md">安装说明</a></p></header><nav><a href="#motion">九种训练录像</a><a href="#screens">全部界面</a><input id="q" aria-label="筛选界面" placeholder="筛选：训练 / 日常 / 饮品 / 深色 / 大字号…"><span id="count"></span></nav><h2 id="motion">训练动作 · 可播放</h2><section class="grid">'''+''.join(vr)+'''</section><h2 id="screens">全部原生界面</h2><p style="padding:0 5vw" class="note">连续页码表示同一页面的不同滚动位置；训练 A/B 表示不同时间点。点击截图查看原始分辨率。</p><main class="grid">'''+''.join(rows)+'''</main><script>const cards=[...document.querySelectorAll('article')];function filter(){let q=document.querySelector('#q').value.toLowerCase();cards.forEach(c=>c.hidden=!c.dataset.name.toLowerCase().includes(q));document.querySelector('#count').textContent=cards.filter(c=>!c.hidden).length+' 项'}document.querySelector('#q').oninput=filter;filter()</script></html>''')
print(len(items),'screenshots;',len(clips),'videos')
