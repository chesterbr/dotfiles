#!/usr/bin/env bash
set -euo pipefail

# Auto-sync the Claude config that lives in this (public) dotfiles repo.
#
# Wired as Claude Code hooks in claude/settings.json:
#   SessionStart -> sync.sh push    (push any unpushed commits; network op, done at start)
#   SessionEnd   -> sync.sh commit  (commit local changes; fast, finishes before the hook is killed)
#
# The commit is scoped to the claude/ subtree so that unrelated (possibly half-finished)
# dotfile edits are never auto-published to this PUBLIC repo. `.local` overlays are gitignored
# and are never staged. Widen SCOPE to "." if you ever want the whole repo auto-committed.

CLAUDE_DIR="$(cd "$(dirname "$0")" && pwd)"   # .../dotfiles/claude
REPO_DIR="$(cd "$CLAUDE_DIR/.." && pwd)"      # .../dotfiles
SCOPE="claude"

commit() {
  cd "$REPO_DIR"
  if [ -n "$(git status --porcelain -- "$SCOPE")" ]; then
    git add -- "$SCOPE"
    git commit -m "claude config: backup $(date '+%Y-%m-%d %H:%M')" -- "$SCOPE"
    echo "Committed Claude config changes."
  else
    echo "No Claude config changes to commit."
  fi
}

push() {
  cd "$REPO_DIR"
  git push || true
}

case "${1:-}" in
  commit) commit ;;
  push)   push ;;
  *)
    echo "Usage: $0 {commit|push}"
    echo ""
    echo "  commit  Stage + commit changes under claude/ (if any)"
    echo "  push    Push any unpushed commits (non-fatal on failure)"
    exit 1
    ;;
esac
