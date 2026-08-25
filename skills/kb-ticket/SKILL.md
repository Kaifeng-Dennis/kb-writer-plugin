---
name: kb-ticket
description: Work on any KB ticket by Jira key, regardless of its current state. Use when the PM mentions a ticket key (e.g. KB-30499) and wants to check status, continue drafting, review, publish, or start new work on it.
---

# KB ticket

Enter the context of one KB ticket by Jira key and drive whatever action its current state requires. This is the universal entry point for ticket-backed work.

## Connectivity

Requires `KB_WRITER_API_BASE_URL` and `KB_WRITER_BEARER_TOKEN` in the environment. If the `kb-writer` MCP server is registered, prefer its tools over raw HTTP.

## Resolve

Ask the PM for the Jira key (for example `KB-30499`). Then call:

```bash
curl -sS "$KB_WRITER_API_BASE_URL/v1/intent-workspaces/resolve/jira/$JIRA_KEY" \
  -H "Authorization: Bearer $KB_WRITER_BEARER_TOKEN"
```

## Branch by state

Present the resolved state and suggest the next action:

- **No workspace exists**: The ticket has never been through the intent workspace flow. Suggest the PM use the browser UI to start first generation, or use `create-kb-intent` if they want to work from a local session instead.
- **Workspace ACTIVE, planning in progress**: Report planning status and suggest waiting or checking again later.
- **Workspace ACTIVE, manifest has blocked UPDATE items**: Suggest `select-kb-target` to bind targets.
- **Workspace ACTIVE, manifest has ready items**: Suggest `approve-kb-manifest` to start drafting.
- **Workspace ACTIVE, generation running**: Report progress and suggest `check-kb-status` to monitor.
- **Workspace ACTIVE, drafts in review**: Suggest `review-kb-draft` to drive content review.
- **Workspace ACTIVE, items ready_to_publish**: Suggest `publish-kb-draft`.
- **Workspace COMPLETED**: Report that all items are published. Ask if the PM wants to start a new revision cycle.
- **Workspace ARCHIVED**: Report that the workspace is archived. Ask if the PM wants to create a new workspace for follow-up work.

Never assume the PM wants to create a new workspace just because one does not exist. Always present the current state and let the PM choose the next action.
