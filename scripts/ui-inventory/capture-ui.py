"""Capture the complete native UI in an isolated simulator using synthetic records."""
from pathlib import Path
import argparse, shutil, subprocess
p=argparse.ArgumentParser();p.add_argument('--simulator',required=True);p.add_argument('--output',required=True);p.add_argument('--only',action='append',default=[]);a=p.parse_args()
root=Path(__file__).resolve().parents[2];out=Path(a.output).resolve();out.mkdir(parents=True,exist_ok=True)
source=Path(__file__).with_name('FullUIInventoryCaptureUITests.swift');target=root/'InnerBalance/InnerBalanceUITests'/source.name
if target.exists():raise SystemExit('Refusing to overwrite an existing test source')
shutil.copy2(source,target)
cmd=['xcodebuild','test','-project','InnerBalance/InnerBalance.xcodeproj','-scheme','InnerBalance','-destination','platform=iOS Simulator,id='+a.simulator,'-derivedDataPath',str(out.parent/'Derived'),'-resultBundlePath',str(out/'Capture.xcresult'),'-parallel-testing-enabled','NO','-collect-test-diagnostics','never','CODE_SIGNING_ALLOWED=NO']
cmd += ['-only-testing:InnerBalanceUITests/FullUIInventoryCaptureUITests'+('/'+name if name else '') for name in (a.only or [''])]
try:
 with (out/'capture.log').open('w') as log:r=subprocess.run(cmd,cwd=root,stdout=log,stderr=subprocess.STDOUT)
 print('ui_capture_exit',r.returncode,flush=True)
finally:
 if target.read_bytes()==source.read_bytes():target.unlink()
subprocess.run(['xcrun','xcresulttool','export','attachments','--path',str(out/'Capture.xcresult'),'--output-path',str(out/'attachments')],cwd=root,check=True)
raise SystemExit(r.returncode)
