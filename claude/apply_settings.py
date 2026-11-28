#!/usr/bin/env python3
"""Generate ~/.claude/settings.json from the shared base plus this machine's overrides.

  base       claude/settings.json (tracked: applies to every machine)
  overrides  ~/.claude/settings.overrides.json (untracked: this machine only; wins over the base)

Objects are merged key by key; anything else, lists included, is replaced by the override.
To drop single items from a shared list, use "_remove": {"permissions.allow": ["..."]}.

Changes made to the generated file (by /config, /model, plugin installs, ...) are kept and
reported until they are moved into the base or the overrides.

  (no args)  write the file
  --dry-run  show the result and how it differs from the current file; write nothing
  --check    report unclassified local changes only
  --adopt    first run over a hand-written file: back it up, then replace it
"""

import argparse
import copy
import difflib
import json
import os
import shutil
import sys
from pathlib import Path

BASE = Path(__file__).resolve().parent / "settings.json"
CLAUDE_DIR = Path.home() / ".claude"
TARGET = CLAUDE_DIR / "settings.json"
OVERRIDES = CLAUDE_DIR / "settings.overrides.json"
STATE = CLAUDE_DIR / "settings.generated.json"  # base + overrides as of the last write
BACKUP = CLAUDE_DIR / "settings.json.pre-generator"
MISSING = object()


def load(path):
    return json.loads(path.read_text()) if path.exists() else {}


def merge(base, over):
    if not (isinstance(base, dict) and isinstance(over, dict)):
        return copy.deepcopy(over)
    result = copy.deepcopy(base)
    for key, value in over.items():
        result[key] = merge(result[key], value) if key in result else copy.deepcopy(value)
    return result


def desired():
    overrides = load(OVERRIDES)
    removals = overrides.pop("_remove", {})
    result = merge(load(BASE), overrides)
    for dotted, items in removals.items():
        *parents, leaf = dotted.split(".")
        node = result
        for part in parents:
            node = node.get(part, {})
        if leaf in node:
            node[leaf] = [item for item in node[leaf] if item not in items]
    return result


def changes(old, new, path=()):
    """Yield (path, value) for what differs in new; value is MISSING for removed keys."""
    for key in sorted(set(old) | set(new)):
        before, after = old.get(key, MISSING), new.get(key, MISSING)
        if isinstance(before, dict) and isinstance(after, dict):
            yield from changes(before, after, path + (key,))
        elif before != after:
            yield path + (key,), after


def apply_changes(settings, drift):
    result = copy.deepcopy(settings)
    for path, value in drift:
        node = result
        for part in path[:-1]:
            node = node.setdefault(part, {})
        if value is MISSING:
            node.pop(path[-1], None)
        else:
            node[path[-1]] = value
    return result


def lookup(settings, path):
    for part in path:
        if not isinstance(settings, dict) or part not in settings:
            return MISSING
        settings = settings[part]
    return settings


def dump(settings):
    return json.dumps(settings, indent=2, ensure_ascii=False) + "\n"


def write(path, text):
    temp = path.with_name(path.name + ".tmp")
    temp.write_text(text)
    os.replace(temp, path)  # replaces a symlink itself, never the file it points to


def report(drift):
    print("Claude settings changed on this machine and not yet classified. For each key, move it "
          f"to {BASE} (all machines) or {OVERRIDES} (this machine), then run {__file__}:")
    for path, value in drift:
        print(f"  {'.'.join(path)} = {'(removed)' if value is MISSING else json.dumps(value)}")


def main():
    parser = argparse.ArgumentParser()
    mode = parser.add_mutually_exclusive_group()
    for flag in ("--dry-run", "--check", "--adopt"):
        mode.add_argument(flag, action="store_true")
    args = parser.parse_args()

    wanted = desired()
    # a symlink (the previous setup) holds nothing of its own, so there is nothing to preserve
    current = load(TARGET) if TARGET.exists() and not TARGET.is_symlink() else None
    last = load(STATE) if STATE.exists() else None

    drift, conflicts = [], []
    if current is not None and last is not None:
        # a change stops being drift once base + overrides agree with it
        drift = [(p, v) for p, v in changes(last, current) if lookup(wanted, p) != v]
    elif current is not None:
        conflicts = [(p, v) for p, v in changes(wanted, current) if v is not MISSING]
    result = apply_changes(wanted, drift)

    if args.check:
        if drift:
            report(drift)
        return 0
    if args.dry_run:
        before = dump(current) if current is not None else ""
        print(dump(result))
        print("".join(difflib.unified_diff(before.splitlines(True), dump(result).splitlines(True),
                                           "current", "generated")))
        if conflicts:
            print("Would need --adopt; current values that would be replaced:",
                  ", ".join(".".join(p) for p, _ in conflicts))
        if drift:
            report(drift)
        return 0
    if conflicts and not args.adopt:
        print(f"{TARGET} has values that neither the base nor the overrides produce: "
              f"{', '.join('.'.join(p) for p, _ in conflicts)}. Nothing written. Put what should "
              f"stay in {OVERRIDES}, check with --dry-run, then run with --adopt.", file=sys.stderr)
        return 1

    CLAUDE_DIR.mkdir(parents=True, exist_ok=True)
    if args.adopt and current is not None:
        shutil.copy2(TARGET, BACKUP)
    if TARGET.is_symlink() or current != result:
        write(TARGET, dump(result))
    write(STATE, dump(wanted))
    if drift:
        report(drift)
    return 0


if __name__ == "__main__":
    sys.exit(main())
