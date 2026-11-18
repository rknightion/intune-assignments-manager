# Review Intune Assignments Manager changes

## Software and operators

Intune administrators use this browser-only Svelte application to inspect policies and manage
assignments. Trace routes in `src/routes/`, browser authentication in `src/lib/auth/` and Graph
request and assignment logic in `src/lib/graph/`.

## Invariants

Preserve the fetch, merge and apply order in `src/lib/graph/execute.ts`. Graph assignment writes
replace the full list, so retain unaffected assignments and verify the merge before applying it.
Use Svelte 5 reactive collections and unique keys for collections with repeated Graph IDs.
Keep effects tied to explicit dependencies and review for repeated requests.

## Sensitive changes

Check Graph endpoint choice against `docs/development/graph-endpoint-findings.md` and preserve
the shared pagination, batching and throttling behavior. Keep token handling browser-side and
verify with synthetic tenant data. Keep visual edits on the CSS token layer in `src/app.css`.

## Checks already in CI

`just check` covers formatting, lint and Svelte type checking. `just build` separately proves
the production bundle. Preserve both checks and the required `ci-success` gate. Review semantic
behavior and coverage gaps beyond findings already reported by those checks.

## Verification

Run `just check </dev/null` and `just build </dev/null` with the documented placeholder settings.
For UI changes, exercise the affected flows in a browser with a clean console and a synthetic or
authorized isolated input. For Graph changes, verify loading, repeated IDs and assignment merge
cases without writing live tenant state during review.
