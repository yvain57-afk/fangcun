"""Validate specification consistency only; this does not build or test the iOS app."""
from pathlib import Path
import json

root = Path(__file__).resolve().parent
load = lambda name: json.loads((root / 'config' / name).read_text(encoding='utf-8'))
catalog = load('practices.v4.json')
scenes = load('companion_scenes.v4.json')
copy = load('copy.zh-Hans.v4.json')
scripts = load('guided_scripts.zh-Hans.v4.json')
ps = catalog['practices']
assert len(ps) == 9
ids = {p['id'] for p in ps}
assert len(ids) == 9
assert len([p for p in ps if p['category'] == 'breathing']) == 6
assert len([p for p in ps if p['origin'] == 'existing']) == 5
assert len([p for p in ps if p['origin'] == 'new']) == 4
assert copy['navigation'] == ['呼吸', '日常']
assert set(copy['practiceCopy']) == ids
assert len(scenes['scenes']) == 9
assert {s['practiceID'] for s in scenes['scenes']} == ids
assert len({s['id'] for s in scenes['scenes']}) == 9
by_id = {p['id']: p for p in ps}
for p in ps:
    assert p['defaultDurationSeconds'] in p['durationOptionsSeconds'], p['id']
    assert p['requiresHealthAuthorization'] is False, p['id']
    assert p['sceneID'] in {s['id'] for s in scenes['scenes']}, p['id']
    for v in p['rhythmVariants']:
        assert all(d > 0 for _, d in v['phases']), p['id']
assert by_id['physiologicalSigh']['rhythmVariants'][0]['phases'] == [['inhale', 3], ['topUp', 2], ['exhale', 7]]
assert by_id['pacedBreathing']['rhythmVariants'][0]['phases'] == [['inhale', 4], ['exhale', 6]]
assert by_id['kegel']['rhythmVariants'][0]['phases'] == [['contract', 4], ['release', 8]]
assert by_id['kegel']['writesMindfulSession'] is False
assert by_id['kegel']['durationOptionsSeconds'] == [180]
assert by_id['alternateNostrilBreathing']['rhythmVariants'][0]['phases'] == [['leftInhale', 3], ['rightExhale', 3], ['rightInhale', 3], ['leftExhale', 3]]
for key in ['meditation', 'diaphragmaticBreathing', 'nsdr']:
    assert by_id[key]['rhythmVariants'] == [], key
expected_tracks = {(k, d) for k in ['meditation', 'diaphragmaticBreathing', 'nsdr'] for d in by_id[k]['durationOptionsSeconds']}
assert {(t['practiceID'], t['durationSeconds']) for t in scripts['tracks']} == expected_tracks
for t in scripts['tracks']:
    segments = t['segments']
    assert segments[0]['startSeconds'] == 0
    assert segments[-1]['endSeconds'] == t['durationSeconds']
    for i, seg in enumerate(segments):
        assert seg['startSeconds'] < seg['endSeconds']
        assert seg['text'] and seg['repeat'] is False
        if i:
            assert segments[i-1]['endSeconds'] == seg['startSeconds']
    if t['practiceID'] == 'nsdr':
        assert segments[-1]['startSeconds'] == t['durationSeconds'] - 30
print('PASS: 9 practices, 6 breathing methods, 5 retained + 4 new; 9 unique scenes; 6 complete guided timelines; original phase contracts retained.')
print('This validates the design package only. No iOS build, medical outcome, animation asset, device installation, or app runtime is validated.')
