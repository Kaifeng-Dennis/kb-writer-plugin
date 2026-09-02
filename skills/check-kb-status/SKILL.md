---
name: check-kb-status
description: Check the current state of a KB Writer Intent Workspace, including planning status, Manifest readiness, generation progress, work item review state, and publication status. Use whenever the PM asks about progress or what to do next.
---

# Check KB status

Read-only status check for one Intent Workspace. Never modifies state; only reports what the server returns.

**Core contract:** report in PM language first. Internal state names (`UNRESOLVED`, `needs_input`, `missing_target`, lifecycle codes) belong in a collapsed technical appendix, not in the main answer. Lead with what the PM can do next, not with raw state.

## Usage tracking preflight

Usage tracking is a required non-blocking startup preflight. Before continuing the skill workflow, call the MCP tool `pm_toolkit_track` from the configured Atlassian MCP server with:

```json
{
  "skill_name": "check-kb-status",
  "skill_version": "0.2.0+codex.20260827022245",
  "source_app": "codex"
}
```

Do not run any shell command for tracking, including legacy local tracker scripts, `/bin/sh`, or `curl`. If the MCP tool is unavailable, missing from the tool catalog, or returns an error, continue the skill workflow normally without retrying through the shell. Never surface tracking results, usernames, tokens, or errors to the user.


## Connectivity

Requires `KB_WRITER_API_BASE_URL` and `KB_WRITER_ACCESS_TOKEN` in the environment. If the `kb-writer` MCP server is registered, prefer its tools over raw HTTP.

## Gather

Call these endpoints and present the results in a single summary:

1. `GET /v1/intent-workspaces/{workspaceId}` — workspace identity, lifecycle, version.
2. `GET /v1/intent-workspaces/planning-jobs/{planningJobId}` — if a planning job is active, its status and failure details.
3. `GET /v1/intent-workspaces/{workspaceId}/manifest` — current manifest revision, items, readiness, blockers.
4. `GET /v1/intent-workspaces/{workspaceId}/generation/latest` — latest preview job status, classification, items with draft IDs.
5. `GET /v1/intent-workspaces/{workspaceId}/tasks` — work item statuses, versions, content owner, review state.

## Report

Present one concise summary, in this order:

1. **What needs the PM's attention right now** (one line, plain language). Examples:
   - "1 篇文章等你选目标文章" (not "1 item blocked on missing_target")
   - "2 篇草稿等你批准开始写" (not "2 items ready, manifest not started")
   - "1 篇草稿在内容审阅中" (not "work item status=in_content_review")
2. **Suggested next action** — one concrete skill or step, matching the gate:
   - UPDATE items missing a target → suggest `select-kb-target`
   - Ready items not yet started → suggest `approve-kb-manifest`
   - Drafts in review → suggest `review-kb-draft`
   - Items ready to publish → suggest `publish-kb-draft`
   - All published → suggest completing or archiving the workspace
3. **Overall progress** — one sentence: how many items total, how many done, how many waiting on the PM.

Only after the three sections above, add a collapsible technical appendix with raw state: workspace lifecycle and version, planning job status, manifest revision, generation classification, per-item status codes, and work item versions. Never lead with the appendix.
