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
  "skill_version": "0.2.0+codex.20260827022245",
  "source_app": "codex"
}
```

Do not run any shell command for tracking, including legacy local tracker scripts, `/bin/sh`, or `curl`. If the MCP tool is unavailable, missing from the tool catalog, or returns an error, continue the skill workflow normally without retrying through the shell. Never surface tracking results, usernames, tokens, or errors to the user.


## Connectivity

Requires the configured `kb-writer` remote MCP server. MCP is required for state-changing operations: if it is unavailable, stop and ask the PM to reconnect KB Writer rather than using raw HTTP. Treat it as unavailable only after searching the tool catalog for a capability name as a substring and finding nothing — not because a guessed full tool name failed to match.

## Pre-publish check

1. Call `get_article_tasks` and confirm the work item is ready to publish.
2. Call `list_publish_destinations` to list available destinations.
3. Present the destination options and final title. If publishing is unavailable, explain the user-relevant reason and next action. Wait for the PM to explicitly confirm the destination before proceeding.

## Publish

After PM confirmation, call `publish_draft` with the current draft version, selected destination, final title, and idempotency key.

## After publish

1. Confirm the published title and provide its published link. Do not expose draft or work-item versions, IDs, API paths, or request parameters unless the PM asks for technical detail.
2. Read `get_workspace` and `get_article_tasks`.
3. Only when `originType` is `JIRA`, `jiraKey` is present, the task list is non-empty, and every task has status `published`, ask: “All articles for `<jiraKey>` are published. Do you want to close this KB ticket in Jira?”
4. On an explicit yes, invoke the host-configured local Jira skill that closes the exact `<jiraKey>`. Do not call Jira through raw HTTP, use a different connector, or close a parent INIT ticket.
5. If the PM declines, no Jira-closing skill is available, or that skill fails, report that outcome and keep the successful publication unchanged. Do not retry the Jira transition or roll back the Draft or Work Item.

When the close condition is not met, suggest `check-kb-status`, then consider `complete_workspace` or `archive_workspace` instead. Never offer to close a ticketless Workspace or a Jira Workspace with any task not yet published.
