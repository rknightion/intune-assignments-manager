---
id: ASM-0003
title: Restore Prettier compliance of the loop contract
status: To Do
assignee: []
created_date: '2026-11-06T02:13:00Z'
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
- [ ] #1 The existing Prettier check accepts the loop contract without a formatter exclusion or weakened configuration.
- [ ] #2 The loop contract retains its current behavioral requirements.
- [ ] #3 Both just check and just build complete successfully, or independent remaining failures are recorded separately.
<!-- AC:END -->

## Definition of Done
<!-- DOD:BEGIN -->
- [ ] #1 just lint passes with zero errors
- [ ] #2 just typecheck passes with zero errors
- [ ] #3 just build passes with zero errors
<!-- DOD:END -->
