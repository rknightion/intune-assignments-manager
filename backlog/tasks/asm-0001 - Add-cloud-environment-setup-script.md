---
id: ASM-0001
title: Add cloud environment setup script
status: Done
assignee:
  - '@codex'
created_date: '2026-08-16 12:02'
updated_date: '2026-08-16 12:07'
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
Provide a repository-owned manual setup script for Codex Cloud Tasks and Claude Code cloud sessions so agents receive project dependencies, Backlog.md task tracking, and validation tooling.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 scripts/cloud-environment-setup.sh starts with guidance that non-cloud local agents must not execute it
- [x] #2 The setup is idempotent and installs the pinned Backlog.md CLI plus locked project dependencies
- [x] #3 The setup supports both Codex Cloud and Claude Code remote cloud environments
- [x] #4 The script verifies the task-tracking, lint, formatting, type-check, build, and pull-request tools agents need
- [x] #5 pnpm lint and pnpm build pass
<!-- AC:END -->

## Definition of Done
<!-- DOD:BEGIN -->
- [x] #1 pnpm lint passes with zero errors
- [x] #2 PUBLIC_ENTRA_CLIENT_ID=<any-guid> pnpm check passes with zero errors
- [x] #3 PUBLIC_ENTRA_CLIENT_ID=<any-guid> pnpm build passes with zero errors
<!-- DOD:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Pin cloud bootstrap tooling and resolve the repository root without relying on the caller working directory.

2. Install Backlog.md and locked pnpm dependencies idempotently, then verify all commands agents need for task tracking and project validation.

3. Validate shell syntax and behavior, run lint/build/check, finalize the Backlog task, commit, and open a pull request.
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Added an executable, idempotent Bash setup that pins pnpm 10.28.1 and Backlog.md 1.50.1, installs missing cloud utilities, installs the frozen lockfile, and verifies the repository toolchain. Validation passed with bash syntax checking, a repeated setup run, lint, svelte-check, and the production build.
<!-- SECTION:NOTES:END -->

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
Added the shared Codex/Claude cloud setup script with a local-agent warning, pinned task/package tooling, locked dependency installation, and tool verification. Verified idempotence, lint, type checking, and the Cloudflare production build.
<!-- SECTION:FINAL_SUMMARY:END -->
