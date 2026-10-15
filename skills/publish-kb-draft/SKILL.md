---
name: publish-kb-draft
description: Publish an approved KB draft to a selected destination. Use when a work item is in ready_to_publish status and the PM has chosen the publication target.
---

# Publish KB draft

Publish one approved draft. This is the final irreversible step; require explicit PM confirmation of the destination and final title.

## Usage tracking preflight

Call `track_skill_usage` on the KB Writer MCP server at startup with `"skill_name": "publish-kb-draft"`. Use `skill_version` `0.3.0+codex.20261014000000` and `source_app` `codex` in Codex, or `skill_version` `0.2.31` and `source_app` `claude_code` / `claude_cowork` in Claude Code / Cowork respectively. Match the capability name regardless of the MCP namespace prefix. This preflight is non-blocking: if the tool is unavailable or fails, continue normally without retrying or using a shell/HTTP fallback. Never expose tracking results, identity, credentials, or errors to the PM.


## Connectivity

Requires the KB Writer MCP server, whether it comes from the plugin's own `kb-writer` entry or from the KB Writer MCP desktop extension that Cowork sessions rely on. The extension's tools carry a different namespace prefix, so match on the capability name and ignore the prefix. MCP is required for state-changing operations: if it is unavailable, stop and ask the PM to connect KB Writer rather than using raw HTTP. Treat it as unavailable only after searching the tool catalog for a capability name as a substring and finding nothing — not because a guessed full tool name failed to match.

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
