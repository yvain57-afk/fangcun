"""Copy named native XCTest screenshots and keep a privacy-safe provenance list."""
from pathlib import Path
import argparse
import hashlib
import json
import shutil

p = argparse.ArgumentParser()
p.add_argument("--attachments", required=True)
p.add_argument("--bundle-name", required=True)
p.add_argument("--delivery", required=True)
args = p.parse_args()
source = Path(args.attachments).resolve()
delivery = Path(args.delivery).resolve()
records_path = delivery / "screenshots-provenance.json"
records = {r["file"]: r for r in json.loads(records_path.read_text())}
count = 0
for test in json.loads((source / "manifest.json").read_text()):
    for item in test.get("attachments", []):
        name = item.get("suggestedHumanReadableName", "").split("_0_", 1)[0]
        if not name.startswith(("LE2-", "v3-raw-", "V4-human-teaching-", "肌肉放松-真实")):
            continue
        if item.get("isAssociatedWithFailure"):
            continue
        assert "/" not in name and "\\" not in name
        file = delivery / "screenshots" / (name + ".png")
        shutil.copy2(source / item["exportedFileName"], file)
        rel = str(file.relative_to(delivery))
        records[rel] = {"file": rel, "sha256": hashlib.sha256(file.read_bytes()).hexdigest(),
                        "sourceTest": test["testIdentifier"], "sourceBundle": args.bundle_name}
        count += 1
records_path.write_text(json.dumps(list(records.values()), ensure_ascii=False, indent=2) + "\n")
print(json.dumps({"copied": count, "total": len(records)}, ensure_ascii=False))
