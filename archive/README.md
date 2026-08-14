# GitHub Issues archive

`issues-dump.json` is the complete GitHub Issues history of this repository as it stood on
2026-08-14, captured before the issues were deleted from GitHub. **It is the record, not a
pointer** — the issues it describes no longer exist on github.com.

9 issues (8 closed, 1 open), with full bodies, all comments, labels, authors, timestamps and
state reasons. Comment completeness was verified against the REST API's own per-issue
`comments` counts, which match the dump exactly for all 9.

The closed-work index in the tracker (`backlog doc list --plain`) is the readable summary; this
file is the underlying detail.

## Reading it

```bash
jq -r '.[] | "#\(.number) [\(.state)] \(.title)"' archive/issues-dump.json
jq -r '.[] | select(.number == 85) | .body' archive/issues-dump.json
jq -r '.[] | select(.number == 85) | .comments[] | .body' archive/issues-dump.json
```

## Redaction

`backlog/` and this archive are committed to a **public** repository, so identifiers were
replaced before the file entered git. Deleting issues that quote a private host name while
committing that same name into permanent public history would move the identifier from
somewhere deletable to somewhere that is not.

One real value maps to one token everywhere, so cross-issue correlation survives without the
identifier:

| Placeholder | What it stood for | Occurrences |
|---|---|---|
| `<broker-host>` | the host running the OpenBao CI token broker | 7 |
| `<internal-git-domain>` | the tailnet-only self-hosted git domain | 1 |
| `<claude-design-project-id>` | the m7kni Design System project id in Claude Design | 1 |

Nothing else was changed. GitHub org ids (`278668071`, `12484127`) and the repo id
(`1162771291`) are public metadata and were left alone, as issue #84 itself notes. No email
addresses, IP addresses or credentials were present in the source; that was checked rather than
assumed.

The sweep ran over **decoded field values**, not the serialized JSON. In `json.dumps` output an
escape such as `\n` leaves a literal `n` immediately before the following word, which breaks a
`\b` word boundary — a blob sweep can certify a file clean while it still leaks.
