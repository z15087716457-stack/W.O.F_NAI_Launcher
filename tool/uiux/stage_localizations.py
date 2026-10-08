"""Stage explicitly named UIUX messages without other agents' uncommitted keys.

The working ARBs and generated Dart are never overwritten. The commit versions
are generated from HEAD plus only the requested message keys in a scratch project.
"""
import argparse
import json
from pathlib import Path
import subprocess


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--keys", required=True, type=Path)
    parser.add_argument("--scratch", required=True, type=Path)
    args = parser.parse_args()
    src = Path.cwd().resolve()
    scratch = args.scratch.resolve()
    scratch.mkdir(parents=True, exist_ok=True)
    messages = json.loads(args.keys.read_text(encoding="utf-8"))
    keys = [item for key in messages for item in (key, "@" + key)]
    arb_dir = scratch / "lib/l10n"
    arb_dir.mkdir(parents=True, exist_ok=True)
    for locale in ["en", "zh", "zh_TW", "ja", "ko"]:
        path = f"lib/l10n/app_{locale}.arb"
        head = json.loads(subprocess.check_output(["git", "show", "HEAD:" + path], cwd=src))
        working = json.loads((src / path).read_text(encoding="utf-8"))
        for key in keys:
            if key in working:
                head[key] = working[key]
            else:
                head.pop(key, None)
        (scratch / path).write_text(json.dumps(head, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    (scratch / "pubspec.yaml").write_text(
        "name: nai_launcher\nenvironment:\n  sdk: '>=3.8.0 <4.0.0'\ndependencies:\n  flutter:\n    sdk: flutter\nflutter:\n  generate: true\n",
        encoding="utf-8",
    )
    (scratch / "l10n.yaml").write_bytes((src / "l10n.yaml").read_bytes())
    subprocess.run(["flutter.bat", "gen-l10n"], cwd=scratch, check=True)
    for path in sorted(arb_dir.glob("*")):
        if path.suffix not in (".arb", ".dart"):
            continue
        target = "lib/l10n/" + path.name
        blob = subprocess.check_output(["git", "hash-object", "-w", str(path)], cwd=src).decode().strip()
        subprocess.run(["git", "update-index", "--add", "--cacheinfo", f"100644,{blob},{target}"], cwd=src, check=True)
    print(json.dumps({"messages": sorted(messages), "stagedFiles": len(list(arb_dir.glob("*")))}, ensure_ascii=False))


if __name__ == "__main__":
    main()
