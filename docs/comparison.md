---
title: When to Use This
description: When Intune Assignments Manager fits versus the Intune admin center or hand-written Microsoft Graph PowerShell scripts.
tags:
  - comparison
---

# When to Use This

There is more than one way to manage Intune app and configuration profile assignments. This
page states what this tool does and where it fits against the two realistic alternatives --
the Intune admin center itself, and hand-written Microsoft Graph PowerShell. It describes
this project, not the internals of either alternative, and does not claim either one is
worse.

## What this tool is

A browser-based, client-side wizard for **bulk** assignment changes: select any number of
apps and configuration profiles, pick target groups (plus `allDevices`/`allUsers` and
exclusions), set an intent and optional filter, review a computed diff, and apply. It always
fetches current assignments first and merges your changes in, because the underlying Graph
`assign` endpoint replaces an item's whole assignment list on every write -- see
[Architecture](development/architecture.md#bulk-assignment-execution-flow). It also gives you
CSV export/import for repeatable or offline-prepared changes ([CSV Import &
Export](csv.md)), a filtered audit log view ([Audit Log](audit.md)), and a Reports-API-backed
status page for install/deployment failures ([Deployment Status](status.md)).

It has no backend: every Graph call runs from your browser as the signed-in user, with
delegated permissions -- see [Security](security.md).

## When to use it

**Applying the same assignment to many apps or profiles at once.** Rolling out an app to
several regional groups, or standardising intent across a set of apps, is one wizard run
instead of one edit per item.

**You want a review step before a tenant-wide write goes out.** The wizard computes a diff
and flags conflicts (same group, different intent or filter) before anything is applied --
see [Bulk Assignment Wizard](assign/index.md).

**You need a repeatable or auditable record of an assignment change.** CSV export gives you
a file you can diff, store, or re-import later -- useful for cloning assignments or as a
rollback point before a bulk change (see [CSV - Common Workflows](csv.md#common-workflows)).

**You want assignment auditing and deployment-failure visibility without building tooling
yourself.** The Audit Log and Deployment Status pages wrap Intune's audit events and the
Reports API in a filtered, browsable view.

## When not to use it

**A single one-off change to one app or profile.** The wizard's five steps (select items,
select groups, configure, review, results) are built for scale. Editing one app's assignment
directly wherever you already manage that app is less overhead.

**Different intents for different apps in the same operation.** The wizard applies **one**
intent to all selected items and groups in a run -- see the [FAQ](faq.md#bulk-assignment). If
your change needs, say, `required` for one app and `available` for another in the same
batch, that needs either separate wizard runs or a script.

**Removing assignments.** The wizard adds and updates assignments; it does not remove
existing ones -- see [Bulk Assignment Wizard - Not ideal for](assign/index.md#when-to-use-bulk-assignment).

**Scripted, unattended, or CI-driven changes.** This is an interactive browser tool signed in
as a user -- see [Security - Application versus delegated permissions](security.md#application-versus-delegated-permissions).
There is no headless mode and no service-principal path. Anything that needs to run without a
human present, on a schedule, or from a pipeline is a job for a script against Microsoft
Graph directly (PowerShell, or any other Graph SDK), using whichever authentication model
that automation needs.

**You need functionality outside app and configuration profile assignments.** This tool
covers mobile apps and Settings Catalog configuration policies. It does not manage
compliance policies, enrollment configuration, or the broader Intune object surface -- for
anything outside that scope, use the admin center or the Graph API directly.

## A note on permissions

The Graph scopes this app uses -- `DeviceManagementApps.ReadWrite.All` and
`DeviceManagementConfiguration.ReadWrite.All` -- are tenant-wide, not scoped to specific
objects: consenting to them grants write access to every app and every configuration policy
in the tenant, not just the ones you intend to touch. The same is true of any script written
against the same scopes. See
[Security](security.md#what-the-app-reads-versus-what-it-writes) for what that means in
practice.
