# intune-assignments-manager

SvelteKit app for bulk-managing Intune app and configuration-profile assignments through Microsoft
Graph. Deployed to Cloudflare Pages, client-side only: no server backend, no Node built-ins, and all
auth and API calls happen in the browser.

## Gate

`just check` is the PR gate, but CI runs a separate build job, so a change is not proven until both
`just check` and `just build` pass. There is no test framework; `just test` is a deliberate no-op.

`PUBLIC_ENTRA_CLIENT_ID` is the only env var, and the justfile exports an all-zeros placeholder so
type-check and build resolve without one. Override it in `.env` for `just dev` - a real sign-in needs
the real client ID.

## Graph traps

- The base is `https://graph.microsoft.com/beta`. Many Intune endpoints are `/beta`-only, deprecated,
  or behave differently from their documented shape. Verify an endpoint responds before building on
  it, and record the result in the **Microsoft Graph endpoint findings (live-verified)** backlog doc
  rather than re-probing.
- **The `assign` action replaces every assignment on the item.** Any write path must fetch current
  assignments, merge, then POST the whole merged list - the fetch/merge/apply shape in
  `src/lib/graph/execute.ts`. Skipping the fetch silently deletes assignments nobody asked to touch.
- The batch endpoint is auto-chunked at 20 requests; 429 retries and the `@odata.nextLink` walk live
  in `src/lib/graph/client.ts`. Use that client, never a bare `fetch`.

## Svelte 5 conventions

Use `SvelteMap` / `SvelteSet` from `svelte/reactivity` rather than native `Map`/`Set` in reactive
state, `const` (not `let`) for `$derived`, no `svelte:component`, and a unique key on every `{#each}`.

## Do not mine `todos.txt`

`todos.txt` and `todos-completed.txt` are the original build plan and are history, not a queue. The
open queue is `backlog task list --plain`.

## Task tracking

Tasks are `asm-NNNN`. `backlog/` is committed to a **public** repository, so tasks and docs must never
carry a tenant id, object id, UPN, email address, device name, group name, or any value copied out of
a live tenant. Write the shape, not the instance: `<tenant-id>`, "the second device in the failed
list". Aggregate counts, timings and structural findings are fine. Sweep before committing:

```bash
grep -rniE "@[a-z0-9-]+\.(com|net|io|onmicrosoft\.com)|[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}" backlog/ && echo "IDENTIFIERS FOUND"
```

Read the **Agent fan-out protocol (canonical)** doc before designing a wave, and the **Wave operating
model** doc for this project's lane boundaries and exclusive resources. Earlier GitHub issue history
is indexed in the **Closed GitHub issues** doc, with the full record in `archive/issues-dump.json`.
