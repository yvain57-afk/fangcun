import json,subprocess,concurrent.futures
from pathlib import Path
production=json.loads(Path('docs/plans/fangcun-breathing-v4/AUDIO_PRODUCTION.json').read_text())
def check(item):
 p=Path(item['file'])
 r=subprocess.run(['ffmpeg','-hide_banner','-i',str(p),'-af','loudnorm=I=-24:TP=-6:LRA=7:print_format=json','-f','null','-'],capture_output=True,text=True,check=True)
 data=json.loads(r.stderr[r.stderr.rfind('{'):])
 return {'resource':p.stem,'integratedLUFS':float(data['input_i']),'truePeakDBTP':float(data['input_tp'])}
with concurrent.futures.ThreadPoolExecutor(max_workers=3) as pool: rows=list(pool.map(check,production['assets']))
report={'measurement':'ffmpeg loudnorm EBU R128 scan of encoded production m4a', 'rows':rows,
        'minimumLUFS':min(x['integratedLUFS'] for x in rows),'maximumLUFS':max(x['integratedLUFS'] for x in rows),
        'peakMaximumDBTP':max(x['truePeakDBTP'] for x in rows)}
Path('docs/plans/fangcun-breathing-v4/evidence/audio/new-loudness.json').write_text(json.dumps(report,ensure_ascii=False,indent=2)+'\n')
print(json.dumps({k:v for k,v in report.items() if k!='rows'}))
print('outliers', [x for x in rows if abs(x['integratedLUFS']+24)>1])
