"""Record actual simulator motion when the dedicated UI journey emits markers.
Run after other UI tests have finished. This never targets a physical phone.
"""
from pathlib import Path
import argparse, json, shutil, signal, subprocess, time
parser=argparse.ArgumentParser()
parser.add_argument('--simulator',required=True)
parser.add_argument('--output',required=True)
parser.add_argument('--derived-data')
parser.add_argument('--also-test', action='append', default=[])
args=parser.parse_args()
root=Path(__file__).resolve().parents[2]
out=Path(args.output).resolve(); out.mkdir(parents=True,exist_ok=True)
source=Path(__file__).with_name('MotionReviewUITests.swift')
target=root/'InnerBalance/InnerBalanceUITests'/source.name
if target.exists(): raise SystemExit('Refusing to overwrite an existing UI test source')
shutil.copy2(source,target)
cmd=['xcodebuild','test','-project','InnerBalance/InnerBalance.xcodeproj','-scheme','InnerBalance','-destination','platform=iOS Simulator,id='+args.simulator,'-derivedDataPath',str(Path(args.derived_data).resolve() if args.derived_data else out.parent/'Derived'),'-resultBundlePath',str(out/'Motion.xcresult'),'-parallel-testing-enabled','NO','-collect-test-diagnostics','never','-only-testing:InnerBalanceUITests/MotionReviewUITests','CODE_SIGNING_ALLOWED=NO']
cmd += ['-only-testing:' + item for item in args.also_test]
recorder=None;receipt=[]
def stop():
 global recorder
 if recorder:
  recorder.send_signal(signal.SIGINT)
  recorder.wait(timeout=30)
  receipt[-1]['recordingExit']=recorder.returncode
  receipt[-1]['seconds']=round(time.monotonic()-receipt[-1].pop('started'),2)
  recorder=None
try:
 with (out/'motion-test.log').open('w') as log, (out/'recorder.log').open('w') as rec:
  process=subprocess.Popen(cmd,cwd=root,stdout=subprocess.PIPE,stderr=subprocess.STDOUT,text=True,bufsize=1)
  for line in process.stdout:
   log.write(line);log.flush()
   if 'FANGCUN_MOTION_START:' in line:
    stop();kind=line.split('FANGCUN_MOTION_START:',1)[1].strip()
    file=out/(kind+'.mp4')
    if file.exists():raise RuntimeError('Refusing to overwrite '+str(file))
    recorder=subprocess.Popen(['xcrun','simctl','io',args.simulator,'recordVideo','--codec=h264',str(file)],stdout=rec,stderr=rec)
    receipt.append({'kind':kind,'file':file.name,'started':time.monotonic()})
    print('recording',kind,flush=True)
   if 'FANGCUN_MOTION_STOP:' in line:stop()
  code=process.wait()
  print('ui_test_exit',code,flush=True)
finally:
 stop()
 if target.read_bytes()==source.read_bytes():target.unlink()
 (out/'recordings.json').write_text(json.dumps(receipt,ensure_ascii=False,indent=2))
raise SystemExit(code)
