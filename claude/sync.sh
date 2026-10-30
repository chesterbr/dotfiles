#!/usr/bin/env bash
set -euo pipefail

# Auto-sync these dotfiles across machines (work mac + personal mac/linux).
#
# Wired as Claude Code hooks in claude/settings.json (sessions fire on every machine):
#   SessionStart -> sync.sh push    (pull latest ff-only, then push local commits)
#   SessionEnd   -> sync.sh commit  (commit tracked changes; fast, before the hook is killed)
#
# This repo is PUBLIC on purpose (keeps secrets out of config). Guards:
#   - commit stages TRACKED files only (git add -u), never `-A`: new/untracked files are
#     never auto-published; opt them in with a manual `git add`.
#   - a secret scan aborts the commit if a key/token slips into a tracked file.
#   - *.local / *.local.* are gitignored everywhere as machine-specific escape hatches.
#   - before pushing, outgoing commits go through the privacy check (claude/sync_privacy_check.py,
#     rules in claude/references/sync-privacy.md); a flag or an unavailable check skips the push.

REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"   # .../dotfiles
LOG="$HOME/.cache/dotfiles-sync.log"

# The privacy check runs headless Claude, whose own session hooks would call back into this script.
[ -n "${CLAUDE_SYNC_CLASSIFIER:-}" ] && exit 0

# Scan staged changes; non-zero => a likely secret is present. Prefer gitleaks (fast,
# comprehensive); fall back to a high-signal grep if it isn't installed.
secret_scan() {
  cd "$REPO_DIR"
  if command -v gitleaks >/dev/null 2>&1; then
    local rc=0
    gitleaks git --staged --no-banner --redact . >/dev/null 2>&1 || rc=$?
    case "$rc" in 0) return 0 ;; 1) return 1 ;; *) : ;; esac   # other rc = gitleaks error -> grep fallback
  fi
  git diff --cached | grep -Eq \
    -e '-----BEGIN [A-Z ]*PRIVATE KEY-----' -e 'AKIA[0-9A-Z]{16}' \
    -e 'xox[baprs]-[0-9A-Za-z-]{10,}' -e 'gh[pousr]_[0-9A-Za-z]{20,}' \
    -e 'github_pat_[0-9A-Za-z_]{20,}' && return 1 || return 0
}

commit() {
  cd "$REPO_DIR"
  git add -u                                    # tracked files only, never -A
  if git diff --cached --quiet; then
    echo "dotfiles: no tracked changes to commit."
    return 0
  fi
  if ! secret_scan; then
    echo "dotfiles: ABORTED - possible secret in staged changes. Inspect 'git diff --cached', fix, commit by hand." >&2
    git reset -q
    return 1
  fi
  git commit -q -m "dotfiles backup $(date '+%Y-%m-%d %H:%M')"
  echo "dotfiles: committed tracked changes."
}

push() {   # SessionStart: integrate other machines first, then publish
  cd "$REPO_DIR"
  if ! git pull --ff-only -q; then
    echo "dotfiles: pull is NOT fast-forward (diverged from another machine). Reconcile by hand; skipping push." >&2
    return 0
  fi
  if [ -n "$(git log --oneline @{u}..HEAD)" ]; then
    local rc=0
    git diff @{u}..HEAD | python3 "$REPO_DIR/claude/sync_privacy_check.py" diff || rc=$?
    if [ "$rc" -ne 0 ]; then
      echo "dotfiles: push skipped (privacy check, see above). Fix it, then fold the fix into the unpushed commits with 'git reset --soft @{u}' and commit again." >&2
      return 0
    fi
  fi
  git push -q || echo "dotfiles: push failed (see above)." >&2
}

case "${1:-}" in
  commit) commit ;;
  # Hooks get 30s; the privacy check can take longer, so the hook only starts a detached run.
  push)   mkdir -p "$(dirname "$LOG")"; nohup "$0" push-now >>"$LOG" 2>&1 & ;;
  push-now) push ;;
  *) echo "Usage: $0 {commit|push}"; exit 1 ;;
esac
