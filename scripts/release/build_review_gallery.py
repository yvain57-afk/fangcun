"""Build an offline gallery from already-exported native capture evidence.

Does not retouch screenshots, synthesize UI, or change release state.
"""
from pathlib import Path
import argparse
import hashlib
import html
import json
import shutil
import subprocess

parser = argparse.ArgumentParser()
parser.add_argument("--delivery", required=True)
parser.add_argument("--motion", required=True)
args = parser.parse_args()
delivery = Path(args.delivery).resolve()
motion = Path(args.motion).resolve()
root = Path(__file__).resolve().parents[2]
assert (delivery / "screenshots").is_dir(), "Export native screenshots first"
videos = delivery / "videos"
videos.mkdir(exist_ok=True)
names = {
    "physiologicalSigh": "A little sigh · 生理性叹息",
    "pacedBreathing": "A longer out-breath · 节律呼吸",
    "balancedBreathing": "Even breathing · 均衡慢呼吸",
    "boxBreathing": "Box breathing · 方块呼吸",
    "diaphragmaticBreathing": "Gentle belly breathing · 膈肌呼吸",
    "alternateNostrilBreathing": "Alternate-nostril breathing · 交替鼻孔呼吸",
    "meditation": "A moment to settle · 冥想",
    "nsdr": "Resting body scan · NSDR",
    "kegel": "Pelvic floor practice · 盆底练习",
    "progressiveMuscleRelaxation": "Tense, then let go · 渐进式肌肉放松",
}
receipts = json.loads((motion / "recordings.json").read_text())
assert len(receipts) == len(names)
video_receipts = []
cards = []
for item in receipts:
    assert item["recordingExit"] == 0
    source = motion / item["file"]
    probe = json.loads(subprocess.check_output([
        "ffprobe", "-v", "error", "-show_streams", "-show_format", "-of", "json", str(source)
    ]))
    stream = next(s for s in probe["streams"] if s["codec_type"] == "video")
    duration = float(probe["format"]["duration"])
    assert duration >= 29 and stream["width"] == 1320 and stream["height"] == 2868
    dest = videos / source.name
    if dest.exists():
        assert dest.read_bytes() == source.read_bytes()
    else:
        shutil.copy2(source, dest)
    video_receipts.append({
        "kind": item["kind"], "file": "videos/" + dest.name,
        "sha256": hashlib.sha256(dest.read_bytes()).hexdigest(),
        "seconds": duration, "width": stream["width"], "height": stream["height"],
        "audioRecorded": any(s["codec_type"] == "audio" for s in probe["streams"]),
        "source": "native iPhone 16 Pro Max simulator / simctl recordVideo",
    })
    cards.append(f'<article><h3>{html.escape(names[item["kind"]])}</h3>'
                 f'<video controls playsinline preload="metadata" src="videos/{dest.name}"></video>'
                 '<p>真实训练运行 → 暂停 → 继续。原始模拟器录像，不含设备音频或触觉。</p></article>')
(delivery / "videos-provenance.json").write_text(json.dumps(video_receipts, indent=2, ensure_ascii=False))
shots = []
for file in sorted((delivery / "screenshots").glob("*.png")):
    label = file.stem
    shots.append(f'<figure><a href="screenshots/{file.name}"><img loading="lazy" '
                 f'src="screenshots/{file.name}" alt="{html.escape(label)}"></a>'
                 f'<figcaption>{html.escape(label)}</figcaption></figure>')
release = json.loads((root / "docs/releases/little-exhale-2/release-state.json").read_text())
if release["appStoreReview"] in {"submitted_waiting_for_review", "in_review", "approved", "ready_for_distribution"}:
    release_title = "2.0 更新已提交 Apple 审核。"
    release_detail = "审核与公开发布是不同阶段；当前状态以交付记录中的 Apple 页面回读为准。"
elif release["upload"] == "xcode_upload_completed_exit_0":
    release_title = "2.0 构建上传命令已成功；正式审核尚未提交。"
    release_detail = "英文商店文案已保存，正在补齐截图、主语言与构建选择。TestFlight 是否处理完成，以 Apple 页面回读为准。"
else:
    release_title = "本地版本已完成；正式审核尚未提交。"
    release_detail = "分发、上传、TestFlight 处理及正式审核分别记录，详情见交付与验证记录。"
page = '''<!doctype html><html lang="zh-CN"><meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1"><title>Little Exhale 2.0 · 原生验收</title>
<style>body{margin:0;background:#faf9f5;color:#1b355a;font:16px/1.7 system-ui,sans-serif}main{max-width:1240px;margin:auto;padding:40px 24px}h1{font:52px Georgia,serif;margin-bottom:12px}h2{margin-top:48px}a{color:inherit}header{max-width:850px}.status{padding:18px 24px;border-left:4px solid #b65d43;background:#f4e8df;border-radius:12px}.grid{display:grid;grid-template-columns:repeat(auto-fit,minmax(260px,1fr));gap:24px}article,figure{margin:0;padding:18px;background:#fff;border-radius:24px}video,img{display:block;width:100%;height:auto;border-radius:16px}video{max-height:680px;background:#faf9f5}figcaption{font-size:12px;overflow-wrap:anywhere;margin-top:12px}article p{font-size:13px}nav{display:flex;gap:20px;flex-wrap:wrap}h3{font-size:17px;min-height:54px}.meta{color:#52677e}</style>
<main><header><p>LITTLE EXHALE · 2.0.0 / 2026102801</p><h1>A little room to breathe.</h1>
<p>英文品牌、十种练习、完整猫狗分层动作，以及更轻的日常页。本页全部为原生模拟器截图与录像，测试内容使用合成数据。</p>
<div class="status"><strong>''' + html.escape(release_title) + '''</strong><br>''' + html.escape(release_detail) + '''</div>
<p class="meta">不把模拟器验证等同于真机音频、蓝牙、触觉、HealthKit 或 Watch 同步验收。原始时长、节拍、记录格式和偏好保留。</p>
<nav><a href="#motion">十种练习录像</a><a href="#screens">界面截图</a><a href="交付与验证.md">交付与验证记录</a></nav></header>
<h2 id="motion">实际训练中的动作</h2><div class="grid">''' + "".join(cards) + '''</div>
<h2 id="screens">原生界面</h2><p>点击查看原始分辨率；图像没有重绘或修饰。</p><div class="grid">''' + "".join(shots) + "</div></main></html>"
(delivery / "原生界面与动作验收.html").write_text(page)
print(json.dumps({"screenshots": len(shots), "videos": len(video_receipts), "gallery": str(delivery / "原生界面与动作验收.html")}, ensure_ascii=False))
