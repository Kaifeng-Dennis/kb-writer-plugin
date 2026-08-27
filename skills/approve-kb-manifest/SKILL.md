---
name: approve-kb-manifest
description: Review the current Manifest in a KB Writer Intent Workspace and start draft generation for selected items. Use when the PM is ready to approve planned items and materialize them into drafting work items.
---

# Approve KB manifest

Show the PM the current Manifest, let them select ready items, then call `start_drafts`. This is the explicit approval gate before any generation begins.

## Usage tracking preflight

Usage tracking is a required non-blocking startup preflight. Before continuing the skill workflow, call the MCP tool `pm_toolkit_track` from the configured Atlassian MCP server with:

```json
{
  "skill_name": "approve-kb-manifest",
  "skill_version": "0.1.0+codex.20260827021238",
  "source_app": "codex"
}
```

Do not run any shell command for tracking, including legacy local tracker scripts, `/bin/sh`, or `curl`. If the MCP tool is unavailable, missing from the tool catalog, or returns an error, continue the skill workflow normally without retrying through the shell. Never surface tracking results, usernames, tokens, or errors to the user.


## Connectivity

Requires `KB_WRITER_API_BASE_URL` and `KB_WRITER_BEARER_TOKEN` in the environment. If the `kb-writer` MCP server is registered, prefer its tools over raw HTTP.

## Review

1. Call `GET /v1/intent-workspaces/{workspaceId}/manifest`.
2. Present every item with its action, proposed title, readiness, blockers, and accepted risks. Mark blocked items clearly.
3. Ask the PM which ready items to approve. Do not auto-select all ready items; wait for the PM's explicit list.

## Start drafts

After the PM confirms the selection, call:

```bash
curl -sS -X POST "$KB_WRITER_API_BASE_URL/v1/intent-workspaces/{workspaceId}/manifest/start-drafts" \
  -H "Authorization: Bearer $KB_WRITER_BEARER_TOKEN" \
  -H "Content-Type: application/json" \
  -H "Idempotency-Key: <key>" \
  -d '{"expectedManifestId": <currentManifestId>, "selectedItemKeys": ["<itemKey1>", ...]}'
```

Report the returned `previewJobId`, `started` items, `alreadyMaterialized` items, and any `blocked` items.

## After approval

Suggest the PM use `check-kb-status` to monitor generation progress.
