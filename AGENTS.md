# intune-assignments-manager

SvelteKit app for bulk-managing Intune app and configuration-profile assignments through Microsoft
Graph. Deployed to Cloudflare Pages, client-side only: no server backend, no Node built-ins, and all
auth and API calls happen in the browser.

## Task interface

`just check` is the PR gate, but CI runs a separate build job, so a change is not proven until both
`just check` and `just build` pass. There is no `just ci` recipe. There is no test framework;
`just test` is a deliberate no-op.

`PUBLIC_ENTRA_CLIENT_ID` is the only env var, and the justfile exports an all-zeros placeholder so
type-check and build resolve without one. Override it in `.env` for `just dev` - a real sign-in needs
the real client ID.

`just clean` is `[confirm]`-marked and removes `node_modules` along with the build output; never
pass `--yes` or `JUST_YES=1` to skip that prompt.

## Graph traps

- The base is `https://graph.microsoft.com/beta`. Many Intune endpoints are `/beta`-only, deprecated,
  or behave differently from their documented shape. Verify an endpoint responds before building on
  it, and record the result in `docs/development/graph-endpoint-findings.md` (Microsoft Graph endpoint
  findings, live-verified) rather than re-probing.
- **The `assign` action replaces every assignment on the item.** Any write path must fetch current
  assignments, merge, then POST the whole merged list - the fetch/merge/apply shape in
  `src/lib/graph/execute.ts`. Skipping the fetch silently deletes assignments nobody asked to touch.
- The batch endpoint is auto-chunked at 20 requests; 429 retries and the `@odata.nextLink` walk live
  in `src/lib/graph/client.ts`. Use that client, never a bare `fetch`.

## Svelte 5 conventions

Use `SvelteMap` / `SvelteSet` from `svelte/reactivity` rather than native `Map`/`Set` in reactive
state, `const` (not `let`) for `$derived`, no `svelte:component`, and a unique key on every `{#each}`.

## Tracking work

Work is tracked in this repository's GitHub issues; they are the only queue. Do not add a checklist
file beside them.

- A pull request body says how it relates to an issue, on a line of its own: `Closes #N` with the
  `Acceptance evidence` table from `.github/pull_request_template.md` (one row for each acceptance
  criterion of that issue), `Refs #N` when it only relates to one, or `Task: none, <reason>`.
- A pull request that changes `.github/workflows/` or `.github/actions/` carries no closing keyword:
  write `Task: none, <reason>`, with `Refs #N` beside it if you like.
- Contributors never need the project board or the tracker tooling; a maintainer handles both.
- Issues and pull requests are public, so they carry no tenant id, object id, UPN, email address,
  device name, group name, or any value copied out of a live tenant. Write the shape, not the
  instance: `<tenant-id>`, "the second device in the failed list". Aggregate counts, timings and
  structural findings are fine.
- Older commits and docs cite legacy board ids such as `ASM-0001`. `just issue <ID>` prints the
  issue each one became; `.github/tracker/id-map.json` is the map. The retired board's documents are
  in `.github/tracker/history/`.
- Earlier GitHub issue history is in `archive/issues-dump.json`; those issues no longer exist on
  github.com.

## Deeper references

- `docs/development/graph-endpoint-findings.md` - read before probing a Graph endpoint, and add to it
  when you verify one.
