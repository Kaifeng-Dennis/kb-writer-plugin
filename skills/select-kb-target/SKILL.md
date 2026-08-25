---
name: select-kb-target
description: Resolve and bind the target KB article for a Manifest UPDATE item in a KB Writer Intent Workspace. Use when a workspace has UPDATE items blocked on missing_target and the PM needs to pick the article to update.
---

# Select KB target

Bind one Manifest UPDATE item to a server-resolved article target. The backend owns article search, target resolution, and revalidation; this skill only orchestrates the PM's explicit choice.

## Connectivity

Requires `KB_WRITER_API_BASE_URL` and `KB_WRITER_BEARER_TOKEN` in the environment. If the `kb-writer` MCP server is registered, prefer its tools over raw HTTP.

## Inputs

Ask the PM for:

1. `workspaceId` — the Intent Workspace ID (from `create_kb_intent` or `check_kb_status`).
2. `itemKey` — the Manifest item key of the UPDATE item to bind.

Do not guess or infer either value. If the PM does not know them, use `check-kb-status` first.

## Resolve candidates

1. Call `GET /v1/intent-workspaces/{workspaceId}/targets?manifestItemKey={itemKey}` to list server-resolved candidates. Present each candidate with its title, canonical URL, match reasons, and update-impact summary.
2. If no candidates are returned, ask the PM for a URL or external ID and call `POST /v1/intent-workspaces/{workspaceId}/targets/resolve` with that reference. Show the resolved target before proceeding.

## Bind explicitly

Present the chosen candidate and wait for the PM to confirm before calling:

```bash
curl -sS -X POST "$KB_WRITER_API_BASE_URL/v1/intent-workspaces/{workspaceId}/manifest/items/{itemKey}/select-target" \
  -H "Authorization: Bearer $KB_WRITER_BEARER_TOKEN" \
  -H "Content-Type: application/json" \
  -H "Idempotency-Key: <key>" \
  -d '{"expectedManifestId": <currentManifestId>, "articleId": "<articleId>", "targetSnapshotId": "<targetSnapshotId>"}'
```

Never bind a target without the PM's explicit selection. Never pick the top-ranked candidate automatically.

## Verify

After binding, call `GET /v1/intent-workspaces/{workspaceId}/manifest` and confirm the item's `blockersJson` no longer contains `missing_target`. Report the item's readiness.
