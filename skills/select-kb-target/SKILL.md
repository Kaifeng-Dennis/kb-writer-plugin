---
name: select-kb-target
description: Resolve and bind the target KB article for a Manifest UPDATE item in a KB Writer Intent Workspace. Use when a workspace has UPDATE items blocked on missing_target and the PM needs to pick the article to update.
---

# Select KB target

Bind one Manifest UPDATE item to a server-resolved article target. The backend owns article search, target resolution, and revalidation; this skill only orchestrates the PM's explicit choice.

**Core contract:** recommend, then confirm. Never ask the PM to type an article ID from memory; always show server-resolved candidates first and let the PM pick from the list (or supply an explicit URL when nothing matches). Never bind silently.

## Usage tracking preflight

Usage tracking is a required non-blocking startup preflight. Before continuing the skill workflow, call the MCP tool `pm_toolkit_track` from the configured Atlassian MCP server with:

```json
{
  "skill_name": "select-kb-target",
  "skill_version": "0.1.0+codex.20260827021412",
  "source_app": "codex"
}
```

Do not run any shell command for tracking, including legacy local tracker scripts, `/bin/sh`, or `curl`. If the MCP tool is unavailable, missing from the tool catalog, or returns an error, continue the skill workflow normally without retrying through the shell. Never surface tracking results, usernames, tokens, or errors to the user.


## Connectivity

Requires `KB_WRITER_API_BASE_URL` and `KB_WRITER_BEARER_TOKEN` in the environment. If the `kb-writer` MCP server is registered, prefer its tools over raw HTTP.

## Inputs

Ask the PM for:

1. `workspaceId` — the Intent Workspace ID (from `create_kb_intent` or `check_kb_status`).
2. `itemKey` — the Manifest item key of the UPDATE item to bind.

Do not guess or infer either value. If the PM does not know them, use `check-kb-status` first.

## Resolve candidates

1. Call `GET /v1/intent-workspaces/{workspaceId}/targets?manifestItemKey={itemKey}` to list server-resolved candidates.
2. Present candidates as a numbered PM-readable shortlist, best match first. For each candidate show: title, canonical URL, why it matched (in plain language), and what the update would touch. Mark the single best candidate as the recommendation, but do not pre-select it.
3. If no candidates are returned, say so plainly and ask the PM for a URL or external ID. Call `POST /v1/intent-workspaces/{workspaceId}/targets/resolve` with that reference and show the resolved target as the only candidate.

## Confirmation gate

Pause and wait for the PM's explicit choice before any binding call. Accept: a candidate number, a candidate title, an explicit URL, "cancel", or an edited candidate list. Do not proceed on silence, on "looks good" without a selection, or on the assumption that the top-ranked candidate is acceptable.

## Bind explicitly

After the PM explicitly picks one candidate, restate the binding ("把《<item 标题>》关联到 <文章标题>") and only then call:

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
