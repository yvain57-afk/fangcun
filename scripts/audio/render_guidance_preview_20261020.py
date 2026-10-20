#!/usr/bin/env python3
"""Local listening preview only. No app runtime network calls; keep legacy assets intact."""
import asyncio,hashlib,json,subprocess
from pathlib import Path
import edge_tts
ROOT=Path(__file__).resolve().parents[2]
PACK=ROOT/'docs/content/guidance-integration-20261020'
WORK=ROOT/'.build/guidance-integration-20261020/audio'
ASSETS=ROOT/'InnerBalance/InnerBalanceApp/PracticeVoice'
async def main():
 data=json.loads((PACK/'AUDIO_MANIFEST.json').read_text());WORK.mkdir(parents=True,exist_ok=True)
 semaphore=asyncio.Semaphore(3);sources={};results=[]
 async def synth(text):
  key=hashlib.sha256((data['voice']+data['rate']+data['pitch']+text).encode()).hexdigest()
  dest=WORK/(key+'.mp3')
  async with semaphore:
   for attempt in range(3):
    try:
     if not dest.exists() or dest.stat().st_size==0:
      part=dest.with_suffix('.partial.mp3')
      await edge_tts.Communicate(text,data['voice'],rate=data['rate'],pitch=data['pitch'],connect_timeout=15,receive_timeout=40).save(str(part))
      if part.stat().st_size==0:raise ValueError('empty')
      part.replace(dest)
     sources[text]=dest;print('speech_cached',key[:10],flush=True);return
    except Exception as e:
     if attempt==2:raise RuntimeError('speech generation failed '+type(e).__name__) from None
     await asyncio.sleep(1+attempt)
 await asyncio.gather(*(synth(t) for t in sorted({a['text'] for a in data['assets']})))
 for a in data['assets']:
  dest=ASSETS/(a['resource']+'.m4a')
  subprocess.run(['ffmpeg','-v','error','-y','-i',str(sources[a['text']]),'-af','loudnorm=I=-24:TP=-6:LRA=7,afade=t=in:d=0.025','-ar','44100','-ac','1','-c:a','aac','-b:a','96k',str(dest)],check=True)
  duration=float(json.loads(subprocess.check_output(['ffprobe','-v','error','-show_entries','format=duration','-of','json',str(dest)]))['format']['duration'])
  if a['windowSeconds'] is not None and duration>a['windowSeconds']-.04:
   raise RuntimeError('unmodified text exceeds timing window: '+a['resource']+' duration '+str(duration))
  results.append(a|{'durationSeconds':duration,'sha256':hashlib.sha256(dest.read_bytes()).hexdigest()})
 (PACK/'AUDIO_PRODUCTION.json').write_text(json.dumps({**{k:v for k,v in data.items() if k!='assets'},'status':'preview_generated_no_time_stretch','assets':results},ensure_ascii=False,indent=2)+'\n')
 print('preview_complete',len(results),flush=True)
if __name__=='__main__':asyncio.run(main())
