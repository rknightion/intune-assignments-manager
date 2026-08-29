# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Intune Assignments Manager — a SvelteKit web app for bulk-managing Microsoft Intune app and configuration profile assignments via the Microsoft Graph API. Deployed to Cloudflare Pages (client-side only, no server backend). All auth and API calls happen in the browser.

## Quality Checks

Always run the full build and type-check (`just build`) after completing any code changes. Do not consider a task done until the build passes cleanly with zero errors.

After editing files, check for duplicate imports and stale references from the previous code. Run `just lint` to catch these before proceeding.

## Svelte 5 Conventions

When working in Svelte 5 files (.svelte, .svelte.ts): use `SvelteMap` and `SvelteSet` instead of native `Map`/`Set`, use `const` (not `let`) for `$derived` runes, avoid deprecated `svelte:component` syntax, and ensure all `{#each}` blocks have unique keys.

## Debugging Guidelines

Before changing code to fix a bug, first investigate the root cause thoroughly (check git history, trace data flow, examine API responses). Do not make speculative code fixes before understanding why the issue occurs.

## Architecture / API Notes

This project uses TypeScript (primary), SvelteKit, and targets the Microsoft Graph API (use /beta prefix for Intune endpoints). When interacting with Graph API, be aware that many endpoints are deprecated or behave unexpectedly — verify endpoint availability before building features around them.

## Workflow Preferences

Keep the planning phase brief and present the plan for approval before exploring the entire codebase. Do not spend excessive time on exploration before producing actionable output.

`todos.txt` and `todos-completed.txt` are the original build plan and every phase in them is shipped. They are **history, not a queue** — do not mine them for work. The open queue is `backlog task list --plain`.

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

## Tech Stack

- **SvelteKit 2** with **Svelte 5** (runes: `$state`, `$derived`, `$effect`, `$props`)
- **TypeScript** — strict mode, `noUnusedLocals`/`noUnusedParameters` enforced
- **Tailwind CSS 4** — OKLCH color tokens defined in `src/app.css` via `@theme`
- **@azure/msal-browser** — OAuth2 PKCE auth against Microsoft Entra ID
- **Zod** — runtime validation of Graph API responses
- **lucide-svelte** — icon library
- **Cloudflare Pages** — no Node.js built-ins, Web APIs only

## Architecture

### Authentication

MSAL.js handles OAuth2 popup flow entirely client-side. Auth state lives in `src/lib/stores/auth.svelte.ts` using Svelte runes. MSAL is lazy-imported on first auth action (SSR-safe with `browser` guard). Single env var: `PUBLIC_ENTRA_CLIENT_ID`.

Incremental consent is managed via `src/lib/auth/permission-check.ts` and `src/lib/stores/permissions.svelte.ts` — features that need extra Graph scopes trigger a consent popup before proceeding.

### Graph API Client (`src/lib/graph/client.ts`)

Factory function `createGraphClient(getAccessToken)` provides three methods:

- `request<T>()` — single request with retry (max 3, exponential backoff on 429)
- `fetchAll<T>()` — paginated fetch following `@odata.nextLink`
- `batch()` — batch endpoint, auto-chunks at 20 requests per batch

Custom error hierarchy: `GraphApiError` → `RateLimitError` (429), `AuthenticationError` (401), `PermissionError` (403). Errors are converted to user-friendly messages via `toFriendlyMessage()` in `src/lib/graph/errors.ts`.

Additional domain-specific Graph modules: `compliance.ts`, `security.ts`, `devices.ts`, `status.ts`, `filters.ts`, `merge.ts`.

### Bulk Assignment Flow (`src/lib/graph/execute.ts`)

Three-phase execution:

1. **Fetch** — batch GET current assignments for all selected items
2. **Merge** — combine new assignments with existing, detect conflicts (same group/target with different settings)
3. **Apply** — batch POST merged assignment lists, retry 5xx errors

The Graph `assign` endpoint **replaces all assignments**, so existing assignments must always be fetched and merged first.

### State Management

Pure Svelte runes — no external state library. Stores in `src/lib/stores/` export reactive state with `$state`/`$derived`. Caches (dashboard, groups, filters) use localStorage for persistence.

### Routing

SvelteKit file-based routing:

- `/` — Dashboard
- `/apps`, `/apps/[id]` — Browse and detail for mobile apps
- `/profiles`, `/profiles/[id]` — Browse and detail for config profiles
- `/compliance`, `/compliance/[id]` — Compliance policies
- `/security`, `/security/[id]` — Endpoint security policies
- `/devices`, `/devices/[id]` — Managed devices
- `/assign` — 5-step bulk assignment wizard
- `/audit` — Intune audit log
- `/status` — App install status reports
- `/settings` — App settings

