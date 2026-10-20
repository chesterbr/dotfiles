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

## Rules enforcement

Every layer of a native stack is evaluated against the rules of the stack's **trunk** (usually
`main`): required reviews, CODEOWNERS and status checks, as if it targeted the trunk directly. A
plain base-branch stack gets the rules of the child's actual target (a feature branch, often
none), so a child can look "approved" on a single review it would fail on the trunk. That
enforcement is the main reason to make a stack native.

## Caveat vs my git rules (decided 2026-10-20)

The native managed stack's auto-restack **rebases** child branches, which runs against my rule
that pushed branches aren't rebased. I accept it as a deliberate exception: **default to a
native stack** for stacked PRs, and let GitHub restack its branches. The exception covers only
GitHub's own restack of a native stack; I still never rebase or force-push by hand, and a plain
base-branch stack (if I ever use one) is still reconciled with a **merge** after the parent
merges. Merge bottom-up, one PR at a time: merging a higher layer also merges every unmerged
layer below it, so only do that when I explicitly want the whole stack in.
