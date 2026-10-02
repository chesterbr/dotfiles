<!--
  GitHub stacked pull requests - general reference. Imported from CLAUDE.md.
  General/cross-project; keep free of employer-specific detail.
-->

# GitHub stacked pull requests

GitHub has a **native** stacked-PR feature. (Do not claim it doesn't - corrected 2026-09
after I wrongly asserted "no native stack.") A stack = 2+ PRs in one repo where the bottom
targets the default branch and each subsequent PR targets the branch below it. The
foundation is still ordinary base branches; the native layer adds:

- **UI:** a stack icon + layer number per PR, a "stack map" in the merge box with one-click
  navigation between layers, and a "Preview stack" banner on stackable PRs.
- **`gh stack`** CLI extension to create/link a managed stack.
- **Auto-retarget + cascading rebase on merge:** merging the bottom PR automatically
  **rebases** the remaining branches so the next one targets the default branch.

Key facts to keep straight:

- **Merging stays per-PR.** You can merge the whole stack, one PR, or part of it, but it is
  bottom-up and yields the same history as merging each individually. There is **no single
  combined merge or deploy** - each PR is its own merge/deploy. (Want one atomic deploy? That
  is a single PR, or the merge queue - not a stack.)
- Same-repo only (no cross-fork stacks); available in CLI/web/mobile/API; **not** GitHub
  Desktop; CI/checks and rules apply to each layer independently.
- A stack's real payoff is **review/authoring** (each PR's diff shows only its own changes,
  and you can open the child before the parent merges), not deployment.

## Caveat vs my git rules

The native managed stack's auto-restack **rebases** child branches. That runs against the
standing rule that rebasing an already-pushed branch needs explicit confirmation (and, where
a stricter project rule applies, "never rebase pushed branches - reconcile with merge"). So
default to a **plain base-branch stack** - set the base explicitly
(`gh pr create --base <parent-branch>`) and, after the parent merges, reconcile the child
with a **merge** (GitHub retargets the child's base to the default branch on parent merge; the
merge brings in the squashed parent). Only opt into the native managed stack / `gh stack`
auto-rebase when the rebase has been explicitly okayed.
