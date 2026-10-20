"""Compile the approved review JSON into Core copy and a timed audio manifest.
Run from any working directory; does not synthesize or publish audio.
"""
from pathlib import Path
import json
R=Path(__file__).resolve().parents[2];d=json.loads((R/'docs/content/guidance-review-20261019/guidance-draft.json').read_text());out=R/'docs/content/guidance-integration-20261020';out.mkdir(exist_ok=True)
assets=[]
def add(name,text,window=None):
 row={'resource':name,'text':text,'windowSeconds':window}
 if name not in [x['resource'] for x in assets]:assets.append(row)
def literal(t):return json.dumps(t,ensure_ascii=False)
lines=['import Foundation','','/// User-approved 2026-10-20 listening draft. Existing nine protocol timings are unchanged.','public enum PracticeGuidanceContent {','  public static let version = "fangcun-guidance-20261020"','  public static func introduction(for kind: PracticeKind, variantID: String? = nil) -> String {','    switch kind {']
for m in d['methods']:
 key=m['key'];intro=m['preparation']+'\n\n'+m['safety']
 if key=='balancedBreathing':
  a=m['preparation_variants']['easy_4_4']+'\n\n'+m['safety'];b=m['preparation_variants']['equal_5_5']+'\n\n'+m['safety']
  lines.append(f'    case .{key}: variantID == "easy_4_4" ? {literal(a)} : {literal(b)}')
  add('guide20_intro_'+key+'_easy_4_4',a);add('guide20_intro_'+key+'_equal_5_5',b)
 else:
  lines.append(f'    case .{key}: {literal(intro)}');add('guide20_intro_'+key,intro)
lines.append('    case .progressiveMuscleRelaxation: '+literal(d['pmr']['preparation']))
add('guide20_intro_progressiveMuscleRelaxation',d['pmr']['preparation'])
lines+=['    }','  }','  public static func introductionResource(for kind: PracticeKind, variantID: String? = nil) -> String {','    let suffix = kind == .balancedBreathing ? "_" + (variantID == "easy_4_4" ? "easy_4_4" : "equal_5_5") : ""','    return "guide20_intro_" + kind.rawValue + suffix','  }','  public static func completion(for kind: PracticeKind) -> String {','    switch kind {']
for m in d['methods']:lines.append(f'    case .{m["key"]}: {literal(m["completion"])}')
lines.append('    case .progressiveMuscleRelaxation: "这次练习结束了。先给自己一点时间，准备好时，再慢慢活动或继续休息。"')
lines+=['    }','  }','  public static func phaseResource(for kind: PracticeKind, cycle: Int, index: Int) -> String {','    "guide20_phase_" + kind.rawValue + "_" + String(min(1, max(0, cycle))) + "_" + String(index)','  }','  public static func phaseTexts(for kind: PracticeKind, cycle: Int) -> [String] {','    switch kind {']
for m in d['methods']:
 if not m.get('cycles'):continue
 first=[x[0] for x in m['cycles']];second=m['second']
 lines.append(f'    case .{m["key"]}: cycle == 0 ? [{", ".join(map(literal,first))}] : [{", ".join(map(literal,second))}]')
 for cycle,texts in enumerate([first,second]):
  for i,t in enumerate(texts):add(f'guide20_phase_{m["key"]}_{cycle}_{i}',t,4 if m['key']=='balancedBreathing' else m['cycles'][i][1])
lines+=['    default: []','    }','  }','  public static func segments(for kind: PracticeKind, duration: TimeInterval, variantID: String? = nil) -> [PracticeGuidedSegment] {','    switch (kind, duration) {']
for m in d['methods']:
 for t in m.get('tracks',[]):
  lines.append(f'    case (.{m["key"]}, {t["duration"]}): [')
  for i,s in enumerate(t['segments']):
   sid=f'{m["key"]}_{t["duration"]}_{i}'
   lines.append(f'      .init(id: "{sid}", start: {s["start"]}, end: {s["end"]}, focus: "{s["focus"]}", text: {literal(s["text"])}),')
   add('guide20_'+sid,s['text'],s['end']-s['start'])
  lines.append('    ]')
lines+=['    case (.progressiveMuscleRelaxation, 600): pmrSegments(sleep: variantID == "pmr_sleep")','    default: []','    }','  }','  private static func pmrSegments(sleep: Bool) -> [PracticeGuidedSegment] {','    let shared: [PracticeGuidedSegment] = [']
p=d['pmr'];shared=[]
for s in p['intro_segments']:shared.append((s,'pmr_settle'))
for g in p['groups']:
 for s in g['segments']:shared.append((s,'pmr_'+g['id'].split('-')[-1].lower()+'_'+s['phase']))
for s in p['whole_segments']:shared.append((s,'pmr_quiet'))
def sid(s):return s['id'].lower().replace('g10-','pmr_').replace('-','_')
for s,focus in shared:
 lines.append(f'      .init(id: "{sid(s)}", start: {s["start"]}, end: {s["end"]}, focus: "{focus}", text: {literal(s["text"])}),')
 add('guide20_'+sid(s),s['text'],s['end']-s['start'])
lines+=['    ]','    let ending: [PracticeGuidedSegment]','    if sleep {','      ending = [']
for s in p['endings']['sleep']:
 lines.append(f'        .init(id: "{sid(s)}", start: {s["start"]}, end: {s["end"]}, focus: "pmr_sleep", text: {literal(s["text"])}),');add('guide20_'+sid(s),s['text'],s['end']-s['start'])
lines+=['      ]','    } else {','      ending = [']
for s in p['endings']['day']:
 lines.append(f'        .init(id: "{sid(s)}", start: {s["start"]}, end: {s["end"]}, focus: "return", text: {literal(s["text"])}),');add('guide20_'+sid(s),s['text'],s['end']-s['start'])
lines+=['      ]','    }','    return shared + ending','  }','}']
(R/'InnerBalanceCore/Sources/InnerBalanceCore/Practice/PracticeGuidanceContent.swift').write_text('\n'.join(lines)+'\n')
(out/'AUDIO_MANIFEST.json').write_text(json.dumps({'voice':'zh-CN-XiaoxiaoNeural','rate':'-6%','pitch':'-2Hz','purpose':'user_authorized_local_listening_preview','commercialDistributionRights':'not_verified; formal release remains on hold','assets':assets},ensure_ascii=False,indent=2)+'\n')
print('content and audio manifest',len(assets),'resources',len(set(a['text'] for a in assets)),'unique texts')
