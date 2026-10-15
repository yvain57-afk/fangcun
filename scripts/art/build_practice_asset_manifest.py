"""Inventory V4 original-art layers and offline voices without modifying assets."""
import hashlib
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
DOC = ROOT / "docs/plans/fangcun-breathing-v4"


def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


layers = json.loads((DOC / "art/layers.json").read_text())
for layer in layers:
    image = ROOT / "InnerBalance/InnerBalanceApp/Assets.xcassets" / (layer["asset"] + ".imageset") / "Artwork.png"
    layer.update(file=str(image.relative_to(ROOT)), sha256=digest(image), bytes=image.stat().st_size)

audio = json.loads((DOC / "AUDIO_ASSETS.json").read_text())
for asset in audio["assets"]:
    assert digest(ROOT / asset["file"]) == asset["sha256"], asset["file"]

scenes = {
    "physiologicalSigh": {"character": "cat", "props": ["cat-flower"], "action": "anchored torso main inhale 0.82; top-up 0.18; exhale; subtle head and flower response"},
    "pacedBreathing": {"character": "resting dog", "props": ["rest-pillow"], "action": "prone pose, anchored 4/6 torso movement, quiet eyes"},
    "balancedBreathing": {"character": "cat and dog", "props": ["cat-mat"], "action": "two separate rigs driven by the same 5/5 or 4/4 timeline"},
    "boxBreathing": {"character": "cat", "props": ["cat-mat"], "action": "four phase cues; held torso during both holds; pause releases instruction"},
    "diaphragmaticBreathing": {"character": "side lying dog", "props": ["rest-pillow"], "action": "paw at lower ribs; natural breathing without paced countdown; human tutorial remains separate"},
    "alternateNostrilBreathing": {"character": "dog", "props": ["dog-leaf", "cat-leaf"], "action": "user left/right/right/left cues, localized head and ear movement"},
    "meditation": {"character": "cat", "props": ["cat-leaf"], "action": "quiet seated pose; brief return-of-attention cue, no continuous pursuit loop"},
    "nsdr": {"character": "side lying dog", "props": ["rest-blanket", "rest-pillow"], "action": "script focus drives face/shoulder/abdomen/legs separately; static between cues"},
    "kegel": {"character": "dog", "props": ["dog-flag"], "action": "flag 4 seconds contract / 8 seconds release; torso does not imply breath holding"},
}

manifest = {
    "schemaVersion": 1,
    "runtime": "native SwiftUI sprites plus local Metal torso deformation; no network assets",
    "artProduction": {
        "source": "Built-in image generation, preserving user-approved Fangcun cat/dog references",
        "referenceFiles": ["web/public/characters/v4/duo-calm.png", "web/public/characters/v4/dog-rest.png"],
        "prompts": "art/PRODUCTION_PROMPTS.json",
        "extraction": "scripts/art/slice_practice_atlas.swift; original RGBA retained; no white keying",
        "rightsNote": "本轮生成与既有用户认可素材的来源记录；不把生产来源等同于第三方商业许可保证。",
        "sources": [{"file": str(p.relative_to(ROOT)), "sha256": digest(p)} for p in sorted((DOC / "art").glob("*-atlas-source.png"))],
    },
    "scenes": scenes,
    "layerCount": len(layers),
    "layers": layers,
    "audioProduction": {
        "source": "Edge TTS build-time production; offline bundled M4A",
        "newVoice": "zh-CN-XiaoxiaoNeural",
        "originalVoiceIdentifier": "unknown; legacy zhixingnv is a local pack name",
        "reference": "AUDIO_PRODUCTION.json",
        "rightsNote": "记录生成服务与原文件来源，未进行独立的第三方授权审查。App运行时无Edge调用。",
    },
    "audio": audio["assets"],
    "verificationBoundary": "Asset hashes/window/loudness verified; taste approval and real-device sound/haptics/lock-screen verification remain separate.",
}
(DOC / "ASSET_MANIFEST.json").write_text(json.dumps(manifest, ensure_ascii=False, indent=2) + "\n")
print(f"Manifest: {len(layers)} art layers, {len(audio['assets'])} required audio assets")
