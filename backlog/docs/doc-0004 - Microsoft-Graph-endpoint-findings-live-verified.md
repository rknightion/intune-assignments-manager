---
id: doc-0004
title: Microsoft Graph endpoint findings (live-verified)
type: other
created_date: '2026-08-14 16:41'
updated_date: '2026-08-14 16:41'
---
Every line here was established against a live tenant. Re-deriving any of it costs real Graph calls
and a tenant to make them against, which is why it lives in the repository rather than in one
machine's notes. **Add to it when you probe an endpoint; do not re-probe what is already recorded.**

Microsoft's documentation lists several of these as available. They are not. Documentation is not
evidence here — a response is.

## App install status: the traditional endpoints are gone

All of these fail in **both** `beta` and `v1.0`:

| Endpoint | Result |
|---|---|
| `/mobileApps/{id}/installSummary` | 400 "Resource not found" |
| `/mobileApps/{id}/deviceStatuses` | 400 "Resource not found" |
| `$expand=installSummary` on `/mobileApps` | "Could not find a property" |

## What works instead — the Reports API (POST, beta)

| Endpoint | Use | Notes |
|---|---|---|
| `getAppsInstallSummaryReport` | install counts for all apps | `ApplicationId`, `DisplayName`, `FailedDeviceCount`, `InstalledDeviceCount`, … |
| `getAppStatusOverviewReport` | one app's summary | requires `filter: "(ApplicationId eq 'xxx')"` |
| `getFailedMobileAppsReport` | all apps with failure counts | `ApplicationId`, `DisplayName`, `Platform`, `FailedDeviceCount` |
| `getFailedMobileAppsSummaryReport` | count of failed apps | returns a single `Count` |

Response shape, and it is not OData:

```json
{
  "TotalRowCount": 408,
  "Schema": [{ "Column": "ApplicationId", "PropertyType": "String" }],
  "Values": [["app-id", "App Name", 0, 2, 0, 0]]
}
```

Values are positional — index them through `Schema`, never by assumed column order. Pagination is
`skip`/`top` **in the request body**, not query parameters. Implementation:
`src/lib/graph/status.ts`.

## Per-device app install status: v1.0 only

`getDeviceInstallStatusReport` (beta) is **removed** — "Resource not found". The replacement is on
**v1.0, not beta**, which is the trap: everything else Intune-shaped in this app is beta, so the
instinct is wrong here.

```
POST /deviceManagement/reports/microsoft.graph.retrieveDeviceAppInstallationStatusReport
```

Requires `filter: "(ApplicationId eq 'xxx')"`. **Page size is capped at 50.** Returns `DeviceName`,
`DeviceId`, `UserName`, `InstallState`, `AppInstallState`, `AppInstallStateDetails`, `ErrorCode`,
`HexErrorCode`, `LastModifiedDateTime`. Implemented as `getAppDeviceInstallStatuses()` in
`src/lib/graph/status.ts`.

`client.request()` and `client.batch()` take a `version: 'v1.0'` option for exactly this.

## Confirmed non-working

| Endpoint | Result |
|---|---|
| `getDeviceInstallStatusReport` | removed — use `retrieveDeviceAppInstallationStatusReport` |
| `getDeviceInstallStatusByAppReport` | "Resource not found" |
| `getConfigurationPolicyDevicesReport` | 500 |
| `getConfigurationPoliciesReportForDevice` | 500 |
| `getConfigurationPolicyNonComplianceSummaryReport` | BadRequest |
| server-side filter `(FailedDeviceCount gt 0)` | type mismatch — the column is `String` internally despite reporting as `Int32`; filter client-side |

## Config profile status

`deviceConfigurations/{id}/deviceStatusOverview` (v1.0) works **only for legacy profiles**. It
returns 404 for Settings Catalog ids (`configurationPolicies`). Every Reports API config-profile
endpoint returns 500. There is currently no working path to Settings Catalog per-device status —
that is a negative result, not an unfinished investigation.

## Assignment writes

The `assign` action **replaces the entire assignment list**. There is no additive form. Existing
assignments must be fetched and merged first, every time — this is what `src/lib/graph/execute.ts`
exists to do, and it is why its fetch → merge → apply order is not refactorable.
