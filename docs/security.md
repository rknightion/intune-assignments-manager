---
title: Security
description: Graph permission scopes and their blast radius, the client-only architecture, token storage, logging, and how to report a vulnerability.
tags:
  - security
  - permissions
  - microsoft-graph
---

# Security

This page covers what the app can read and write in your tenant, where credentials and
tokens live, what is logged, and how to report a vulnerability.

## Architecture: no backend, no third party in the loop

Intune Assignments Manager has **no server component**. It is a static SvelteKit build
deployed to Cloudflare Pages, and every Microsoft Graph API call goes directly from your
browser to `graph.microsoft.com` -- there is no proxy, no middleware, and no third-party
server that ever sees your tokens or tenant data (see [Authentication - Security
Model](authentication.md#security-model)).

Practically, this means:

- Your Entra ID credentials are handled entirely by Microsoft's own login page inside the
  auth popup -- the app itself never sees your password.
- Access and refresh tokens, once issued, are held only in your browser.
- Nothing about your apps, profiles, groups, or assignments is sent anywhere except Microsoft
  Graph.

## Authentication: OAuth2 PKCE, no client secret

Sign-in uses the OAuth2 **Authorization Code flow with PKCE**, implemented by
[MSAL.js](https://github.com/AzureAD/microsoft-authentication-library-for-js). PKCE is
designed for public clients like single-page apps: the app registration needs **no client
secret**, and none should be created for it (see [Getting Started - No client secret
required](getting-started.md#step-2-configure-the-platform)). A leaked client ID is not a
credential -- there is nothing secret to leak from the app registration itself.

## What the app reads versus what it writes

The Tier 1 scopes requested at sign-in are a mix of read and **write** access:

| Scope                                         | Read/Write       | What it grants                                                       |
| --------------------------------------------- | ---------------- | -------------------------------------------------------------------- |
| `User.Read`                                   | Read             | Your own profile (name, email)                                       |
| `DeviceManagementApps.ReadWrite.All`          | **Read + Write** | All Intune mobile apps and their assignments, tenant-wide            |
| `DeviceManagementConfiguration.ReadWrite.All` | **Read + Write** | All Intune configuration policies and their assignments, tenant-wide |
| `Group.Read.All`                              | Read             | Azure AD group names, used to resolve assignment targets             |

Optional higher tiers add further scope -- see the full breakdown in
[Permissions](permissions.md#permission-tiers). Tier 3
(`DeviceManagementManagedDevices.ReadWrite.All`) additionally grants device actions (sync,
restart, retire); Tiers 2 and 4 are read-only.

!!! danger "Blast radius of the write scopes"
`DeviceManagementApps.ReadWrite.All` and `DeviceManagementConfiguration.ReadWrite.All` are
**not scoped to specific apps or profiles** -- they grant write access to every app and
every configuration policy in the tenant. Any user who consents to these scopes, or any
session where a token for these scopes is compromised, can modify assignments tenant-wide,
not just the ones they intended to change.

The write path itself carries an additional risk that is architectural, not a permission
issue: the Graph `assign` endpoint **replaces an item's entire assignment list** on every
call. The app always fetches current assignments and merges before writing (see
[Architecture - Bulk Assignment Execution Flow](development/architecture.md#bulk-assignment-execution-flow)),
but the **Review** step in the wizard is the last checkpoint before a tenant-wide write goes
out -- treat it as such.

## Application versus delegated permissions

All scopes used by this app are **delegated permissions**, acquired through interactive
user sign-in (see [Local Development Setup](development/setup.md#azure-app-registration)).
There is no application (app-only / client-credential) permission path, and no service
principal that can act without a signed-in user:

- Every Graph call runs **as the signed-in user**, subject to whatever conditional access,
  MFA, and Entra ID policies already apply to that user.
- The app cannot act in the background or outside an active browser session -- there is no
  daemon, no scheduled job, and no stored application credential that could be exfiltrated
  and reused independently of a user.
- The practical corollary: a user's own Graph privileges are the real ceiling. Consenting to
  these scopes cannot grant a user more access than an equivalent direct Graph API call
  already would with the same delegated permissions.

!!! tip "Evaluate with a dedicated account first"
Because the write scopes are tenant-wide, consider granting consent via a **dedicated
service/test account** or in a **test tenant** the first time you evaluate the app, rather
than an existing admin's daily-driver account -- see
[Permissions - Broad permissions](permissions.md#permission-tiers).

## Where tokens live

MSAL.js caches tokens in the browser's `localStorage` (see [Authentication - Token
Management](authentication.md#token-management)), which is what allows a session to survive
page refreshes and browser restarts. This has a direct consequence:

!!! warning "Anyone with access to the browser session has your Intune access"
Because tokens live in `localStorage`, anyone with access to the browser profile --
another user of the same OS account, malicious code that achieves script execution on the
page, or a stolen device with the session unlocked -- can act with the same Graph
permissions you consented to, for as long as the tokens remain valid. Always sign out on
shared or public computers (see [Authentication - Sign-out](authentication.md#sign-out)).

Signing out clears the MSAL token cache and the locally tracked granted-scopes state (stored
under the `intune-granted-scopes` `localStorage` key -- see [Developer docs -
Authentication](development/auth.md#incremental-consent)), but it does **not** sign you out
of Microsoft 365 or any other Microsoft service; it only clears this app's local session.

## What is logged

The app does not collect analytics, telemetry, or usage data, and there is no backend to log
to (see [Authentication - Security Model](authentication.md#security-model) and the
[FAQ](faq.md#general)). Any logging that does happen -- browser console output during
development, or errors surfaced via the notification system (see [Graph API Client -
notifyGraphError](development/graph-client.md#notifygrapherrorerror)) -- stays local to your
browser and is never transmitted. Graph API error responses rendered in the UI can include
tenant-specific identifiers (app names, group names, object IDs) as part of normal error
messages; treat browser console output and screenshots of error states as potentially
containing tenant data before sharing them.

## Revoking access

To revoke the app's access to your tenant, either as a user or as an administrator:

- **As a user**: go to [myapps.microsoft.com](https://myapps.microsoft.com), find the app,
  and select **Revoke permissions**.
- **As a tenant administrator**: revoke consent from the Azure Portal under the app
  registration's **API permissions** blade.

See [Permissions - Revoking Permissions](permissions.md#revoking-permissions) for the full
steps.

## Reporting a vulnerability

Do not open a public issue for a security vulnerability. Report it privately via GitHub's
[private vulnerability reporting](https://docs.github.com/en/code-security/security-advisories/guidance-on-reporting-and-writing-information-about-vulnerabilities/privately-reporting-a-security-vulnerability)
on this repository (**Security -> Report a vulnerability**), including enough detail to
reproduce.

Reports involving token handling, the incremental-consent flow, or a way to act outside the
scopes a user actually consented to are particularly in scope.
