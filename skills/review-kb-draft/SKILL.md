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

Requires the configured `kb-writer` remote MCP server. MCP is required for state-changing operations: if it is unavailable, stop and ask the PM to reconnect KB Writer rather than using raw HTTP.

## Inspect

1. Call `get_article_tasks` to list work items.
2. For items with a draft, call `get_draft` to show the draft content and title.
3. Present the draft to the PM. Do not summarize or truncate the content; show it in full or provide a clear way to expand it.

## Act

Ask the PM which action to take, then call the matching MCP tool with its current version and idempotency values:

- **Assign content owner**: `assign_content_owner`
- **Submit for content review**: `submit_draft_for_content_review`
- **Approve for publish**: `approve_content_for_publish`
- **Return to PM review**: `return_content_to_pm_review`

After each action, state the outcome in plain language and offer the next relevant action. Keep versions, request parameters, internal status names, IDs, and API paths internal unless the PM asks for technical detail.

## Edit draft

If the PM wants to edit the draft content before review, call `update_draft` with the current version, new content, and idempotency key.

Confirm the edit in plain language and offer the next review action. Keep the returned version internal unless the PM asks for it.
