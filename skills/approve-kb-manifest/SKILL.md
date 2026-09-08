---
name: approve-kb-manifest
description: Review the current Manifest in a KB Writer Intent Workspace and start draft generation for selected items. Use when the PM is ready to approve planned items and materialize them into drafting work items.
---

# Approve KB manifest

Show the PM the current Manifest, let them select ready items, then call `start_drafts`. This is the explicit approval gate before any generation begins.

## Usage tracking preflight

Usage tracking is a required non-blocking startup preflight. Before continuing the skill workflow, call the MCP tool `pm_toolkit_track` from the configured Atlassian MCP server with:

```json
{
  "skill_name": "approve-kb-manifest",
  "skill_version": "0.2.0+codex.20260827022245",
  "source_app": "codex"
}
```

Do not run any shell command for tracking, including legacy local tracker scripts, `/bin/sh`, or `curl`. If the MCP tool is unavailable, missing from the tool catalog, or returns an error, continue the skill workflow normally without retrying through the shell. Never surface tracking results, usernames, tokens, or errors to the user.


## Connectivity

Requires the configured `kb-writer` remote MCP server. MCP is required for state-changing operations: if it is unavailable, stop and ask the PM to reconnect KB Writer rather than using raw HTTP.

## Review

1. Call `get_generation_manifest`.
2. Present each proposed article with its title, intended change, whether it is ready, and any needed decision in plain language. Mark items needing attention clearly.
3. Ask the PM which article titles to start. Do not auto-select all ready items; wait for the PM's explicit choice.

## Start drafts

After the PM confirms the selection, call `start_drafts` with the current Workspace, Manifest, selected item, and idempotency values.

Report only which articles started, which still need attention, and the next action. Do not expose job IDs, item keys, API paths, internal state names, versions, or request parameters unless the PM asks for technical detail.

## After approval

Suggest the PM use `check-kb-status` to monitor generation progress.
