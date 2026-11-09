<!--
Thanks for contributing! Please keep PRs focused.
Do not include secrets, tokens, tenant identifiers, or any Entra ID / Intune record content.
-->

## What & why

<!-- What does this change do, and what problem does it solve? -->

## Checklist

- [ ] `pnpm lint`, `pnpm check` and `pnpm build` are all green
- [ ] New `.ts` / `.svelte` files carry the `SPDX-License-Identifier: AGPL-3.0-only` header
- [ ] Conventional Commit title (`feat:` / `fix:` / `docs:` / … ; `!` for breaking)
- [ ] No tenant-specific or customer-specific values added (kept configurable)
- [ ] Svelte 5 conventions: `SvelteMap`/`SvelteSet` over native, `const` for `$derived`, every `{#each}` keyed
- [ ] Graph API endpoints verified to actually exist — many documented Intune endpoints are removed or 500

## Notes for reviewers

<!-- Anything reviewers should focus on, risks, follow-ups. -->

## Issue

<!-- Closes #<number> on a line of its own for each issue of this repository this change completes (Closes owner/repo#<number> means the same). Refs #<number> when it only relates to one. A change with no issue says "Task: none, <reason>" on a line of its own. -->

## Acceptance evidence

<!-- One row per acceptance criterion of every issue this change closes, copied exactly from the issue's "- [ ] ACn" list. Evidence class is code, live or browser. In Proof, put repository paths in backticks, and write anything else (a command, a read-back, a run) without them. Delete the example row. Leave the table out only when the change closes no issue. -->

| Issue | AC  | AC text                                 | Evidence class | Proof                                  |
| ----- | --- | --------------------------------------- | -------------- | -------------------------------------- |
| #N    | AC1 | The acceptance criterion, word for word | code           | `path/to/the_test.go` TestWhatItProves |