### Type System

Three-tier validation: TypeScript interfaces → Zod schemas → business logic types. Core files in `src/lib/types/`: `graph.ts`, `schemas.ts`, `wizard.ts`. Domain-specific pairs: `compliance.ts`/`compliance-schemas.ts`, `device.ts`/`device-schemas.ts`, `security.ts`, `status.ts`/`status-schemas.ts`.

## Code Style

- **Prettier**: tabs, single quotes, no trailing commas, 100 char width
- **Imports**: use `$lib/` and `$app/` path aliases
- **Components**: PascalCase filenames, props via `$props()` destructuring
- **Svelte 5 snippets**: used for flexible content slots (e.g., `{#snippet actions()}`)
- **Graph API base**: `https://graph.microsoft.com/beta`

## Validation

Use the Claude Code Chrome MCP server to validate significant changes in a browser. Run `pnpm dev`, navigate to the URL from its output, and check that the feature works with no console errors. Not required after every change — use for new features or major modifications.

<!-- BACKLOG.MD GUIDELINES START -->
<!-- backlog.md-instructions-version: 1.50.1 -->

<CRITICAL_INSTRUCTION>

## Backlog.md Workflow

This project uses Backlog.md for task and project management.

**For every user request in this project, run `backlog instructions overview` before answering or taking action.**

Use the overview to decide whether to search, read, create, or update Backlog tasks.

Before task lifecycle actions, read the matching detailed guide:

- `backlog instructions task-creation` before creating or splitting tasks
- `backlog instructions task-execution` before planning, changing status or assignee, adding a plan or implementation notes, or implementing task work
- `backlog instructions task-finalization` before checking acceptance criteria, writing final summaries, or moving tasks to terminal statuses

Use `backlog <command> --help` before running unfamiliar commands. Help shows options, fields, and examples.

Do not edit Backlog task, draft, document, decision, or milestone markdown files directly. Use the `backlog` CLI so metadata, relationships, and history stay consistent.

</CRITICAL_INSTRUCTION>
<!-- BACKLOG.MD GUIDELINES END -->

## Task tracking

Rules this project adds on top of the block above. They sit outside the tool-managed markers so an upstream update leaves them alone.

**Read the docs before designing a wave.** `backlog doc list --plain` shows all four:

- **Agent fan-out protocol (canonical)** — the campaign model. Copied verbatim from its source; authoritative for this repo.
- **Wave operating model** — this project's own rules, defects, lane boundaries and exclusive resource.
- **Microsoft Graph endpoint findings (live-verified)** — which Intune endpoints actually respond. Read it before building on any endpoint; add to it rather than re-probing.
- **Closed GitHub issues: pre-Backlog history index** — the pre-2026-08-14 history, whose full record is `archive/issues-dump.json`.

**Never use `--notes` or `--plan` bare.** They _silently replace_ the whole section, destroying another session's writes with no warning and exit 0. Use `--append-notes` and `--append-plan`. This is an open upstream bug, not a misunderstanding, and a global `PreToolUse` hook in the agent config denies the bare forms rather than trusting anyone to remember.

**Never hand-edit task, draft, doc, decision or milestone markdown.** Section boundaries are HTML-comment markers; break one and the section is _silently dropped_ at exit 0 — still in the file, invisible to the CLI, until the next write destroys it for real. There is no repair command; `backlog doctor` only fixes duplicate task IDs. The guard hook denies these edits too. `backlog/config.yml` is the one exemption: list-valued keys cannot be set through `backlog config set`, so it is edited by hand.

**Finalize in one call**, so an interrupted agent cannot leave finished work looking unfinished:

```bash
backlog task edit ASM-0007 --check-ac 1 --check-ac 2 -s Done
```

**Never let two agents edit the same task.** The v1.50 fix covers the edit funnel but not reorder, draft saves, the TUI edit path, `doc update` or decision updates.

**`backlog/` is committed to a public repository.** Tasks, docs and decisions must never carry real account identifiers or personal data — no tenant ids, object ids, UPNs, email addresses, device names, group names, or values copied out of a live Intune tenant. Write the shape, not the instance: `<tenant-id>`, "the second device in the failed list". Aggregate counts, timings and structural findings are fine. Sweep before committing:

```bash
grep -rniE "@[a-z0-9-]+\.(com|net|io|onmicrosoft\.com)|[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}" backlog/ && echo "IDENTIFIERS FOUND"
```
