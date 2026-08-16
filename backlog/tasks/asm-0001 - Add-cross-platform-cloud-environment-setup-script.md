---
id: ASM-0001
title: Add cross-platform cloud environment setup script
status: Done
assignee:
  - '@codex'
created_date: '2026-08-16 10:33'
updated_date: '2026-08-16 10:49'
labels: []
dependencies: []
references:
  - 'https://learn.chatgpt.com/docs/environments/cloud-environment#manual-setup'
  - 'https://code.claude.com/docs/en/cloud-environments#setup-scripts'
modified_files:
  - scripts/cloud-environment-setup.sh
type: chore
ordinal: 1000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Provide a committed, idempotent setup script that can be pasted or invoked from Codex Cloud and Claude Code cloud environment configuration. It must provision this SvelteKit project and Backlog.md so future agents can follow the repository task workflow and run all required validation.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 The script installs the pinned Backlog.md CLI and verifies the backlog command is available
- [x] #2 The script installs project dependencies reproducibly with pnpm and prepares the SvelteKit workspace
- [x] #3 The script works from Codex Cloud and Claude Code cloud setup contexts without relying on persistent shell exports or a fixed checkout path
- [x] #4 Repository lint and production build pass after setup
<!-- AC:END -->

## Definition of Done
<!-- DOD:BEGIN -->
- [x] #1 pnpm lint passes with zero errors
- [x] #2 PUBLIC_ENTRA_CLIENT_ID=<any-guid> pnpm check passes with zero errors
- [x] #3 PUBLIC_ENTRA_CLIENT_ID=<any-guid> pnpm build passes with zero errors
<!-- DOD:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Add a repository-root-aware Bash setup script with pinned pnpm and Backlog.md versions.
2. Install dependencies from the lockfile and verify the task-tracking and SvelteKit toolchain.
3. Exercise idempotency, lint, type-check, and production build; then finalize the Backlog task.

4. Rename the script to scripts/cloud-environment-setup.sh, add a prominent local-agent prohibition at the top, and rerun the full validation suite.
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Added the cross-platform setup script with pinned pnpm 10.28.1 and Backlog.md 1.50.1, repository discovery, frozen dependency installation, and toolchain verification.

Validated direct invocation from outside the checkout; the script found the repository and completed successfully. pnpm lint, pnpm check, and pnpm build all passed.

Renamed the entry point to scripts/cloud-environment-setup.sh and added a top-of-file instruction prohibiting local agents from executing it.
<!-- SECTION:NOTES:END -->

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
Added an idempotent Codex Cloud and Claude Code cloud setup script that pins pnpm and Backlog.md, installs the lockfile, discovers the checkout from any working directory, and verifies the SvelteKit toolchain. Direct invocation from /tmp, lint, svelte-check, and the Cloudflare production build all passed.

Follow-up review changes renamed the script to scripts/cloud-environment-setup.sh and added an explicit cloud-only warning for local agents. Bash syntax, lint, svelte-check, and the production build passed without executing the cloud-only setup script locally.
<!-- SECTION:FINAL_SUMMARY:END -->
