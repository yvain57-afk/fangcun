#!/usr/bin/env python3
"""Offline English pack. Authored copy only is sent; no app/user data.
Requires edge-tts 7.3.1. No time stretching, clipping or protocol changes.
"""
import asyncio,hashlib,json,re,subprocess,shutil
import edge_tts
from pathlib import Path
ROOT=Path(__file__).resolve().parents[2]
WORK=ROOT/'.build/little-exhale-2'
OUT=ROOT/'InnerBalance/InnerBalanceApp/PracticeVoice'
DOC=ROOT/'docs/content/little-exhale-2'
VOICE='en-US-AvaMultilingualNeural'
RATE='-10%'
FFMPEG=shutil.which('ffmpeg') or '/Users/yvainair/.local/bin/ffmpeg'
PROBE=shutil.which('ffprobe') or '/Users/yvainair/.local/bin/ffprobe'
def duration(p):
 return float(subprocess.check_output([PROBE,'-v','error','-show_entries','format=duration','-of','default=noprint_wrappers=1:nokey=1',str(p)]))
def manifest():
 d=json.loads((DOC/'guidance-copy.json').read_text()); items=[]
 def add(name,text,window=None):items.append(dict(resource='le2_'+name,text=text,windowSeconds=window))
 for k,t in d['intro'].items():
  if k=='balancedBreathing':
   add('guide20_intro_'+k+'_equal_5_5',t)
   add('guide20_intro_'+k+'_easy_4_4',t.replace('five seconds','four seconds').replace('out for five','out for four'))
  else:add('guide20_intro_'+k,t)
 for k,t in d['completion'].items():add('guide20_end_'+k,t)
 windows={'physiologicalSigh':[3,2,7],'pacedBreathing':[4,6],'balancedBreathing':[4,4],'boxBreathing':[3,3,3,3],'alternateNostrilBreathing':[3,3,3,3],'kegel':[4,8]}
 for k,cycles in d['phases'].items():
  for c,texts in enumerate(cycles):
   for i,t in enumerate(texts):add(f'guide20_phase_{k}_{c}_{i}',t,windows[k][i])
 s=(ROOT/'InnerBalanceCore/Sources/InnerBalanceCore/Practice/PracticeGuidanceContent.swift').read_text()
 bounds={k:int(end)-int(start) for k,start,end in re.findall(r'\.init\(id: "([^"]+)", start: (\d+), end: (\d+)',s)}
 for k,t in d['segments'].items():add('guide20_'+k,t,bounds[k])
 # Retain short fallback resources used by the older audio API, in the same English voice.
 audio=(ROOT/'InnerBalance/InnerBalanceApp/Features/Practice/PracticeAudioPlan.swift').read_text()
 names=dict(re.findall(r'case \.(\w+): "([^"]+)"',audio.split('var voiceResourceName: String {')[1].split('var spokenText: String {')[0]))
 spoken=dict(re.findall(r'case \.(\w+): "([^"]+)"',audio.split('var spokenText: String {')[1].split('enum PracticeAudioBackgroundPolicy')[0]))
 cue_windows={'sighInhale':3,'sighTopUp':2,'sighExhale':7,'pacedInhale':4,'pacedExhale':6,'kegelContract':4,'kegelRelease':8,'hold':3,'leftInhale':3,'rightExhale':3,'rightInhale':3,'leftExhale':3}
 for cue,name in names.items():add(name,spoken[cue],cue_windows.get(cue,30))
 return items
async def main():
 DOC.mkdir(parents=True,exist_ok=True);cache=WORK/'audio-source';cache.mkdir(exist_ok=True)
 items=manifest();semaphore=asyncio.Semaphore(1)
 records=[]; failures=[]
 async def one(item):
  async with semaphore:
   key=hashlib.sha256((VOICE+RATE+item['text']).encode()).hexdigest()
   raw=cache/(key+'.mp3'); target=OUT/(item['resource']+'.m4a')
   try:
    if not raw.exists():
     temp=raw.with_suffix('.partial.mp3')
     await edge_tts.Communicate(item['text'],VOICE,rate=RATE,connect_timeout=20,receive_timeout=60).save(str(temp))
     duration(temp);temp.replace(raw)
    actual=duration(raw)
    if item['windowSeconds'] is not None and actual>item['windowSeconds']-.08:
     raise ValueError(f'needs shorter copy: {actual:.3f}s > {item["windowSeconds"]}s')
    if not target.exists():
     temp=target.with_suffix('.partial.m4a')
     subprocess.run([FFMPEG,'-v','error','-y','-i',str(raw),'-af','loudnorm=I=-23:TP=-3:LRA=7','-ar','44100','-ac','1','-c:a','aac','-b:a','128k',str(temp)],check=True)
     temp.replace(target)
    subprocess.run([FFMPEG,'-v','error','-i',str(target),'-f','null','-'],check=True,stderr=subprocess.PIPE)
    records.append(dict(item,duration=duration(target),sha256=hashlib.sha256(target.read_bytes()).hexdigest(),decoded=True))
    print('ready',item['resource'],round(actual,2),flush=True)
   except Exception as e:
    failures.append(dict(resource=item['resource'],error=str(e)));print('failed',item['resource'],type(e).__name__,str(e)[:120],flush=True)
 await asyncio.gather(*(one(i) for i in items))
 (DOC/'AUDIO_PRODUCTION.json').write_text(json.dumps(dict(voice=VOICE,rate=RATE,source='Edge TTS',commercialDistributionRights='not independently verified; not an Azure licensed pack',assets=sorted(records,key=lambda r:r['resource']),failures=failures),indent=2)+'\n')
 print('RESULT',len(records),'ready;',len(failures),'failed',flush=True)
 if failures:raise SystemExit(1)
if __name__=='__main__':asyncio.run(main())
