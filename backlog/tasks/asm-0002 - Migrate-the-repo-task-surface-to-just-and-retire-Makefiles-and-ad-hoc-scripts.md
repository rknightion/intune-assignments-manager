---
id: ASM-0002
title: Migrate the repo task surface to just and retire Makefiles and ad-hoc scripts
status: In Progress
assignee: []
created_date: '2026-08-28 19:20'
updated_date: '2026-08-29 14:05'
labels:
  - 'wave:2-fleet'
dependencies: []
priority: medium
type: chore
ordinal: 2000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
# Migrate intune-assignments-manager's task surface to `just`

Fleet-wide `just` migration per the frozen standard (`JUST-FLEET-STANDARD.md`). This repo has **no
Makefile and no existing justfile** — this is a from-scratch justfile authoring task, not a
translation task. The repo is a SvelteKit/TypeScript app (pnpm), client-side only, deployed to
Cloudflare Pages. **No test framework is configured** — `AGENTS.md` states this explicitly, so `test`
is a documented no-op per §1 of the standard.

## 1. Outcome

`intune-assignments-manager` has a single top-level `justfile` exposing the seven mandatory recipes
plus `dev` and `clean`. `just check` runs `fmt-check`, `lint`, `typecheck`, `test` (no-op) and is
byte-for-byte what CI's three jobs (`lint`, `check`, `build` minus the build itself — see §5) enforce.
`.github/workflows/ci.yml`'s `lint` and `check` jobs each collapse their two-tool `run:` steps into a
single `just` call; the `build` job calls `just build`. `AGENTS.md` and `README.md` point at `just
<recipe>` instead of raw `pnpm` invocations. `backlog/config.yml`'s `definition_of_done` names `just`
recipes instead of raw `pnpm` commands. `scripts/cloud-environment-setup.sh` is untouched — it is a
cloud-provisioner bootstrap script invoked by an external service before `just`/the toolchain exist,
not a dev/CI task script, and is explicitly out of scope for absorption.

## 2. The complete justfile

Drop this at the repo root as `justfile`. `PUBLIC_ENTRA_CLIENT_ID` is required for `typecheck` and
`build` — `$env/static/public` fails to resolve without it (see the comment already in
`.github/workflows/ci.yml`). The `env()` default below mirrors the exact inert placeholder value CI
sets at workflow level, so `just check` and `just build` work out of the box on a fresh checkout with
no `.env` file needed.

```just
set shell := ["bash", "-euo", "pipefail", "-c"]

# Placeholder Entra client ID — $env/static/public needs a value to resolve at
# type-check/build time. The real value is per-deployment Cloudflare Pages
# config; this app is client-side only with no server secrets. Override with a
# real value via `.env` (loaded by Vite) for `just dev`.
export PUBLIC_ENTRA_CLIENT_ID := env('PUBLIC_ENTRA_CLIENT_ID', '00000000-0000-0000-0000-000000000000')

# show the task surface
default:
    @just --list

# install dependencies from the committed lockfile (idempotent)
setup:
    pnpm install --frozen-lockfile
    pnpm exec svelte-kit sync

# format source in place (prettier)
[group('check')]
fmt:
    pnpm exec prettier --write .

# verify formatting — prettier + just's own formatter
[group('check')]
[no-exit-message]
fmt-check:
    pnpm exec prettier --check .
    just --fmt --check

# static analysis (eslint)
[group('check')]
[no-exit-message]
lint:
    pnpm exec eslint .

# type-check (svelte-check via svelte-kit sync)
[group('check')]
[no-exit-message]
typecheck:
    pnpm exec svelte-kit sync
    pnpm exec svelte-check --tsconfig ./tsconfig.json

# no test suite in this repo (client-side app, no test framework configured)
[group('check')]
test filter="":
    @echo "no tests in this repo"

# the full PR gate — exactly what CI enforces
[group('check')]
check: fmt-check lint typecheck test

# production build to .svelte-kit/cloudflare
[group('build')]
[no-exit-message]
build:
    pnpm exec vite build

# remove build output and caches (reproducible via setup + build)
[group('build')]
[confirm('remove .svelte-kit, build/, .wrangler/ and node_modules? [y/N]')]
clean:
    rm -rf .svelte-kit build .wrangler node_modules

# start the Vite dev server (long-running)
[group('dev')]
dev:
    pnpm exec vite dev
```

