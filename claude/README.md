# Claude Code config (personal base)

Personal/general [Claude Code](https://claude.com/claude-code) configuration, shared across
all my machines (work and personal) via the same dotbot symlinks as the rest of these dotfiles.

Company-specific (Wrapbook) configuration lives in a **separate** repo and is layered on top
only where that repo is checked out — this repo never contains work-specific config or secrets.

## What's here

| File | Linked to | Purpose |
|---|---|---|
| `settings.json` | `~/.claude/settings.json` | Personal base settings: model, thinking/effort, macOS sound hooks, `/tmp` permissions, official-marketplace plugins, and the auto-sync hooks below. |
| `CLAUDE.md` | `~/.claude/CLAUDE.md` | Global instructions. Imports the work overlay and a private local overlay (both optional / skipped if absent). |
| `commands/` | files under `~/.claude/commands/` | Personal slash commands (e.g. `prepare-pr`). |
| `sync.sh` | — | Auto commit/push of this `claude/` dir on Claude session start/end. |

Linked via `../install.conf.yaml` (run `../install` to apply).

## How config layers (base + overlay)

Claude Code merges configuration from several places. This module is the **base**, present on
every machine. Work config is an **additive overlay** present only on the work machine:

- **`~/.claude/CLAUDE.md`** (this repo) `@import`s `…/wrapbook/chesterbr-claude-config/claude-global/CLAUDE.work.md`.
  Missing imports are silently skipped, so personal machines just get the base.
- **Work settings** (permissions, work-marketplace plugins, work sync hooks) live in the work
  repo and are applied at **project scope** (`wrapbook/app/.claude/settings.local.json`), which
  Claude Code merges over these user-level settings. Nothing work-specific lives here.

### Private personal overlay

Anything too personal/sensitive for this **public** repo goes in an untracked, machine-local
file that `CLAUDE.md` imports:

```
~/.claude/CLAUDE.personal.local.md      # never committed; absent by default
```

This mirrors the `ssh/config` → `Include ~/.ssh/config.local` pattern used elsewhere in these
dotfiles.

## Auto-sync

`sync.sh` is wired as Claude Code hooks in `settings.json`:

- **SessionStart** → `sync.sh push`: pull latest fast-forward-only, then push local commits.
- **SessionEnd** → `sync.sh commit`: commit tracked changes (`git add -u`, never `-A`) after a
  secret scan (`gitleaks`, with a high-signal grep fallback) that aborts the commit on a likely
  key or token.

The split (commit at end, push at start) exists because a network push is too slow for the
SessionEnd hook window. New/untracked files are never auto-committed: add them by hand with
`git add` so nothing lands in this public repo by accident.

## Never commit here

This repo is public. These must never be added (they are gitignored and/or live only in `~/.claude`):

- `~/.claude/remote-settings.json` — contains an org telemetry API key
- `~/.claude.json` and `~/.claude/backups/*` — account/OAuth state
- any `*.local` / `*.local.*` files: machine-local / private overlays (gitignored in every dir)

## First-time setup on a new machine

1. `../install` — creates the symlinks.
2. If official plugins aren't found, register the official marketplace once:
   in Claude Code run `/plugin marketplace add anthropics/claude-plugins-official`.
3. Restart Claude Code. On the work machine, approve the one-time external-import prompt for
   `CLAUDE.work.md`.

## Updating an existing machine

For a machine that already has this config set up (symlinks in place, auto-sync running) but is
behind, possibly by several versions. Safe to run interactively:

1. Find the repo (its `origin` is `chesterbr/dotfiles`; usually `~/code/chesterbr/dotfiles`). The
   hooks call `$HOME/code/chesterbr/dotfiles/claude/sync.sh`, so that path must resolve; if the
   real repo lives elsewhere, symlink `~/code/chesterbr/dotfiles` to it.
2. `git fetch`, then look at `git status -sb`:
   - Behind and fast-forwardable: `git pull --ff-only`.
   - Diverged (local unpushed commits from this machine's own auto-sync): stop and reconcile by
     hand. Do not force or blind-rebase. `sync.sh` itself refuses a non-fast-forward pull for
     exactly this reason.
3. `../install` to refresh the symlinks and install any new tooling (on Linux this also installs
   `gitleaks`, used by the commit secret scan).
4. Verify: `~/.claude/settings.json` and `~/.claude/CLAUDE.md` are symlinks into this repo, the
   working tree is clean and up to date with `origin/main`, and a Claude session starts cleanly.
