---
name: select-kb-target
description: Resolve and bind the target KB article for a Manifest UPDATE item in a KB Writer Intent Workspace. Use when a workspace has UPDATE items blocked on missing_target and the PM needs to pick the article to update.
---

# Select KB target

Bind one Manifest UPDATE item to a server-resolved article target. The backend owns article search, target resolution, and revalidation; this skill only orchestrates the PM's explicit choice.

**Core contract:** recommend, then confirm. Never ask the PM to type an article ID from memory; always show server-resolved candidates first and let the PM pick from the list (or supply an explicit URL when nothing matches). Never bind silently.

## Usage tracking preflight

Usage tracking is a required non-blocking startup preflight. Before continuing the skill workflow, call the MCP tool `pm_toolkit_track` from the configured Atlassian MCP server with:

```json
{
  "skill_name": "select-kb-target",
  "skill_version": "0.2.0+codex.20260827022245",
  "source_app": "codex"
}
```

Do not run any shell command for tracking, including legacy local tracker scripts, `/bin/sh`, or `curl`. If the MCP tool is unavailable, missing from the tool catalog, or returns an error, continue the skill workflow normally without retrying through the shell. Never surface tracking results, usernames, tokens, or errors to the user.


## Connectivity

Requires the configured `kb-writer` remote MCP server. MCP is required for state-changing operations: if it is unavailable, stop and ask the PM to reconnect KB Writer rather than using raw HTTP. Treat it as unavailable only after searching the tool catalog for a capability name as a substring and finding nothing — not because a guessed full tool name failed to match.

## Inputs

Use the active ticket or Workspace context to identify the UPDATE item. If the context is absent, ask the PM for the ticket or article they want to update, then resolve the underlying Workspace and item yourself. Never ask the PM for internal IDs or item keys.

## Resolve candidates

1. Call `discover_article_targets` to list server-resolved candidates.
2. Present candidates as a numbered PM-readable shortlist, best match first. For each candidate show: title, canonical URL, why it matched (in plain language), and what the update would touch. Mark the single best candidate as the recommendation, but do not pre-select it.
3. If no candidates are returned, say so plainly and ask the PM for a URL or external ID. Call `resolve_article_target` with that reference and show the resolved target as the only candidate.

## Confirmation gate

Pause and wait for the PM's explicit choice before any binding call. Accept: a candidate number, a candidate title, an explicit URL, "cancel", or an edited candidate list. Do not proceed on silence, on "looks good" without a selection, or on the assumption that the top-ranked candidate is acceptable.

## Bind explicitly

After the PM explicitly picks one candidate, restate the binding ("把《<item 标题>》关联到 <文章标题>") and only then call `select_update_target` with the current Manifest, selected target, and idempotency values.

Never bind a target without the PM's explicit selection. Never pick the top-ranked candidate automatically.

## Verify

After binding, confirm the item is ready. Reply with the selected article, what will be updated, and the next action. Do not expose internal identifiers, status fields, versions, API paths, or request parameters unless the PM asks for technical detail.
