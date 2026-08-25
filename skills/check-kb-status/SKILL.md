---
name: check-kb-status
description: Check the current state of a KB Writer Intent Workspace, including planning status, Manifest readiness, generation progress, work item review state, and publication status. Use whenever the PM asks about progress or what to do next.
---

# Check KB status

Read-only status check for one Intent Workspace. Never modifies state; only reports what the server returns.

## Connectivity

Requires `KB_WRITER_API_BASE_URL` and `KB_WRITER_BEARER_TOKEN` in the environment. If the `kb-writer` MCP server is registered, prefer its tools over raw HTTP.

## Gather

Call these endpoints and present the results in a single summary:

1. `GET /v1/intent-workspaces/{workspaceId}` — workspace identity, lifecycle, version.
2. `GET /v1/intent-workspaces/planning-jobs/{planningJobId}` — if a planning job is active, its status and failure details.
3. `GET /v1/intent-workspaces/{workspaceId}/manifest` — current manifest revision, items, readiness, blockers.
4. `GET /v1/intent-workspaces/{workspaceId}/generation/latest` — latest preview job status, classification, items with draft IDs.
5. `GET /v1/intent-workspaces/{workspaceId}/tasks` — work item statuses, versions, content owner, review state.

## Report

Present one concise summary:

- Workspace lifecycle and version
- Planning status (if applicable)
- Manifest revision and item readiness (ready / blocked counts)
- Generation classification and per-item status
- Next action suggestion based on the current state:
  - UPDATE items with `missing_target` → suggest `select-kb-target`
  - Ready items not yet started → suggest `approve-kb-manifest`
  - Drafts in review → suggest `review-kb-draft`
  - Items `ready_to_publish` → suggest `publish-kb-draft`
  - All published → suggest `complete_workspace` or `archive_workspace`
