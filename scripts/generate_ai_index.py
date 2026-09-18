#!/usr/bin/env python3
"""Build public, readable source bundles and a complete tracked-file index."""
from pathlib import Path
from urllib.parse import quote
import hashlib
import json
import subprocess

ROOT = Path(__file__).resolve().parents[1]
RAW = "https://raw.githubusercontent.com/yvain57-afk/fangcun/main/"
TEXT = {".swift", ".metal", ".md", ".txt", ".js", ".jsx", ".ts", ".tsx", ".json", ".css", ".html", ".svg", ".plist", ".entitlements", ".pbxproj", ".command", ".py", ".yml", ".yaml"}


def main():
    files = sorted(Path(p) for p in subprocess.check_output(
        ["git", "ls-files", "-z", "--cached", "--others", "--exclude-standard"], cwd=ROOT,
        text=True).rstrip("\0").split("\0"))
    files = [p for p in files if p.parts[0] != "ai" and p.name not in {
        "FILE_INDEX.md", "llms.txt", "llms-full.txt", "publication-manifest.json"}]
    # Only overwrite this script's generated outputs, never source files.
    target = ROOT / "ai"
    target.mkdir(exist_ok=True)
    for old in target.glob("source-*.txt"):
        old.unlink()
    chunks, chunk, size = [], [], 0
    for p in files:
        if p.suffix not in TEXT or p.name == "package-lock.json":
            continue
        try:
            content = (ROOT / p).read_text(encoding="utf-8")
        except UnicodeError:
            continue
        block = f"\n===== FILE: {p.as_posix()} =====\n{content}\n===== END FILE =====\n"
        if chunk and size + len(block.encode()) > 160_000:
            chunks.append("".join(chunk)); chunk, size = [], 0
        chunk.append(block); size += len(block.encode())
    if chunk:
        chunks.append("".join(chunk))
    links = []
    for number, content in enumerate(chunks, 1):
        name = f"source-{number:02}.txt"
        (target / name).write_text(content, encoding="utf-8")
        links.append(f"- [{name}]({name}) — [raw]({RAW}ai/{name})")
    (target / "README.md").write_text(
        "# Readable source bundles\n\nGenerated from the public source files. "
        "Every section names its original repository path. Binary images/audio and the "
        "dependency lockfile remain available through FILE_INDEX.md. "
        "Historical documents are not current completion claims.\n\n" + "\n".join(links) + "\n",
        encoding="utf-8")
    (ROOT / "llms-full.txt").write_text("\n".join(
        (ROOT / p).read_text(encoding="utf-8") for p in [
            "AI_CONTEXT.md", "docs/CURRENT_DESIGN.md", "docs/ARCHITECTURE.md",
            "docs/verification/STATUS.md"]), encoding="utf-8")
    (ROOT / "llms.txt").write_text(
        "# Fangcun\n\n> Native iOS/watchOS wellbeing app and its design archive.\n\n"
        f"- [AI entry]({RAW}AI_CONTEXT.md)\n"
        f"- [Context in one file]({RAW}llms-full.txt)\n"
        f"- [Complete file index]({RAW}FILE_INDEX.md)\n"
        f"- [Source bundles]({RAW}ai/README.md)\n", encoding="utf-8")
    all_files = sorted(set(files + [Path("ai") / p.name for p in target.iterdir()] +
                           [Path("llms.txt"), Path("llms-full.txt")]))
    index = ["# Complete file index", "", "Public source, assets and design materials. "
             "Generated files are included; caches, private signing and user data are excluded.", ""]
    manifest = []
    for p in all_files:
        data = (ROOT / p).read_bytes()
        path = p.as_posix(); encoded = quote(path)
        index.append(f"- [{path}]({encoded}) — [raw]({RAW}{encoded}) ({len(data):,} bytes)")
        manifest.append({"path": path, "bytes": len(data), "sha256": hashlib.sha256(data).hexdigest()})
    (ROOT / "FILE_INDEX.md").write_text("\n".join(index) + "\n", encoding="utf-8")
    (ROOT / "publication-manifest.json").write_text(json.dumps({
        "description": "File-level hashes of public materials; excludes this manifest and the generated index.",
        "files": manifest}, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(f"Indexed {len(all_files)} files; wrote {len(chunks)} text bundles.")


if __name__ == "__main__":
    main()
