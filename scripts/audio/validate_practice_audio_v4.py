#!/usr/bin/env python3
"""Validate real offline files against every V4 script window. Never synthesizes a fallback voice."""
import argparse
import hashlib
import json
from pathlib import Path
import subprocess
import re

ROOT = Path(__file__).resolve().parents[2]
PACK = ROOT / 'docs/plans/fangcun-breathing-v4'
ASSETS = ROOT / 'InnerBalance/InnerBalanceApp/PracticeVoice'
PHASES = {
    'practice_sigh_inhale': ('用鼻子，轻轻吸气。', 3),
    'practice_sigh_top_up': ('再补一小口。', 2),
    'practice_sigh_exhale': ('慢慢呼出去。', 7),
    'practice_v4_paced_inhale': ('慢慢吸气。', 3),
    'practice_v4_paced_exhale': ('把呼气放长。', 3),
    'practice_kegel_contract': ('轻轻收紧，呼吸照常。', 4),
    'practice_v4_kegel_release': ('完全放松。', 8),
    'practice_v4_hold': ('轻松停留。', 3),
    'practice_v4_left_inhale': ('左侧吸气。', 3),
    'practice_v4_right_exhale': ('右侧呼气。', 3),
    'practice_v4_right_inhale': ('右侧吸气。', 3),
    'practice_v4_left_exhale': ('左侧呼气。', 3),
}

def expected():
    for name, (text, duration) in PHASES.items():
        yield {'resource': name, 'text': text, 'windowSeconds': duration, 'type': 'phase'}
    scripts = json.loads((PACK / 'config/guided_scripts.zh-Hans.v4.json').read_text())
    for track in scripts['tracks']:
        for index, segment in enumerate(track['segments']):
            yield {'resource': f"practice_v4_{track['practiceID']}_{track['durationSeconds']}_{index}",
                   'text': segment['text'], 'windowSeconds': segment['endSeconds'] - segment['startSeconds'],
                   'type': 'segment', 'startSeconds': segment['startSeconds'], 'endSeconds': segment['endSeconds']}

def inspect(item):
    result = dict(item)
    path = next((ASSETS / (item['resource'] + ext) for ext in ('.m4a', '.mp3', '.wav')
                 if (ASSETS / (item['resource'] + ext)).exists()), None)
    if path is None:
        return result | {'status': 'missing', 'voicePack': 'zhixingnv'}
    probe = subprocess.run(['ffprobe', '-v', 'error', '-show_entries', 'format=duration',
                            '-of', 'json', str(path)], capture_output=True, text=True, check=True)
    duration = float(json.loads(probe.stdout)['format']['duration'])
    measured = subprocess.run(['ffmpeg', '-hide_banner', '-i', str(path), '-af', 'volumedetect',
                               '-f', 'null', '-'], capture_output=True, text=True, check=True)
    mean_db = float(re.search(r'mean_volume: ([\-\w.]+) dB', measured.stderr).group(1))
    peak_db = float(re.search(r'max_volume: ([\-\w.]+) dB', measured.stderr).group(1))
    status = 'pass' if 0 < duration <= item['windowSeconds'] else 'window_overflow'
    if mean_db < -50 or peak_db >= 0:
        status = 'signal_invalid'
    return result | {'status': status, 'voicePack': 'zhixingnv', 'file': str(path.relative_to(ROOT)),
                     'durationSeconds': duration, 'meanVolumeDB': mean_db, 'peakVolumeDB': peak_db, 'sha256': hashlib.sha256(path.read_bytes()).hexdigest()}

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--report', type=Path, default=PACK / 'AUDIO_ASSETS.json')
    args = parser.parse_args()
    rows = [inspect(item) for item in expected()]
    report = {'schemaVersion': 1, 'voicePack': 'zhixingnv',
              'generationStatus': 'generated_with_edge_tts_identity_listening_pending' if (PACK / 'AUDIO_PRODUCTION.json').exists() else 'production_in_progress',
              'runtimeFallback': 'explicit_text_and_optional_rhythm_only_no_voice_substitution',
              'assets': rows, 'summary': {status: sum(row['status'] == status for row in rows)
                                       for status in ('pass', 'missing', 'window_overflow', 'signal_invalid')}}
    args.report.write_text(json.dumps(report, ensure_ascii=False, indent=2) + '\n')
    print(json.dumps(report['summary'], ensure_ascii=False))
    return 1 if any(row['status'] != 'pass' for row in rows) else 0

if __name__ == '__main__':
    raise SystemExit(main())
