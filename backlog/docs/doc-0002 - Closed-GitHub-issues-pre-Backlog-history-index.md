---
id: doc-0002
title: 'Closed GitHub issues: pre-Backlog history index'
type: other
created_date: '2026-08-14 16:39'
updated_date: '2026-08-14 16:39'
---
This repository tracked its work in GitHub Issues until 2026-08-14, when it moved to Backlog.md.
Every issue was closed by then, so nothing was imported as a task — the board started empty, which
was the accurate state, not an omission.

**The issues no longer exist on github.com.** They were archived and then deleted. The full record —
bodies, all comments, labels, authors, timestamps — lives in `archive/issues-dump.json`, redacted
per `archive/README.md`. `gh issue view <N>` will not work; use:

```bash
jq -r '.[] | select(.number == 86) | .body' archive/issues-dump.json
jq -r '.[] | select(.number == 86) | .comments[] | .body' archive/issues-dump.json
```

The `#NNN` numbers stay the only ID space for this history. They are cited in commit messages and
in earlier discussion, so backlog task IDs were deliberately not minted over the same work — a
second ID space over one history can never be reconciled with the first.

## The closed set

9 issues total: 8 closed, plus `#20`, Renovate's dependency dashboard, which was live and was kept.

| # | Title | Closed | Landed in |
|---|---|---|---|
| 94 | Close layout gaps against the design system's intune-assignments UI kit | 2026-08-09 | `398fcf2` |
| 93 | Adopt the m7kni design system token layer | 2026-08-09 | `549a1ec` |
| 87 | Mirror remaining 2otel repo config: issue templates and label set | 2026-08-09 | `165396e` and the `.github/` work around it |
| 86 | `pnpm check` and `pnpm lint` are both broken by TypeScript 7.0.2 | 2026-08-08 | `db835fd`, `d502e28`, `ed9fa00`, `06b3acf` |
| 85 | docs-sync will fail after the org transfer: Tailscale WIF identity still pinned to m7kni | 2026-08-09 | infrastructure-side, no commit in this repo |
| 84 | Move repo from m7kni org to rknightion, and prepare for AGPLv3 OSS release | 2026-08-08 | `d74688d` |
| 56 | Docs site: redesign & rebrand alignment + SEO/LLM discoverability | 2026-07-03 | `cd27833`, `ae348ab`, `b6365f3`, `f8529fd` |
| 5 | Dependency Dashboard (Renovate) | 2026-03-16 | n/a — bot dashboard, superseded by `#20` |

## What is worth knowing without opening the archive

Four findings from that history are expensive to re-derive and easy to undo by accident.

**TypeScript is pinned to `^6.x` on purpose (`#86`).** TypeScript 7.0.2 silently breaks both
`pnpm check` and `pnpm lint` while `pnpm build` stays green — so a green build proves nothing about
the gates. `typescript-eslint`, `svelte-check` and `eslint` were all already at their latest
published versions, so there was nothing to upgrade to and TypeScript was the only lever. A Renovate
`allowedVersions: <7.0.0` constraint holds it, with the reasoning inline. Do not lift it because a
newer major exists.

**ESLint flat config does not read `.gitignore` (`#86`).** With `site/` untracked but present on
disk, ESLint was linting minified zensical bundles — 699 of an apparent 795 errors. `site/` and
vendored `docs/javascripts/` are in the `ignores` list for that reason.

**A correction that was made inside `#86` and should not be re-reversed:** the 14
`svelte/require-each-key` errors were first called latent instances of the duplicate-key reactivity
bug. That was wrong. That bug comes from Graph API data returning repeated ids
(`deviceCompliancePolicyStates`); those loops were fixed-length `{#each Array(N) as _}` skeleton
placeholders that could never collide. Lint hygiene, not a defect. The real duplicate-key hazard
remains real everywhere the keys come from Graph data.

**`IconComponent` is deliberately the legacy Svelte 4 type (`#86`).** `src/lib/types/ui.ts` types
lucide icon props as `ComponentType<SvelteComponent<IconProps>>`, not Svelte 5's
`Component<IconProps>`, because lucide-svelte 1.0.1 still declares a `svelte ^4.2.19` peer and ships
`SvelteComponentTyped` subclasses. Typing it the modern way type-checks at the definition and then
fails at every call site — it took svelte-check from 6 errors to 102. Likewise the report row shapes
in `src/lib/types/reports.ts` are `type` aliases rather than `interface`s: interfaces stay open to
declaration merging, so TypeScript will not infer an implicit index signature and refuses assignment
to `Record<string, unknown>[]`.

## Not imported, and why

`todos.txt` and `todos-completed.txt` are the original build plan. Every phase in them is marked
complete, and the last unmarked item — the navigation restructure — was verified as shipped
(`/updates`, `/remediations`, `/scripts`, `/autopilot` all exist and sit in the grouped sidebar in
`src/routes/+layout.svelte`). They are completion artefacts for shipped work, not a queue, and were
left in place rather than mined for tasks.
