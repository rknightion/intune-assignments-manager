# Loop: intune-assignments-manager
tier: routine
gate: just check
ci-required: ci-success
grafana-stack: none

Public repository: no tenant ID, object ID, UPN, email, device or group name, or any value copied
from a live tenant in any tracked file or loop artifact. The gate is `just check` plus `just build`
(CI runs a separate build job); there is no test framework and `just test` is a deliberate no-op,
so do not invent a harness mid-run. Say whether a change was gate-verified and browser-verified.

## Credentials

- None held by the loop. `PUBLIC_ENTRA_CLIENT_ID` is the only env var; the justfile exports an
  all-zeros placeholder so type-check and build resolve. A failure about
  `$env/static/public` is that missing variable, not a code error: do not touch
  `src/lib/auth/config.ts`.

## Traps

- Duplicate `{#each}` keys silently kill the parent's reactivity (a tab indicator moves while the
  content does not): Graph collections such as `deviceCompliancePolicyStates` repeat ids for one
  device. Key by `` `${id}-${index}` `` wherever ids come from Graph data.
- An `$effect` calling an async function tracks everything it reads: read the wanted dependencies
  explicitly and wrap the call in `untrack()`, or it loops into runaway Graph requests.
- Svelte 5 conventions are enforced (`SvelteMap`/`SvelteSet`, `const` for `$derived`, no
  `svelte:component`); the Svelte 4 idiom passes `just build` and is wrong.
- `src/lib/graph/execute.ts` keeps fetch, merge, apply order: the `assign` action replaces the whole
  assignment list. Never an incidental edit in another lane's change.
- Many `/beta` Intune endpoints are removed or return 500 while documented: confirm an endpoint
  responds, and record it in the Graph endpoint findings doc instead of re-probing.
- `src/app.css` is a token layer generated from the m7kni design system; change the token, not the
  call site. `src/` has zero hex colours and zero Tailwind palette classes: keep it so.
- Browser verification is `pnpm dev` driven through the Chrome MCP server with a clean console.

## Mutexes

- One live Intune tenant and one browser MSAL session: one lane at a time drives `pnpm dev` plus
  Chrome, and only the root issues tenant writes (not sandboxed, not reversible by the app).
  Read-only Graph exploration is fine, but per-tenant throttling makes parallel `fetchAll` calls
  produce 429s that look like app bugs.
- Single owner, never parallel: `src/routes/+layout.svelte` (sidebar registry),
  `src/lib/graph/client.ts`, `src/lib/types/graph.ts`, `schemas.ts`, `wizard.ts` (the frozen type
  seam), `src/app.css`, `src/lib/graph/execute.ts` and `backlog/config.yml`. Freeze the type seam
  and token names before lanes fan out.
- Natural lanes: one route family each (`src/routes/<area>/` plus components used only by it), one
  Graph domain module each (`compliance.ts`, `security.ts`, `devices.ts`, `status.ts`,
  `filters.ts`, `merge.ts`). `docs/` is always safe to run concurrently with code.

## Lane brief

A decision the brief does not cover stops the lane and returns the question: no guess, and no
quietly narrowing the task. The costly wrong guess here is a Graph endpoint chosen without checking
it responds.