Notes on choices:

- `pnpm exec <tool>` is used directly rather than `pnpm run <script>` (i.e. `pnpm lint`) so `just
  --show <recipe>` tells an agent the real underlying command instead of an indirection through
  `package.json#scripts`. This is a style choice, not a functional necessity — if a future edit to
  this repo's `package.json` scripts drifts from this, keep the justfile as the source of truth and
  update `package.json#scripts` to match, not the reverse.
- `typecheck` runs `svelte-kit sync` before `svelte-check`, matching `pnpm check`'s existing
  `"check": "svelte-kit sync && svelte-check --tsconfig ./tsconfig.json"` — `svelte-kit sync`
  regenerates `.svelte-kit/tsconfig.json` and the `$env/static/public` types tsconfig.json extends.
  Do not drop it or `typecheck` fails with the exact error the CI comment warns about.
- `test filter=""` takes the standard's optional `filter` param even though it is unused, so the
  signature matches every other repo in the fleet. The parameter is accepted and ignored.
- No `typecheck` alias omission — this repo has real type-checking (`svelte-check`), so `typecheck`
  is mandatory-in-practice here even though it's in the fleet's optional list, and it MUST be a
  dependency of `check` (CI's `check` job is exactly `pnpm check`, i.e. `svelte-check`).
- No `gen`/`gen-check`/`ci`/`docs`/`release`/`deps-update`/`plan`/`apply` recipes — none apply. `docs/`
  and `docs.toml` are fed to an external hub (`m7kni-net-site`) that generates the actual site; this
  repo does no local docs build. Do not invent one.
- `clean` is new — nothing in CI or docs currently does this, but it is in the fleet's optional
  vocabulary and this repo's build artifacts (`.svelte-kit`, `build`, `.wrangler`) are exactly the
  kind of thing it exists for. `[confirm]` because it removes `node_modules` (expensive to
  regenerate, not just disk-cheap junk).

## 3. Makefile disposition

None. `find . -iname Makefile -o -iname GNUmakefile` (excluding `vendor/`, `node_modules/`,
`third_party/`, `.venv/`) returns nothing. No `git rm` needed for this section.

## 4. Script disposition

| Script | Disposition | Recipe / reason |
|---|---|---|
| `scripts/cloud-environment-setup.sh` | **KEEP** | Invoked by an external cloud service (Codex Cloud / Claude Code cloud environment bootstrap), not by a developer or CI — per §6 of the standard, "scripts invoked by something other than a developer or CI" stay a file. It also has real control flow (a `find_repo_root` function, an `install_pnpm` function with an `if command -v corepack` branch) that does not inline into a `just` recipe line. It runs *before* any toolchain exists (installs pnpm itself), so it cannot depend on `just` being present either. No recipe wraps it — it is configured directly as the cloud service's setup command (`bash scripts/cloud-environment-setup.sh`), per its own header comment. Do not touch this file, do not add a `just` recipe for it, do not delete it. |

That is the only script in the repo (`git ls-files | grep -E '\.(sh|bash|zsh|ps1)$'` returns exactly
this one file). No Python/Go/other-language dev-task scripts exist (`scripts/` has this one file
only).

## 5. CI changes

### `.github/workflows/ci.yml`

Three jobs collapse their tool-invocation steps to `just`. Everything else (job names,
`concurrency:`, `permissions:`, the workflow-level `env.PUBLIC_ENTRA_CLIENT_ID`, `ci-success` and its
`needs: [lint, check, build]`, the three pinned `uses:` steps per job) stays exactly as-is.

Insert a `setup-just` step after the existing `actions/setup-node` step (order doesn't matter as long
as it's before the first `just` call) in all three jobs — `lint`, `check`, `build`.

**`lint` job** — replace the `eslint` and `prettier` steps:

```yaml
      - name: eslint
        run: pnpm lint

      - name: prettier
        run: pnpm exec prettier --check .
```

with:

```yaml
      - uses: extractions/setup-just@53165ef7e734c5c07cb06b3c8e7b647c5aa16db3 # v4.0.0
        with:
          just-version: '1.58.0'

      - name: Install
        run: pnpm install --frozen-lockfile

      - name: lint + fmt-check
        run: just lint fmt-check
```

(`just lint fmt-check` runs both recipes in one invocation — order within that command is
irrelevant since neither mutates or depends on the other. `pnpm install` still runs first, unchanged.)

**`check` job** — replace the `svelte-check` step:

```yaml
      - name: svelte-check
        run: pnpm check
```

with:

```yaml
      - uses: extractions/setup-just@53165ef7e734c5c07cb06b3c8e7b647c5aa16db3 # v4.0.0
        with:
          just-version: '1.58.0'

      - name: svelte-check
        run: just typecheck
```

Keep this job's comment above the step (the one explaining why `check` — not `build` — is the real
type-check gate, and the TypeScript pin in `renovate.json`) — move it to sit above `just typecheck`.

**`build` job** — replace the `Build` step:

```yaml
      - name: Build
        run: pnpm build
```

with:

```yaml
      - uses: extractions/setup-just@53165ef7e734c5c07cb06b3c8e7b647c5aa16db3 # v4.0.0
        with:
          just-version: '1.58.0'

      - name: Build
        run: just build
```

Keep the `PUBLIC_ENTRA_CLIENT_ID` comment above this step — it still applies (`just build`'s recipe
body has no env logic of its own; it inherits the workflow-level `env:` exactly as `pnpm build` did).

Do **not** add a `just check` call replacing the three separate jobs — CI's parallel `lint`/`check`/
`build` job split is deliberate (separate required-check names feeding `ci-success`'s `needs:` list)
and the standard does not require collapsing job structure, only step bodies. `just check` remains
the thing a developer runs locally before pushing; CI keeps running the equivalent three recipes
across three jobs so failures are attributed per-job in the GitHub UI.

### `.github/workflows/notify-new-issue.yml` and `.github/workflows/trigger-docs-sync.yml`

**No changes.** Neither runs build/test/lint/format/generate logic — `notify-new-issue.yml` is a
single `gh issue edit` call, `trigger-docs-sync.yml` mints an OpenBao broker token and calls
`peter-evans/repository-dispatch`. Both are GitHub-native/orchestration workflows out of scope per §8
of the standard.

## 6. Docs and agent-contract changes

### `AGENTS.md` (also read as `CLAUDE.md` — do not edit `CLAUDE.md`, it is just `@AGENTS.md`)

Replace the existing `## Commands` section:

```markdown
## Commands

- `pnpm install` — install dependencies (pnpm is enforced via `.npmrc`)
- `pnpm dev` — start Vite dev server
- `pnpm build` — production build (outputs to `.svelte-kit/cloudflare`)
- `pnpm check` — TypeScript type-checking with svelte-check
- `pnpm lint` — ESLint (flat config, strict TS rules)
- `pnpm format` — Prettier auto-format

No test framework is configured.
```

with the standard's §9 block, adapted:

```markdown
## Task interface

This repo's task surface is a `justfile`. Discover it, don't guess it:

    just --list                        # human-readable
    just --dump --dump-format json     # machine-readable
    just --show <recipe>               # what a recipe actually runs

- `just check` is the full gate and is exactly what CI enforces (across its `lint`, `check` and
  `build` jobs). It must pass before you commit.
- Prefer `just <recipe>` over the underlying tool. If you are typing `pnpm exec eslint` or
  `svelte-check`, you want `just lint` or `just typecheck`.
- Run `just` with stdin from /dev/null. Recipes marked `[confirm]` are destructive — stop and ask
  before running one; never pass `--yes` or `JUST_YES=1`.
- If a task you need does not exist, add a recipe with a `#` doc comment and a `[group(...)]` rather
  than running a bare command.
- No test framework is configured in this repo — `just test` is a documented no-op.
```

Also update the `Quality Checks` section (currently: *"Always run the full build and type-check
(`pnpm build`) after completing any code changes... Run `pnpm lint` to catch these..."*) — replace the
two `pnpm` invocations with `just build` and `just lint` respectively. Keep the surrounding prose
unchanged.

### `README.md`

Replace:

```markdown
Other commands:

```sh
pnpm build    # production build to .svelte-kit/cloudflare
pnpm check    # TypeScript / svelte-check
pnpm lint     # ESLint
pnpm format   # Prettier
```
```

with:

```markdown
Other commands:

```sh
just build      # production build to .svelte-kit/cloudflare
just typecheck  # TypeScript / svelte-check
just lint       # ESLint
just fmt        # Prettier (in place)
just check      # the full gate — everything CI enforces
```

Run `just --list` for the complete task surface.
```

Leave the `pnpm install` / `pnpm dev` lines in the "Running it locally" code block above this section
alone — `just setup` and `just dev` are equivalent, but the quick-start block stays in raw `pnpm` form
intentionally since it's a first-contact clone-and-run snippet for a reader who hasn't discovered
`just` yet. (This is a narrow, deliberate exception — do not extend it to the "Other commands" list
above.)

## 7. `backlog/config.yml`

`backlog/config.yml` is the one file this migration edits by hand (per this repo's own AGENTS.md: it
is the sole hand-edit exemption because list-valued keys can't go through `backlog config set`).
Current `definition_of_done`:

```yaml
definition_of_done: ["pnpm lint passes with zero errors", "PUBLIC_ENTRA_CLIENT_ID=<any-guid> pnpm check passes with zero errors", "PUBLIC_ENTRA_CLIENT_ID=<any-guid> pnpm build passes with zero errors"]
```

Replace with:

```yaml
definition_of_done: ["just lint passes with zero errors", "just typecheck passes with zero errors", "just build passes with zero errors"]
```

`PUBLIC_ENTRA_CLIENT_ID=<any-guid>` is dropped because the justfile's `env()` default already
supplies the placeholder value — a bare `just typecheck` / `just build` now works without the caller
setting it, matching what CI actually does (workflow-level `env:`, not a per-invocation prefix).

## 8. Order of work

1. Add the justfile from §2 at the repo root. Run `just --fmt --check` (fix formatting if it fails —
   apply `just --fmt` once), then `just setup && just check && just build` locally. Confirm `just
   check`'s four sub-recipes match what CI's `lint`/`check` jobs currently pass, and `just build`
   produces the same `.svelte-kit/cloudflare` output `pnpm build` did.
2. Edit `.github/workflows/ci.yml` per §5. Push and confirm all three jobs and `ci-success` are green
   on the resulting commit/PR — this is the only step in this migration that needs a live CI run to
   verify.
3. Edit `AGENTS.md` and `README.md` per §6.
4. Hand-edit `backlog/config.yml`'s `definition_of_done` per §7.
5. Nothing to delete — no Makefile exists, and the one script is KEEP. Skip the deletion step this
   migration would otherwise end on.

Steps 1–4 can commit together once step 1 is locally verified; step 2's CI edit is the only one that
needs a real CI run before being trusted.

## 9. Traps specific to this repo

- **`PUBLIC_ENTRA_CLIENT_ID` is load-bearing for `typecheck` and `build`, not just `dev`.** The
  existing CI comment in `ci.yml` explains why: `svelte-kit sync` generates `$env/static/public`'s
  types from whatever env var is present at sync time, and `svelte-check`/Vite fail outright without
  it. The justfile's `env()` default reproduces this — don't strip it thinking it's dev-only.
- **`typecheck` must re-run `svelte-kit sync` first**, matching `package.json`'s existing `"check"`
  script (`svelte-kit sync && svelte-check ...`). Skipping the sync step reintroduces exactly the
  failure mode the CI comment on the `check` job describes.
- **No `packageManager` field in `package.json` and no `engines` block** — pnpm version is asserted
  only in CI (`pnpm/action-setup` with `version: 11`) and in `scripts/cloud-environment-setup.sh`
  (`PNPM_VERSION='10.28.1'`, installed via corepack). These two already disagree with each other and
  that's a pre-existing inconsistency, not something this migration should silently "fix" by picking
  one — `just setup` deliberately does not pin or install a pnpm version itself, it assumes pnpm is
  already on PATH (as `.npmrc`'s `engine-strict=true` already assumes). Flag this mismatch to Rob
  rather than resolving it inside this task.
- **`build/` vs `.svelte-kit/cloudflare`**: `eslint.config.js`'s ignore list includes `build/`, but the
  actual Vite/adapter-cloudflare output directory is `.svelte-kit/cloudflare` (per `AGENTS.md`'s own
  Tech Stack section and this task's §2 comment). `clean`'s `rm -rf` list matches the eslint ignore
  list (`.svelte-kit build .wrangler`) for consistency with what's already treated as build output
  fleet-wide in this repo — do not narrow it to only `.svelte-kit/cloudflare` without checking whether
  `build/` is produced by some other path (e.g. a Cloudflare Pages preview build) first.
- **`docs/` and `docs.toml` are not a local build** — resist the urge to add a `docs`/`docs-serve`
  recipe. The actual site generation happens in the external `m7kni-net-site` hub, triggered by
  `trigger-docs-sync.yml`'s `repository_dispatch`. This repo only owns the content and `docs.toml`
  config fragment.
- **`node_modules`, `.svelte-kit`, `.wrangler` are gitignored** (verified in `.gitignore`) — `clean`
  removing them is safe and matches what `setup`/`build` can fully reproduce.

## 10. Out of scope

- `scripts/cloud-environment-setup.sh` — KEEP, untouched, no recipe (§4).
- `.github/workflows/notify-new-issue.yml` — GitHub-native issue-triage automation, no build/test/lint
  logic, untouched.
- `.github/workflows/trigger-docs-sync.yml` — GitHub-native dispatch-to-hub workflow (OpenBao broker
  token mint + `repository_dispatch`), untouched. Do not fold into `just` per §8 of the standard.
- `docs/` content and `docs.toml` — owned by this repo, consumed by an external hub; no local build
  step exists or should be added.
- `todos.txt` / `todos-completed.txt` — explicitly documented in `AGENTS.md` as historical, not a task
  queue; irrelevant to this migration.
- `archive/` — historical issue-dump data, irrelevant to this migration.
- `backlog/config.yml`'s other keys (`statuses`, `task_prefix`, `remote_operations`, etc.) — only
  `definition_of_done` changes.
- Any CodeQL/zizmor/actionlint/scorecard/dependency-review/container-publish/release-please workflow
  — none exist in this repo's `.github/workflows/` (only the three listed in §5/§10), so there is
  nothing of that kind to preserve, but if any are added later they stay GitHub-native per the
  standard.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 Top-level justfile exists with all seven mandatory recipes (default, setup, fmt, fmt-check, lint, test, check) plus typecheck, build, dev, clean
- [ ] #2 just check passes locally and is exactly what CI's lint/check/build jobs enforce (fmt-check, lint, typecheck, test)
- [ ] #3 just --fmt --check passes
- [ ] #4 just --list shows a doc comment and correct group for every public recipe
- [ ] #5 No Makefile exists in the repo (none did before this task; confirm none was introduced)
- [ ] #6 scripts/cloud-environment-setup.sh remains untouched and unabsorbed, per its KEEP classification
- [ ] #7 .github/workflows/ci.yml's lint, check and build jobs call just recipes via a pinned extractions/setup-just step, and ci-success still gates on needs: [lint, check, build] unchanged
- [ ] #8 AGENTS.md and README.md no longer tell a developer to run pnpm lint/pnpm check/pnpm build directly outside the quick-start clone snippet; they reference just recipes and AGENTS.md carries the Task interface section
- [ ] #9 backlog/config.yml's definition_of_done names just lint, just typecheck and just build instead of raw pnpm invocations
<!-- AC:END -->

## Definition of Done
<!-- DOD:BEGIN -->
- [ ] #1 pnpm lint passes with zero errors
- [ ] #2 PUBLIC_ENTRA_CLIENT_ID=<any-guid> pnpm check passes with zero errors
- [ ] #3 PUBLIC_ENTRA_CLIENT_ID=<any-guid> pnpm build passes with zero errors
<!-- DOD:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Verify the current task surface, CI workflow, documentation, scripts, hooks, and repository cleanliness.
2. Add the prescribed top-level justfile and validate its format, metadata, and local task gate.
3. Convert only the CI build/lint/typecheck command bodies to pinned just invocations while preserving job topology.
4. Update the agent contract, README command list, and definition of done; search for stale removed command references.
5. Run the prescribed local gates, review the final diff, commit and push named paths, verify CI at the final SHA, then finalize ASM-0002 with evidence.
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Implemented the requested justfile, CI invocation migration, task-interface documentation, definition-of-done update, and Renovate version annotation for the existing shared broker-token composite action.

Found and repaired a pre-existing formatter-boundary defect: baseline CI run 33248499007 failed because `prettier --check .` scanned 10 tool-managed Backlog records and historical archive files. `.prettierignore` now excludes only `backlog/docs/`, `backlog/tasks/`, and `archive/`; source, workflows, docs, and `backlog/config.yml` remain formatted and checked.

Local evidence: `just --fmt --check`, `just --dump --dump-format json`, `just setup`, `just check`, and `just build` pass; `svelte-check` reported 0 errors and 0 warnings; `actionlint` passed for the changed workflows. CodeRabbit is intentionally skipped because this change is declarative task/configuration/documentation wiring with no application branching.
<!-- SECTION:NOTES:END -->

## Comments

<!-- COMMENTS:BEGIN -->
author: campaign-ordering
created: 2026-08-29 09:18
---
## Fleet ordering — WAVE 2. Starts after the Wave 0 pilot (`sf2loki` / SFL-0073) and the Wave 1 hubs land.

Within Wave 2 the order is free — these repos do not depend on each other. Batching by language is worthwhile so one lane reuses its Makefile-to-recipe mapping across similar repos.

Do not start before the pilot reports. The standard may be amended off the back of it, and picking this up early risks coding against a superseded seam.

**Provisioning `just` in CI.** Which mechanism depends on the runner, and the two must not be mixed:

| Runner | Mechanism |
| --- | --- |
| `arc-arm64` (m7kni self-hosted) | `just` is **baked into the runner image** by `m7kni/ci-tools` (`runner-image/Dockerfile`, `ARG JUST_VERSION`). Do **not** add `extractions/setup-just`, and delete the step if this repo already has one — it installs a second `just` earlier on `PATH` and turns the image pin into a lie. |
| GitHub-hosted (all `rknightion` repos) | `extractions/setup-just`, SHA-pinned, with an explicit `just-version:`. |

Both sides currently sit on **1.58.0** and are Renovate-managed. `ci-tools`' `Tool version drift` workflow fails if the Dockerfile `ARG` and the published image ever disagree, and lists any repo still carrying a second pin.

**While you are in the workflow files, check the hub pin.** On 2026-08-29 Renovate was unfrozen for `rknightion/.github` in `m7kni/renovate-config` — it had been `enabled: false` on the mistaken belief that callers tracked `@main`, which froze the fleet across 19 different hub SHAs (v1.3.1 June → v1.9.7 August) so that no hub fix ever propagated. Bumps now arrive as one grouped, CI-gated, automerged PR per repo. **A `uses:` whose comment is not a real `# vX.Y.Z` still cannot be bumped** (it resolves to a digest-only update, which the fleet rules disable) — if you find one, repair the comment as part of this task.
---

author: campaign-ordering
created: 2026-08-29 10:42
---
## Standard amendment — `ci` is the sanctioned superset of `check` (RATIFIED)

This supersedes the frozen wording *"`check` is the complete local gate and reproduces every CI job that can run off a GitHub runner"*, which several lanes could not honour without making the pre-commit gate depend on a Docker daemon.

**The definitions now are:**

- **`check`** — everything that runs with **only the language toolchain installed**. This is the pre-commit gate. A leg that runs on a bare toolchain belongs here *however long it takes*.
- **`ci`** — `check` plus the legs CI gates that need a **Docker daemon, a service container, or cross-compilation**, and nothing else. Written as `ci: check <heavy legs>`.

**Every leg you put in `ci` must carry a comment naming which of those three it needs.** That comment is the guard: without it `ci` becomes the bin for anything slow or awkward, `check` quietly stops meaning much, and the fleet is back to a per-repo gate.

Eleven of the 42 lanes arrived at this shape independently before it was ratified, which is why it won.

**If this repo has no such legs, it has no `ci` recipe at all** and `check` is the whole gate. Do not add an empty one.
---
<!-- COMMENTS:END -->
