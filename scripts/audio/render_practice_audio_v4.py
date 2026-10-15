#!/usr/bin/env python3
"""Build-time Edge TTS only. App playback remains entirely offline. Never modifies legacy assets."""
import asyncio
import hashlib
import json
from pathlib import Path
import shutil
import subprocess
import edge_tts
from validate_practice_audio_v4 import ROOT, PACK, ASSETS, expected

VOICE = 'zh-CN-XiaoxiaoNeural'
RATE = '-6%'
PITCH = '-2Hz'
DERIVED = {'practice_v4_paced_inhale': 'practice_paced_inhale',
           'practice_v4_paced_exhale': 'practice_paced_exhale'}
WORK = ROOT / '.build/v4-audio-production'
CACHE = WORK / 'source'


def duration(path):
    return float(json.loads(subprocess.check_output(['ffprobe', '-v', 'error', '-show_entries',
                 'format=duration', '-of', 'json', str(path)]))['format']['duration'])


async def main():
    CACHE.mkdir(parents=True, exist_ok=True)
    ASSETS.mkdir(parents=True, exist_ok=True)
    records = []
    receipt = PACK / 'AUDIO_PRODUCTION.json'
    previous = json.loads(receipt.read_text()) if receipt.exists() else {}
    verified_existing = {row['resource']: row for row in previous.get('assets', [])} if previous.get('voice') == VOICE and previous.get('rate') == RATE and previous.get('pitch') == PITCH else {}
    semaphore = asyncio.Semaphore(3)
    requests = [item for item in expected() if item['resource'].startswith('practice_v4_')]
    texts = {item['text'] for item in requests if item['resource'] not in DERIVED}
    files = {}

    async def synthesize(text):
        key = hashlib.sha256((VOICE + RATE + PITCH + text).encode()).hexdigest()[:20]
        source = CACHE / (key + '.mp3')
        async with semaphore:
            if not source.exists() or source.stat().st_size == 0:
                temp = source.with_suffix('.partial.mp3')
                # Only authored generic practice copy is sent; no personal/device data.
                await edge_tts.Communicate(text, VOICE, rate=RATE, pitch=PITCH,
                                          connect_timeout=15, receive_timeout=40).save(str(temp))
                if temp.stat().st_size == 0:
                    raise RuntimeError('empty speech response')
                temp.replace(source)
            files[text] = source
            print('source ready', key, flush=True)

    await asyncio.gather(*(synthesize(text) for text in sorted(texts)))
    for item in requests:
        source = ASSETS / (DERIVED[item['resource']] + '.m4a') if item['resource'] in DERIVED else files[item['text']]
        source_duration = duration(source)
        # Preserve the protocol's fixed window. A small, disclosed tempo adjustment
        # fits the authored text; fail instead of truncating words or stretching protocol.
        tempo = max(1, source_duration / max(0.1, item['windowSeconds'] - 0.15))
        if tempo > 1.25:
            raise RuntimeError('authored speech cannot fit window: ' + item['resource'])
        dest = ASSETS / (item['resource'] + '.m4a')
        old = verified_existing.get(item['resource'])
        if old and dest.exists() and old['text'] == item['text'] and old['sha256'] == hashlib.sha256(dest.read_bytes()).hexdigest():
            records.append(old)
            continue
        filters = f'atempo={tempo:.6f},loudnorm=I=-24:TP=-6:LRA=7,afade=t=in:d=0.025'
        subprocess.run(['ffmpeg', '-v', 'error', '-y', '-i', str(source), '-af', filters,
                        '-ar', '44100', '-ac', '1', '-c:a', 'aac', '-b:a', '128k',
                        '-metadata', 'comment=Fangcun V4 offline guidance; Edge TTS Xiaoxiao',
                        str(dest)], check=True)
        actual = duration(dest)
        if actual > item['windowSeconds'] or actual <= 0:
            raise RuntimeError('rendered audio window failure: ' + item['resource'])
        records.append(item | {'voice': 'legacy_zhixingnv_original' if item['resource'] in DERIVED else VOICE, 'rate': RATE, 'pitch': PITCH,
                              'durationSeconds': actual, 'tempoAdjustment': tempo,
                              'file': str(dest.relative_to(ROOT)),
                              'sourceType': 'legacy_volume_only' if item['resource'] in DERIVED else 'edge_tts',
                              'sha256': hashlib.sha256(dest.read_bytes()).hexdigest()})
        print('asset ready', item['resource'], f'{actual:.3f}s', flush=True)
    # Measure final AAC, then correct gain only. No change to speech duration or pitch.
    for record in records:
        dest = ROOT / record['file']
        measured = subprocess.run(['ffmpeg', '-hide_banner', '-i', str(dest), '-af',
          'loudnorm=I=-24:TP=-6:LRA=7:print_format=json', '-f', 'null', '-'],
          capture_output=True, text=True, check=True)
        levels = json.loads(measured.stderr[measured.stderr.rfind('{'):])
        gain = -24 - float(levels['input_i'])
        if abs(gain) > 0.15:
            temp = dest.with_suffix('.normalized.m4a')
            subprocess.run(['ffmpeg', '-v', 'error', '-y', '-i', str(dest), '-af', f'volume={gain:.4f}dB',
                            '-ar', '44100', '-ac', '1', '-c:a', 'aac', '-b:a', '128k', str(temp)], check=True)
            temp.replace(dest)
        record['postEncodeGainDB'] = gain if abs(gain) > 0.15 else 0
        record['sha256'] = hashlib.sha256(dest.read_bytes()).hexdigest()
        record['durationSeconds'] = duration(dest)
    report = {'productionDate': '2026-10-15', 'provider': 'Edge TTS', 'libraryVersion': edge_tts.__version__,
              'voice': VOICE, 'rate': RATE, 'pitch': PITCH, 'loudnessTargetLUFS': -24,
              'legacyVoiceIdentity': 'not_proven; user suggested Edge TTS; Xiaoxiao closest of two same-text female candidates by spectral comparison',
              'auditoryIdentityAcceptance': 'pending_human_listening', 'assets': records}
    (PACK / 'AUDIO_PRODUCTION.json').write_text(json.dumps(report, ensure_ascii=False, indent=2) + '\n')
    print('complete', len(records), 'assets', flush=True)

if __name__ == '__main__':
    try:
        asyncio.run(main())
    except Exception as error:
        # Do not serialize endpoint queries, headers, tokens or account data.
        print('audio production failed:', type(error).__name__, getattr(error, 'status', ''), flush=True)
        raise SystemExit(1)
