---
id: ASM-0003
title: Restore Prettier compliance of the loop contract
status: Done
assignee: []
created_date: '2026-11-06T02:13:00Z'
updated_date: '2026-11-06T02:28:00Z'
labels: []
dependencies: []
references:
  - >-
    https://github.com/rknightion/intune-assignments-manager/blob/35c08b7c25ff65625ded734c2ed787f4f83d5e50/LOOP.md
priority: medium
type: chore
ordinal: 3000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
The declared just check gate stops in pnpm exec prettier --check . and reports LOOP.md as unformatted. Observed during a configuration-only change based on 35c08b7c25ff65625ded734c2ed787f4f83d5e50. The unchanged LOOP.md bytes match that baseline commit; no application or protocol edits were part of the candidate. The required just build command was not reached because just check failed. Restore the formatter contract without weakening the gate or changing protocol meaning.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 The existing Prettier check accepts the loop contract without a formatter exclusion or weakened configuration.
- [x] #2 The loop contract retains its current behavioral requirements.
- [x] #3 Both just check and just build complete successfully, or independent remaining failures are recorded separately.
<!-- AC:END -->

## Definition of Done
<!-- DOD:BEGIN -->
- [x] #1 just lint passes with zero errors
- [x] #2 just typecheck passes with zero errors
- [x] #3 just build passes with zero errors
<!-- DOD:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
Use the repository-pinned Prettier on LOOP.md only; preserve its preimage and verify protocol text unchanged apart from formatting. Run the complete required just check and just build on the combined configuration-retirement candidate.
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Prettier added exactly one blank line after the loop title. All non-whitespace tokens remain identical; no protocol or formatter configuration changed. Full just check (formatting, ESLint, Svelte typecheck, declared test recipe) and just build passed with Node 24.22.2 and pnpm 11.28.11. No application changes were needed.
<!-- SECTION:NOTES:END -->

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
Restored the existing loop-contract formatting requirement with a single blank line. Both declared gates pass using the CI Node major and pnpm major; protocol text and application code are unchanged.
<!-- SECTION:FINAL_SUMMARY:END -->
