---
id: doc-0003
title: Wave operating model
type: guide
created_date: '2026-08-14 16:41'
updated_date: '2026-08-14 16:41'
---
The fan-out protocol doc is the model — run contract, routing, lane briefs, the goal-file template,
the pre-flight checklist. **Nothing from it is restated here.** This document carries only what is
true of *this* repository: the rules it added, the defects that recur in this codebase, its lane
boundaries and its one exclusive resource.

`backlog doc list --plain` shows both.

## The gate, and the trap in it

```bash
pnpm lint                                                   # eslint, currently 0 errors
PUBLIC_ENTRA_CLIENT_ID=00000000-0000-0000-0000-000000000000 pnpm check   # svelte-check, 0 errors
PUBLIC_ENTRA_CLIENT_ID=00000000-0000-0000-0000-000000000000 pnpm build   # vite + adapter-cloudflare
```

**`pnpm check` and `pnpm build` fail without `PUBLIC_ENTRA_CLIENT_ID` set**, with
`Module '"$env/static/public"' has no exported member 'PUBLIC_ENTRA_CLIENT_ID'` — a SvelteKit
`$env/static/public` failure, not a code error. Any GUID works; nothing authenticates at build time.
A lane that reports this as a type error has misread it, and a lane that "fixes" it by touching
`src/lib/auth/config.ts` has broken working code.

There is **no test framework**. Verification is the three gates plus, for anything user-visible, a
real browser: `pnpm dev`, then drive it through the Chrome MCP server and require a clean console.
Do not invent a test harness mid-wave to satisfy a habit — say the change was gate-verified and
browser-verified, or say it was not.

## Recurring defects in this codebase

Each of these has actually happened here. They are the first things to check when a lane's change
misbehaves, and the first things to review in its diff.

**Duplicate `{#each}` keys silently kill the *parent's* reactivity.** Graph API collections —
`deviceCompliancePolicyStates`, `deviceConfigurationStates` — return repeated ids for one device. An
`each_key_duplicate` thrown in a child component takes out the whole parent update cycle: the
symptom is a tab indicator that moves while the content does not, and `$state` writes that look
ignored. It is not a rendering bug and it will not be found by reading the component that appears
broken. Key by `` `${id}-${index}` `` wherever the ids come from Graph data.

**`$effect` calling an async function tracks everything that function reads.** Read the dependencies
you actually want tracked explicitly, then wrap the call in `untrack()`. Skipping this produces
effect loops that present as runaway Graph requests.

**Svelte 5 conventions are enforced, not stylistic**: `SvelteMap`/`SvelteSet` over native
`Map`/`Set`, `const` for `$derived`, no `svelte:component`. A lane using the Svelte 4 idiom will pass
`pnpm build` and be wrong.

**Graph `assign` endpoints REPLACE the whole assignment list.** Anything touching
`src/lib/graph/execute.ts` must preserve the fetch → merge → apply order. Skipping the fetch silently
deletes every assignment the app did not know about — the single highest-blast-radius path in the
product, and the reason that file is never a parallel lane's incidental edit.

**Many `/beta` Intune endpoints are removed or return 500 while still being documented.** Do not
design a feature around an endpoint without confirming it responds. The verified working and
non-working set is in the Graph endpoint findings doc; add to it rather than re-probing.

**Colours are never invented here.** `src/app.css` is a token layer generated from the m7kni design
system; read the system with DesignSync and change the token, not the call site. `rg` over `src/`
returns zero hex colours and zero Tailwind palette classes, and that property is worth preserving —
it is why an accent change costs one file. Two issues (`#93`, `#94`) exist because it was not obvious.

## Lane boundaries

Natural, non-overlapping lanes in this codebase:

- one route family each — `src/routes/<area>/` plus the `src/lib/components/` used only by it;
- one Graph domain module each — `compliance.ts`, `security.ts`, `devices.ts`, `status.ts`,
  `filters.ts`, `merge.ts`;
- docs (`docs/`) is always safe to run concurrently with code.

**Single-owner files — never edited by two lanes, and never in parallel:**

| File | Why |
|---|---|
| `src/routes/+layout.svelte` | the sidebar registry; every new area appends to it |
| `src/lib/graph/client.ts` | the shared request/retry/batch seam |
| `src/lib/types/graph.ts`, `schemas.ts`, `wizard.ts` | the frozen type seam every lane codes against |
| `src/app.css` | the design token layer |
| `src/lib/graph/execute.ts` | the assignment-merge path, per above |
| `backlog/config.yml` | tracker config |

Freeze the type seam and the token names **before** fan-out. A wave that lets two lanes each add a
field to `wizard.ts` will produce a clean-looking merge that drops one of them.

## The one exclusive resource

**There is exactly one live Intune tenant and one browser MSAL session.** Only one lane at a time may
be driving `pnpm dev` + Chrome MCP, and only one may be issuing writes against the tenant. Graph
write operations against a real tenant are not sandboxed and not reversible by the app. Sequence
browser validation at the wiring checkpoint rather than letting each lane reach for it, and keep
tenant writes on the root agent's thread where a human message authorises them.

Read-only Graph exploration is fine concurrently, but Graph applies a per-tenant throttle: parallel
lanes hammering `fetchAll` will produce 429s that look like application bugs.

## Ownership and the escape hatch

A lane owns its files and its task. It does **not** own: the type seam, the token layer, the tenant,
`git commit`, or the decision to widen its own scope.

**The escape hatch: when a lane hits a decision its brief does not cover, it stops and returns the
question.** It does not guess, and it does not quietly narrow the task to the part it can do. A
boundary with no escape hatch is a stop condition wearing a safety label. One round trip is cheaper
than the rewrite — and in this codebase the expensive class of wrong guess is a Graph endpoint chosen
without verifying it responds, which produces working-looking code that fails only against a real
tenant.

## Run-end against this tracker

Task state is the record.

- landed → `Done`, with the commit SHA in the task's final summary;
- attempted and blocked → `Parked`, with a **concrete** resume boundary: the file, the line, the
  specific unanswered question. "Needs more investigation" is not a resume boundary;
- discovered work → a new task labelled `needs-triage`, never a note in a closing message;
- untouched work stays `To Do` and needs no ceremony.

Finalize in one call so an interrupted run cannot leave finished work looking unfinished:

```bash
backlog task edit ASM-0007 --check-ac 1 --check-ac 2 -s Done
```

The closing terminal message is a covering note — what the run learned that no single task captures —
and **nothing durable may live only there.** Writing it is the last unit of work, not a reply to a
request.
