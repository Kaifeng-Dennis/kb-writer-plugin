---
name: kb-ticket
description: Work on any KB ticket by Jira key, regardless of its current state. Use when the PM mentions a ticket key (e.g. KB-30499) and wants to check status, continue drafting, review, publish, or start new work on it.
---

# KB ticket

Enter the context of one KB ticket by Jira key and drive whatever action its current state requires. This is the universal entry point for ticket-backed work.

## Connectivity

Requires `KB_WRITER_API_BASE_URL` and `KB_WRITER_BEARER_TOKEN` in the environment. If the `kb-writer` MCP server is registered, prefer its tools over raw HTTP.

## Resolve

Ask the PM for the Jira key (for example `KB-30499`). Then call both endpoints to understand the full state:

```bash
# Ticket intake state (always available for existing tickets)
curl -sS "$KB_WRITER_API_BASE_URL/v1/workflow/tickets/$JIRA_KEY" \
  -H "Authorization: Bearer $KB_WRITER_BEARER_TOKEN"

# Workspace binding (may not exist)
curl -sS "$KB_WRITER_API_BASE_URL/v1/intent-workspaces/resolve/jira/$JIRA_KEY" \
  -H "Authorization: Bearer $KB_WRITER_BEARER_TOKEN"
```

## Branch by state

Present the current state and suggest the next action based on what the ticket actually supports:

**Ticket does not exist** (404 from `/v1/workflow/tickets/{key}`): Report that the ticket is not in the KB backlog. Suggest checking the key or adding it in the browser UI.

**Ticket exists, no workspace** (404 from `resolve/jira`): The ticket is in the backlog but has not been through the intent workspace flow. Report the ticket's intake status (pending/assigned/drafting) and suggest:
- If `pending`: "This ticket is waiting for assignment. You can assign it in the browser UI."
- If `assigned`: "This ticket is assigned and ready for generation. You can start generation in the browser UI."
- If `drafting`: "This ticket has an active generation. You can monitor progress in the browser UI."
- If the PM has a completed local session for this ticket: suggest `create-kb-intent` to create a workspace from that session.

**Ticket exists, workspace ACTIVE**: The ticket has an Intent Workspace. Report the workspace state and suggest the appropriate skill:
- Planning in progress → wait or check later
- Blocked UPDATE items → `select-kb-target`
- Ready items → `approve-kb-manifest`
- Generation running → `check-kb-status`
- Drafts in review → `review-kb-draft`
- Ready to publish → `publish-kb-draft`

**Workspace COMPLETED**: Report that all items are published. Ask if the PM wants to start a new revision cycle.

**Workspace ARCHIVED**: Report that the workspace is archived. Ask if the PM wants to create a new workspace for follow-up work.

Never assume the PM wants to create a workspace just because one does not exist. Always present the current state and let the PM choose the next action.
