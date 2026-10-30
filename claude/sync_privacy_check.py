#!/usr/bin/env python3
"""Privacy check run by the sync scripts before they commit.

Rules live in claude/references/sync-privacy.md (plus an optional --extra rules file).

  memory FILE...   Print the memory files that must stay out of the repo, one per line.
                   Untagged or `visibility: private` files are excluded without a model call;
                   `visibility: org` files are double-checked by the model (cached by content hash).
  diff             Read a staged diff on stdin and fail if it breaks the public-repo rules.
  audit FILE...    Classify every file regardless of tags and print a verdict table.
  allow FILE...    Record my decision that these files (as they are now) are fine to sync.

Exit codes: 0 ok, 1 diff flagged, 2 classifier unavailable (callers must not push).
"""

import argparse
import hashlib
import json
import os
import re
import subprocess
import sys
from pathlib import Path

RULES = Path(__file__).resolve().parent / "references" / "sync-privacy.md"
CACHE = Path.home() / ".cache" / "claude-sync-privacy.json"
CHUNK_BYTES = 60_000


class ClassifierError(Exception):
    pass


def visibility(text):
    match = re.match(r"^---\n(.*?)\n---", text, re.S)
    if not match:
        return None
    tag = re.search(r"^\s*visibility:\s*(\w+)", match.group(1), re.M)
    return tag.group(1) if tag else None


def rules_text(extra, public=False):
    """The rule sections for this audience (the memory-tagging section is bookkeeping, not a rule)."""
    text = RULES.read_text().split("## Memory files")[0]
    if not public:
        text = text.split("## Also never in the public repo")[0]
    if extra:
        text += "\n\n" + Path(extra).read_text()
    return text


def ask_model(prompt):
    env = dict(os.environ, CLAUDE_SYNC_CLASSIFIER="1")  # sync.sh exits early under this
    try:
        result = subprocess.run(
            ["claude", "-p", "--model", os.environ.get("SYNC_PRIVACY_MODEL", "sonnet"), "--no-session-persistence", "--output-format", "text"],
            input=prompt, capture_output=True, text=True, timeout=300, cwd="/tmp", env=env,
        )
    except (OSError, subprocess.TimeoutExpired) as error:
        raise ClassifierError(str(error))
    match = re.search(r"\[.*\]", result.stdout, re.S)
    if result.returncode != 0 or not match:
        raise ClassifierError(result.stderr.strip() or result.stdout.strip()[:200])
    try:
        return json.loads(match.group(0))
    except json.JSONDecodeError as error:
        raise ClassifierError(str(error))


def classify(files, rules, audience, retry=True):
    """Return {path: (verdict, reason)} where verdict is "ok" or "private"."""
    chunks, size = [[]], 0
    for path in files:
        body = Path(path).read_text()
        if chunks[-1] and size + len(body) > CHUNK_BYTES:
            chunks.append([])
            size = 0
        chunks[-1].append((path, body))
        size += len(body)

    verdicts = {}
    for chunk in filter(None, chunks):
        by_name = {Path(p).name: p for p, _ in chunk}
        docs = "\n\n".join(f'<file name="{Path(p).name}">\n{b}\n</file>' for p, b in chunk)
        prompt = (
            f"These files are about to be committed to a repo readable by {audience}.\n"
            "Judge each file against the rules below. Mark it private if any part breaks "
            "a rule; otherwise ok.\n\n"
            f"<rules>\n{rules}\n</rules>\n\n{docs}\n\n"
            'Answer with only a JSON array: [{"file": "<name>", "verdict": "ok"|"private", '
            '"reason": "<short; quote the offending phrase>"}]'
        )
        answers = ask_model(prompt)
        for item in answers:
            name = Path(str(item.get("file", ""))).name
            if len(chunk) == 1 and len(answers) == 1:
                name = Path(chunk[0][0]).name
            if name in by_name and item.get("verdict") in ("ok", "private"):
                verdicts[by_name[name]] = (item["verdict"], item.get("reason", ""))
    missing = [p for p in files if p not in verdicts]
    if missing and retry:
        verdicts.update(classify(missing, rules, audience, retry=False))
    elif missing:
        raise ClassifierError(f"no verdict for {missing}")
    return verdicts


def load_cache():
    try:
        return json.loads(CACHE.read_text())
    except (OSError, json.JSONDecodeError):
        return {}


def save_cache(cache):
    CACHE.parent.mkdir(parents=True, exist_ok=True)
    CACHE.write_text(json.dumps(cache, indent=1))


def digest(path):
    return hashlib.sha256(Path(path).read_bytes()).hexdigest()


def memory(files, extra):
    cache, to_check, excluded = load_cache(), [], []
    for path in files:
        text = Path(path).read_text()
        if path.endswith(".private.md") or visibility(text) != "org":
            excluded.append(path)
        elif cache.get(digest(path), {}).get("verdict") == "private":
            excluded.append(path)
        elif digest(path) not in cache:
            to_check.append(path)
    if to_check:
        for path, (verdict, reason) in classify(to_check, rules_text(extra), "my employer's org").items():
            cache[digest(path)] = {"verdict": verdict, "reason": reason}
            if verdict == "private":
                excluded.append(path)
                print(f"kept local: {Path(path).name} ({reason})", file=sys.stderr)
        save_cache(cache)
    print("\n".join(excluded))


def diff(extra):
    patch = sys.stdin.read()
    added = "\n".join(l for l in patch.splitlines() if l.startswith(("+", "diff --git")))
    if not added.strip():
        return 0
    Path("/tmp/claude-sync-diff.txt").write_text(added)
    verdict, reason = classify(["/tmp/claude-sync-diff.txt"], rules_text(extra, public=True), "anyone on the internet")["/tmp/claude-sync-diff.txt"]
    if verdict == "private":
        print(f"privacy check flagged the staged diff: {reason}", file=sys.stderr)
        return 1
    return 0


def audit(files, extra):
    for path, (verdict, reason) in sorted(classify(files, rules_text(extra), "my employer's org").items()):
        print(f"{verdict}\t{Path(path).name}\t{reason}")


def allow(files):
    cache = load_cache()
    for path in files:
        cache[digest(path)] = {"verdict": "ok", "reason": "allowed by hand"}
    save_cache(cache)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("mode", choices=["memory", "diff", "audit", "allow"])
    parser.add_argument("files", nargs="*")
    parser.add_argument("--extra", help="additional rules file")
    args = parser.parse_args()
    try:
        if args.mode == "memory":
            memory(args.files, args.extra)
        elif args.mode == "diff":
            return diff(args.extra)
        elif args.mode == "allow":
            allow(args.files)
        else:
            audit(args.files, args.extra)
    except ClassifierError as error:
        print(f"privacy check unavailable: {error}", file=sys.stderr)
        return 2
    return 0


if __name__ == "__main__":
    sys.exit(main())
