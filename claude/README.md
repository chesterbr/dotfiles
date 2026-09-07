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

- **SessionStart** → `sync.sh push` (push any unpushed commits)
- **SessionEnd** → `sync.sh commit` (commit changes under `claude/`)

The commit is **scoped to `claude/`** so unrelated dotfile edits are never auto-published to this
public repo. The split (commit at end, push at start) exists because a network push is too slow
for the SessionEnd hook window.

## Never commit here

This repo is public. These must never be added (they are gitignored and/or live only in `~/.claude`):

- `~/.claude/remote-settings.json` — contains an org telemetry API key
- `~/.claude.json` and `~/.claude/backups/*` — account/OAuth state
- any `*.local.md` / `*.local.json` — machine-local / private overlays

## First-time setup on a new machine

1. `../install` — creates the symlinks.
2. If official plugins aren't found, register the official marketplace once:
   in Claude Code run `/plugin marketplace add anthropics/claude-plugins-official`.
3. Restart Claude Code. On the work machine, approve the one-time external-import prompt for
   `CLAUDE.work.md`.
