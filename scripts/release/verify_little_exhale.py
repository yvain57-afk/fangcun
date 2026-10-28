"""Verify the actual signed archive app against reviewed offline resources.
Does not read device containers, credentials, signing identities, or personal health data.
"""
import argparse, hashlib, json, plistlib, subprocess
from pathlib import Path
parser = argparse.ArgumentParser()
parser.add_argument("--app", required=True)
parser.add_argument("--out", required=True)
args = parser.parse_args()
root = Path(__file__).resolve().parents[2]
app = Path(args.app)
info = plistlib.loads((app / "Info.plist").read_bytes())
assert info["CFBundleIdentifier"] == "com.yvainair.InnerBalance"
assert info["CFBundleShortVersionString"] == "2.0.0"
assert info["CFBundleVersion"] == "2026102801"
assert info["CFBundleDisplayName"] == "Little Exhale"
assert info.get("ITSAppUsesNonExemptEncryption") is False
assert (app / "en.lproj/Localizable.strings").exists()
manifest = json.loads((root / "docs/content/little-exhale-2/AUDIO_PRODUCTION.json").read_text())
checked = []
for entry in manifest["assets"]:
    matches = list(app.rglob(entry["resource"] + ".m4a"))
    assert matches, entry["resource"]
    # A Watch companion can also contain the resource; every packaged copy must match.
    for file in matches:
        assert hashlib.sha256(file.read_bytes()).hexdigest() == entry["sha256"], file.name
    checked.append(entry["resource"])
assert len(checked) == 171
asset_info = json.loads(subprocess.check_output(["xcrun", "assetutil", "--info", str(app / "Assets.car")]))
asset_names = {item.get("Name") for item in asset_info}
expected_art = {p.stem for p in (root / "InnerBalance/InnerBalanceApp/Assets.xcassets").glob("LE2-*.imageset")}
assert len(expected_art) == 12
assert expected_art <= asset_names, sorted(expected_art - asset_names)
watch = list((app / "Watch").glob("*.app"))
assert len(watch) == 1
wi = plistlib.loads((watch[0] / "Info.plist").read_bytes())
assert wi["CFBundleIdentifier"] == "com.yvainair.InnerBalance.watchkitapp"
assert wi["CFBundleShortVersionString"] == info["CFBundleShortVersionString"]
assert wi["CFBundleVersion"] == info["CFBundleVersion"]
assert wi["WKCompanionAppBundleIdentifier"] == info["CFBundleIdentifier"]
privacy = plistlib.loads((app / "PrivacyInfo.xcprivacy").read_bytes())
assert privacy["NSPrivacyTracking"] is False
assert privacy["NSPrivacyCollectedDataTypes"] == []
result = subprocess.run(["codesign", "--verify", "--deep", "--strict", str(app)], capture_output=True)
assert result.returncode == 0, "Code signature verification failed"
receipt = {"version": info["CFBundleShortVersionString"], "build": info["CFBundleVersion"],
 "bundleID": info["CFBundleIdentifier"], "englishAudioVerified": len(checked), "characterLayersVerified": len(expected_art),
 "watchIdentityAndVersionMatch": True, "englishCatalogBundled": True,
 "tracking": False, "codeSignatureVerified": True,
 "archive": app.parent.parent.parent.name,
 "executableSHA256": hashlib.sha256((app / info["CFBundleExecutable"]).read_bytes()).hexdigest(),
 "signatureScope": "Development-signed archive; distribution export not verified",
 "boundary": "Local package validation, not Apple processing or review approval."}
Path(args.out).write_text(json.dumps(receipt, indent=2) + "\n")
print(json.dumps(receipt, indent=2))
