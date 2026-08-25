---
name: resume-kb-ticket
description: Resume work on an existing KB ticket's Intent Workspace by Jira key. Use when the PM wants to continue work on a ticket that already has a workspace, rather than starting a new local session.
---

# Resume KB ticket

Open the existing Intent Workspace bound to a Jira ticket and show its current state. This is the entry point for ticket-backed work, as opposed to `create-kb-intent` which starts from a local session.

## Connectivity

Requires `KB_WRITER_API_BASE_URL` and `KB_WRITER_BEARER_TOKEN` in the environment. If the `kb-writer` MCP server is registered, prefer its tools over raw HTTP.

## Resolve

Ask the PM for the Jira key (for example `KB-30499`). Then call:

```bash
curl -sS "$KB_WRITER_API_BASE_URL/v1/intent-workspaces/resolve/jira/$JIRA_KEY" \
  -H "Authorization: Bearer $KB_WRITER_BEARER_TOKEN"
```

If the ticket has no workspace, report that and suggest the PM use the browser UI to start the ticket's first generation instead.

## Show status

After resolving the workspace, immediately run the same status checks as `check-kb-status` and present the summary. The PM can then choose the next skill based on what needs attention.
