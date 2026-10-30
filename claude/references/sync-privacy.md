# What stays out of synced repos

My config and memories back up to repos other people can read: this one is public, and my work
config repo is readable by my employer's org. I keep professional discretion in both. Notes that
fall under any rule below stay local-only (never committed), and the sync scripts check for them
before each commit (`claude/sync_privacy_check.py`).

## Never in a shared repo (public or org-visible)

- Performance reviews, 1:1s, career or promotion plans, compensation.
- Health, mood, personal circumstances, or the reasons behind time off.
- Judgements about named people: their work, workload, habits, or decisions. Naming someone in a
  neutral fact ("Fabio reviewed the PR") is fine; pairing a name with an opinion is not.
- Private messages quoted or paraphrased from named people.
- Hiring, departures, or org changes not yet public.
- How to word something so it draws less scrutiny or review. (Plainly stating what I'm skipping
  or deprioritizing is fine; reading as dodging something clearly mine is not.)
- Secrets, and anything token-like (webhook URLs, feed or invite URLs with an embedded key).

## Also never in the public repo

- Anything employer-internal: hostnames, buckets, where secrets live, internal tools and
  vendors, ticket or project IDs, people's names, customers.
- Details that help someone attack my own servers (open ports, missing TLS, sudo setup).

## Memory files

Every memory file carries `metadata.visibility` in its frontmatter: `org` (fine for the work
repo) or `private` (local-only). Set it when the memory is written; a file without it counts as
private. `*.private.md` filenames are always private.
