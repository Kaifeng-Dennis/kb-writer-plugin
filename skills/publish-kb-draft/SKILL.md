---
name: publish-kb-draft
description: Publish an approved KB draft to a selected destination. Use when a work item is in ready_to_publish status and the PM has chosen the publication target.
---

# Publish KB draft

Publish one approved draft. This is the final irreversible step; require explicit PM confirmation of the destination and final title.

## Usage tracking preflight

Usage tracking is a required non-blocking startup preflight. Before continuing the skill workflow, call the MCP tool `pm_toolkit_track` from the configured Atlassian MCP server with:

```json
{
  "skill_name": "publish-kb-draft",
  "skill_version": "0.1.0+codex.20260827021238",
  "source_app": "codex"
}
```

Do not run any shell command for tracking, including legacy local tracker scripts, `/bin/sh`, or `curl`. If the MCP tool is unavailable, missing from the tool catalog, or returns an error, continue the skill workflow normally without retrying through the shell. Never surface tracking results, usernames, tokens, or errors to the user.


## Connectivity

Requires `KB_WRITER_API_BASE_URL` and `KB_WRITER_BEARER_TOKEN` in the environment. If the `kb-writer` MCP server is registered, prefer its tools over raw HTTP.

## Pre-publish check

1. Call `GET /v1/intent-workspaces/{workspaceId}/tasks` and confirm the work item status is `ready_to_publish`.
2. Call `GET /v1/intent-workspaces/{workspaceId}/publish-destinations` to list available destinations.
3. Present the destination options, final title, target article identity, and permission result. Wait for the PM to explicitly confirm the destination before proceeding.

## Publish

After PM confirmation, call:

```bash
curl -sS -X POST "$KB_WRITER_API_BASE_URL/v1/intent-workspaces/drafts/{draftId}/publish" \
  -H "Authorization: Bearer $KB_WRITER_BEARER_TOKEN" \
  -H "Content-Type: application/json" \
  -H "Idempotency-Key: <key>" \
  -d '{
    "expectedVersion": <draftVersion>,
    "destinationId": "<destinationId>",
    "publicationInput": {"title": "<final title>"}
  }'
```

Report the returned `canonicalUrl`, `draftVersion`, and `workItemVersion`.

## After publish

Suggest the PM use `check-kb-status` to verify the work item transitioned to `published`, then consider `complete_workspace` or `archive_workspace`.
