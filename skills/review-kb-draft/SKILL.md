---
name: review-kb-draft
description: Review a generated KB draft, assign a content owner, submit for content review, approve for publish, or return to PM review. Use when a work item has a draft ready and the PM needs to drive the review workflow.
---

# Review KB draft

Drive the content review workflow for one work item. All state transitions use the work item's current `version` as the CAS token.

## Usage tracking preflight

Usage tracking is a required non-blocking startup preflight. Before continuing the skill workflow, call the MCP tool `pm_toolkit_track` from the configured Atlassian MCP server with:

```json
{
  "skill_name": "review-kb-draft",
  "skill_version": "0.2.0+codex.20260827022245",
  "source_app": "codex"
}
```

Do not run any shell command for tracking, including legacy local tracker scripts, `/bin/sh`, or `curl`. If the MCP tool is unavailable, missing from the tool catalog, or returns an error, continue the skill workflow normally without retrying through the shell. Never surface tracking results, usernames, tokens, or errors to the user.


## Connectivity

Requires the configured `kb-writer` remote MCP server. MCP is required for state-changing operations: if it is unavailable, stop and ask the PM to reconnect KB Writer rather than using raw HTTP. Treat it as unavailable only after searching the tool catalog for a capability name as a substring and finding nothing — not because a guessed full tool name failed to match.

## Inspect

1. Call `get_article_tasks` to list work items.
2. For the selected item with a draft, call `get_draft` to confirm its current title, version, and `workspaceUrl`.

## Codex Workspace handoff

When `open_in_codex` is available and `workspaceUrl` is present, open that
existing Workspace in the current Codex task's right side panel.
Do not construct a UI URL from `KB_WRITER_API_BASE_URL`: it is an API origin,
which may differ from the frontend origin in local development.

`workspaceUrl` is server-built from the selected task's persisted `articleId`
and `workItemId`. Do not use the Draft title, image URLs, or the chat's current
content as identity. Tell the PM to review and edit the Draft in that side
panel, where the existing editor can render its images and retain image review
notes. Keep the chat response to a concise review summary and the next action.

## Claude fallback

When `open_in_codex` is unavailable, present `workspaceUrl` as a regular
Workspace link. If it is unavailable, present the full or expandable Draft so
Claude users retain a usable review surface.

When the PM returns after saving, call `get_article_tasks` and `get_draft`
again before taking a review transition so the current persisted version remains
the CAS token.

## Act

Ask the PM which action to take, then call the matching MCP tool with its current version and idempotency values:

- **Assign content owner**: `assign_content_owner`
- **Submit for content review**: `submit_draft_for_content_review`. If no owner is assigned, ask the PM to choose one and include `content_owner_identity` in this same call. Do not make the PM perform a separate assignment first.
- **Approve for publish**: `approve_content_for_publish`
- **Return to PM review**: `return_content_to_pm_review`

After each action, state the outcome in plain language and offer the next relevant action. Keep versions, request parameters, internal status names, IDs, and API paths internal unless the PM asks for technical detail.

## Edit draft

If the PM wants to edit the draft content before review, call `update_draft` with the current version, new content, and idempotency key.

Confirm the edit in plain language and offer the next review action. Keep the returned version internal unless the PM asks for it.
