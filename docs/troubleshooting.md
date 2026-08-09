---
title: Troubleshooting
description: Diagnosing sign-in failures, consent and permission errors, tenant mismatches, and throttling in Intune Assignments Manager.
tags:
  - troubleshooting
---

# Troubleshooting

For general questions about how features behave, see the [FAQ](faq.md). This page covers
diagnosing failures -- what an error means and what to check.

If nothing here matches what you are seeing,
[file an issue](https://github.com/rknightion/intune-assignments-manager/issues/new) with the
browser and OS you are using, the page you were on, and the exact error text.

## Sign-in and consent

### Popup blocked or closes immediately

**Symptom**: Clicking **Sign in with Microsoft** does nothing, or a browser notification
appears saying a popup was blocked.

**Cause**: The app uses [`loginPopup()`](https://github.com/AzureAD/microsoft-authentication-library-for-js)
for the OAuth2 PKCE flow. Browsers block popups not triggered directly by a user gesture, and
some popup blockers also block the intermediate redirect back to the app.

**Check**: Look for a blocked-popup icon in the address bar.

**Fix**: Allow popups for the app's domain and click **Sign in with Microsoft** again.

### Consent prompt shows the wrong permissions, or none at all

**Symptom**: The consent screen lists fewer permissions than expected, or the app behaves as
if you were never asked for consent.

**Cause**: The app uses a **tiered, incremental consent model** (see
[Permissions](permissions.md)). Only Tier 1 scopes -- `User.Read`,
`DeviceManagementApps.ReadWrite.All`, `DeviceManagementConfiguration.ReadWrite.All`,
`Group.Read.All` -- are requested at sign-in. Higher tiers are requested only when you
navigate to a feature that needs them, as a separate popup.

**Check**: Confirm which page you were on when the prompt appeared, and cross-reference it
against the [scope-to-feature table](permissions.md#how-scopes-map-to-features).

**Fix**: Accept the prompt for the feature you are trying to use. If no prompt appears at
all, your organisation may require **admin consent** -- see below.

### "Need admin approval" or the consent popup closes with an error

**Symptom**: Microsoft's consent screen shows "Need admin approval" instead of an Accept
button, or the popup closes without granting anything.

**Cause**: `DeviceManagementApps.ReadWrite.All`, `DeviceManagementConfiguration.ReadWrite.All`,
and `Group.Read.All` are **admin-level Graph scopes**. If your tenant has user consent
disabled for admin-level permissions (the default in many hardened tenants), an individual
user cannot self-consent, regardless of how many times they click Accept.

**Fix**: A **Global Administrator** or **Intune Administrator** must grant admin consent for
the app registration once, tenant-wide. From the Azure Portal: **App registrations** > your
app > **API permissions** > **Grant admin consent**. See
[Granting Additional Permissions](permissions.md#granting-additional-permissions).

### Signed in, but scopes reset after every page refresh

**Symptom**: You have to re-consent to a tier you already granted, every session.

**Cause**: Granted-scope tracking is stored in `localStorage` under the key
`intune-granted-scopes` (see [Authentication - Scope accumulation](development/auth.md#incremental-consent)).
If the browser is in a private/incognito window, has third-party storage restrictions, or
clears site data on close, that key does not persist.

**Check**: Confirm you are not in a private browsing window and that the site is not
excluded from storage in your browser's privacy settings.

## "Insufficient permissions" and Graph errors

### Insufficient permissions / 403 on a specific action

**Symptom**: An action fails with an insufficient-permissions message, but you are signed in.

**Cause**: The Graph client throws a typed `PermissionError` for any `403` response (see
[Graph API Client - PermissionError](development/graph-client.md#permissionerror-http-403)).
This means the request reached Microsoft Graph and was rejected for lacking a scope --
distinct from a `401`, which means the token itself was rejected.

**Check**: Go to **Settings** and compare the granted tiers against what the operation needs:

| Operation                                       | Required scopes                                                                     |
| ----------------------------------------------- | ----------------------------------------------------------------------------------- |
| Read-only browsing                              | `DeviceManagementApps.Read.All`, `DeviceManagementConfiguration.Read.All`           |
| Assignment management (bulk assign, CSV import) | `DeviceManagementApps.ReadWrite.All`, `DeviceManagementConfiguration.ReadWrite.All` |
| Group search                                    | `Group.Read.All`                                                                    |
| Audit log                                       | `DeviceManagementApps.Read.All`                                                     |

**Fix**: Click **Grant Permissions** on the Settings page for the missing tier. If the tier
already shows as granted, the tenant-level admin consent may not have propagated yet, or a
tenant admin may have revoked consent centrally -- see
[Revoking Permissions](permissions.md#revoking-permissions) for where that is controlled.

### Session expires mid-task, or "Your session has expired. Please sign in again."

**Symptom**: An in-progress action fails and you are prompted to sign in again.

**Cause**: Access tokens last approximately one hour. MSAL.js retries silently via
`acquireTokenSilent()` using the cached refresh token first; only if that fails (refresh
token expired, revoked, or a new scope needs interactive consent) does the app fall back to
`acquireTokenPopup()`. If that also fails, the Graph client raises `AuthenticationError` and
`toFriendlyMessage()` renders it as "Your session has expired. Please sign in again." (see
[Graph API Client - AuthenticationError](development/graph-client.md#authenticationerror-http-401)).

**Fix**: Sign in again. Wizard state is kept in memory (not lost), so you can resume the
Bulk Assignment flow after re-authenticating -- see the [FAQ](faq.md#authentication).

### Rate limited / "Microsoft Graph is rate limiting requests"

**Symptom**: A bulk operation slows down or a friendly rate-limit message appears.

**Cause**: The Graph client retries `429` responses automatically -- up to 3 attempts,
sleeping for the `Retry-After` duration returned by Graph (defaulting to 5 seconds if the
header is missing). Batch requests handle `429` per-item: failed items are collected,
the client waits for the longest `Retry-After` among them, and resubmits just those items,
also up to 3 total attempts (see [Graph API Client](development/graph-client.md#batchrequests-options)).

**Check**: This is expected behaviour under load, not a bug -- large bulk-assignment runs
against many apps/profiles and groups generate a proportionally large number of Graph calls.

**Fix**: Nothing to do for occasional throttling; the client retries transparently. If a
`RateLimitError` still surfaces after all retries are exhausted, wait and retry the
operation, or reduce the number of items selected in a single wizard run.

### Wrong tenant, or app/group data doesn't match what you expect

**Symptom**: The apps, profiles, or groups shown don't match the tenant you intended to sign
into.

**Cause**: The app's MSAL authority is configured as `https://login.microsoftonline.com/common`
(see [Authentication - MSAL Configuration](development/auth.md#msal-configuration)), which is
multi-tenant: it allows sign-in to any Microsoft Entra ID tenant that has consented to the app
registration, and Microsoft's account picker may default to a different account/tenant than
the one you meant to use.

**Fix**: Sign out (clears the local MSAL cache and any tracked permissions -- see
[Sign-out](authentication.md#sign-out)), then sign in again and pick the correct account at
the Microsoft login screen. If you use multiple work accounts, check which one is active in
the browser before signing in.

### GCC, DoD, or other sovereign cloud tenant

**Symptom**: Sign-in or Graph calls fail entirely, or the app cannot reach your tenant at all.

**Cause**: The app is hardcoded to the Microsoft public cloud endpoints
(`login.microsoftonline.com` / `graph.microsoft.com`). GCC High, DoD, and other sovereign
clouds use different authority and Graph endpoints.

**Fix**: Not supported without modifying the MSAL and Graph client configuration in source --
see the [FAQ](faq.md#general).

## Assignment and data issues

### Assignment write appears to have removed unrelated assignments

**Symptom**: After running a bulk assignment, a group's existing assignment for an
unrelated app changed or disappeared.

**Cause**: The Graph `assign` endpoint **replaces the entire assignment list** for an item on
every write. The app is designed to fetch current assignments first and merge in your
changes (see [Architecture - Bulk Assignment Execution Flow](development/architecture.md#bulk-assignment-execution-flow)),
but this only covers what the merge step actually saw at fetch time -- a concurrent change
made by someone else (or in the Intune portal) between your fetch and your apply is not
accounted for.

**Fix**: Always review the diff on the **Review** step before applying (see
[Bulk Assignment Wizard](assign/index.md)), and avoid running two bulk operations against
overlapping items at the same time.

### Status page is missing profiles you know have deployment errors

**Symptom**: A Settings Catalog profile with known deployment issues does not appear on the
[Deployment Status](status.md) page.

**Cause**: The device status overview endpoint the app uses only works for legacy device
configuration profiles. Settings Catalog policies return a 404 from that endpoint and are
silently excluded -- see [Graph API Client - Known API Limitations](development/graph-client.md#known-api-limitations).

**Fix**: None from within the app; this is a Graph API limitation, not a filter you can
change. Check the profile's status directly in the Intune admin center instead.

### CSV import rejects rows

**Symptom**: Importing a CSV shows validation errors instead of pre-populating the wizard.

**Cause**: See the validation table in [CSV Import & Export](csv.md#validation) -- most
failures are a missing required header, an `ItemType`/`TargetType` value outside the allowed
set, or an `ItemId`/`GroupId` that does not resolve (and no exact-match `ItemName`/`GroupName`
fallback either).

**Fix**: Check the per-row error messages shown after import, and prefer GUIDs over names --
name resolution requires an exact, unique match. See
[CSV - Name-Based Resolution](csv.md#name-based-resolution).

## Where to look for more detail

- [FAQ](faq.md) -- common behavioural questions (does it overwrite assignments, can I set
  different intents per app, browser support, and more)
- [Graph API Client](development/graph-client.md) -- the client's retry logic and full error
  type hierarchy
- [Permissions](permissions.md) -- the full scope-tier breakdown
