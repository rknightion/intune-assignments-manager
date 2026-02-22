# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Intune Assignments Manager — a SvelteKit web app for bulk-managing Microsoft Intune app and configuration profile assignments via the Microsoft Graph API. Deployed to Cloudflare Pages (client-side only, no server backend). All auth and API calls happen in the browser.

## Commands

- `pnpm install` — install dependencies (pnpm is enforced via `.npmrc`)
- `pnpm dev` — start Vite dev server
- `pnpm build` — production build (outputs to `.svelte-kit/cloudflare`)
- `pnpm check` — TypeScript type-checking with svelte-check
- `pnpm lint` — ESLint (flat config, strict TS rules)
- `pnpm format` — Prettier auto-format

No test framework is configured.

## Tech Stack

- **SvelteKit 2** with **Svelte 5** (runes: `$state`, `$derived`, `$effect`, `$props`)
- **TypeScript** — strict mode, `noUnusedLocals`/`noUnusedParameters` enforced
- **Tailwind CSS 4** — OKLCH color tokens defined in `src/app.css` via `@theme`
- **@azure/msal-browser** — OAuth2 PKCE auth against Microsoft Entra ID
- **Zod** — runtime validation of Graph API responses
- **Cloudflare Pages** — no Node.js built-ins, Web APIs only

## Architecture

### Authentication

MSAL.js handles OAuth2 popup flow entirely client-side. Auth state lives in `src/lib/stores/auth.svelte.ts` using Svelte runes. MSAL is lazy-imported on first auth action (SSR-safe with `browser` guard). Single env var: `PUBLIC_ENTRA_CLIENT_ID`.

### Graph API Client (`src/lib/graph/client.ts`)

Factory function `createGraphClient(getAccessToken)` provides three methods:

- `request<T>()` — single request with retry (max 3, exponential backoff on 429)
- `fetchAll<T>()` — paginated fetch following `@odata.nextLink`
- `batch()` — batch endpoint, auto-chunks at 20 requests per batch

Custom error hierarchy: `GraphApiError` → `RateLimitError` (429), `AuthenticationError` (401), `PermissionError` (403). Errors are converted to user-friendly messages via `toFriendlyMessage()` in `src/lib/graph/errors.ts`.

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
- `/assign` — 5-step bulk assignment wizard
- `/audit` — Intune audit log

### Type System

Three-tier validation: TypeScript interfaces (`src/lib/types/graph.ts`) → Zod schemas (`src/lib/types/schemas.ts`) → business logic types (`src/lib/types/wizard.ts`).

## Code Style

- **Prettier**: tabs, single quotes, no trailing commas, 100 char width
- **Imports**: use `$lib/` and `$app/` path aliases
- **Components**: PascalCase filenames, props via `$props()` destructuring
- **Svelte 5 snippets**: used for flexible content slots (e.g., `{#snippet actions()}`)
- **Graph API base**: `https://graph.microsoft.com/beta`

## Validation
You can use claude code chrome MCP server to validate changes and implementations work. You do not need to do this after every change but after new or significant features/changes are introduced to validate they work. You should run pnpm dev and then launch the browser to the right URL provided by pnpm dev output and validate the changes work and no errors exist in the browser console or are returned to the node console