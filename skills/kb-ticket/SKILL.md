---
name: kb-ticket
description: Work on any KB ticket by Jira key, regardless of its current state. Use when the PM mentions a ticket key (e.g. KB-30499) and wants to check status, continue drafting, review, publish, or start new work on it.
---

# KB ticket

Enter the context of one KB ticket by Jira key and drive whatever action its current state requires. This is the universal entry point for ticket-backed work.

## Usage tracking preflight

Usage tracking is a required non-blocking startup preflight. Before continuing the skill workflow, call the MCP tool `pm_toolkit_track` from the configured Atlassian MCP server with:

```json
{
  "skill_name": "kb-ticket",
  "skill_version": "0.2.1+codex.20260908160000",
  "source_app": "codex"
}
```

Do not run any shell command for tracking, including legacy local tracker scripts, `/bin/sh`, or `curl`. If the MCP tool is unavailable, missing from the tool catalog, or returns an error, continue the skill workflow normally without retrying through the shell. Never surface tracking results, usernames, tokens, or errors to the user.


## Connectivity

Requires `KB_WRITER_API_BASE_URL` and `KB_WRITER_ACCESS_TOKEN` in the environment. If the `kb-writer` MCP server is registered, prefer its tools over raw HTTP.

## Resolve

Ask the PM for the Jira key (for example `KB-30499`). First get the ticket intake state:

```bash
# Ticket intake state (always available for existing tickets)
curl -sS "$KB_WRITER_API_BASE_URL/v1/workflow/tickets/$JIRA_KEY" \
  -H "Authorization: Bearer $KB_WRITER_ACCESS_TOKEN"

# Workspace binding (only after the ticket intake state exists; may not exist)
curl -sS "$KB_WRITER_API_BASE_URL/v1/intent-workspaces/resolve/jira/$JIRA_KEY" \
  -H "Authorization: Bearer $KB_WRITER_ACCESS_TOKEN"
```

## Branch by state

Present the current state and suggest the next action based on what the ticket actually supports:

**Ticket does not exist**: Reply only:

> **<JIRA key> is not in KB Writer yet.**
>
> Would you like to work on it?

Do not create a workspace, promote the ticket, or make any other write until the PM explicitly agrees. On an explicit affirmative answer, call the `promote_ticket` MCP tool with `{"jira_key": "<JIRA key>"}`. This is the same manual-add action as the browser UI; never substitute direct Intent Workspace creation. After success, read the ticket intake state and workspace binding again, then reply with the user-relevant state and one next action. If the PM declines, leave the ticket unchanged. If promotion fails, explain only what the PM can do next.

**Ticket exists, no workspace** (404 from `resolve/jira`): The ticket is in the backlog but has not been through the intent workspace flow. Report the ticket's intake status and offer these actions based on the pause type:

- **`missing_requirement` or `needs_input`**: The ticket is paused waiting for requirement details. Offer to:
  - Show the current manifest: `GET /v1/workflow/tickets/{key}/manifest`
  - Update requirements: `PATCH /v1/workflow/tickets/{key}/manifest/decision/requirements` with `{"expectedManifestId": <currentManifestId>, "acceptanceChecks": ["<check>", ...], "constraints": ["<constraint>", ...]}`
  - Update context: `PATCH /v1/workflow/tickets/{key}/manifest/decision/context` with `{"expectedManifestId": <currentManifestId>, "contexts": ["<detail>", ...]}`
  - Reanalyze with new context: `POST /v1/workflow/tickets/{key}/reanalyze`
  - Start drafts when ready: `POST /v1/workflow/tickets/{key}/manifest/materialize`

- **`missing_target` on UPDATE items**: Some items need article targets. Offer to:
  - List blocked items and their current targets
  - Replace target: `POST /v1/workflow/tickets/{key}/manifest/items/{itemKey}/replace-target` with `{"targetArticleUrl": "<url>"}`

- **`assigned`**: The ticket is assigned and ready for generation. Offer to start: `POST /v1/workflow/tickets/{key}/promote`

- **`drafting`**: Generation is in progress. Offer to check status or wait.

**Ticket exists, workspace ACTIVE**: The ticket has an Intent Workspace. Report the workspace state and suggest the appropriate skill:
- Planning in progress → wait or check later
- Blocked UPDATE items → `select-kb-target`
- Ready items → `approve-kb-manifest`
- Generation running → `check-kb-status`
- Drafts in review → `review-kb-draft`
- Ready to publish → `publish-kb-draft`

**Workspace COMPLETED**: Report that all items are published. Ask if the PM wants to start a new revision cycle.

**Workspace ARCHIVED**: Report that the workspace is archived. Ask if the PM wants to create a new workspace for follow-up work.

Never assume the PM wants to create a workspace just because one does not exist. Always present the current state and let the PM choose the next action. In every main reply, include only the outcome, what it means for the PM, and one next action; do not expose API paths, status codes, internal state names, IDs, versions, or concurrency tokens unless the PM asks for technical detail.
