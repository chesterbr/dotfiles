# Personal Instructions

General instructions for Claude that apply on every machine (work and personal).
Keep this file free of anything company-specific or secret — this repo is public.
Work (Wrapbook) instructions live in a separate repo and are imported below only where
that repo is checked out; personal/secret bits go in an untracked local overlay.

<!-- Add durable, cross-context preferences here (coding style, tone, defaults). -->

---

<!--
  Work (Wrapbook) overlay — imported only on machines where the work config repo is
  checked out. Missing imports are silently skipped, so this line is harmless on
  personal machines. The first time it resolves on the work machine, Claude Code shows
  a one-time approval dialog for the external import; approve it.
-->
@~/code/wrapbook/chesterbr-claude-config/claude-global/CLAUDE.work.md

<!--
  Private personal overlay — untracked, machine-local, never committed to this public
  repo. Put anything too personal/sensitive for a public repo here. Absent by default
  (silently skipped). Mirrors the ssh `Include ~/.ssh/config.local` pattern.
-->
@~/.claude/CLAUDE.personal.local.md
