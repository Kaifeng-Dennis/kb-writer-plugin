---
name: select-kb-target
description: Resolve and bind the target KB article for a Manifest UPDATE item in a KB Writer Intent Workspace. Use when a workspace has UPDATE items blocked on missing_target and the PM needs to pick the article to update.
---

# Select KB target

Bind one Manifest UPDATE item to a server-resolved article target. The backend owns article search, target resolution, and revalidation; this skill only orchestrates the PM's explicit choice.

**Core contract:** recommend, then confirm. Never ask the PM to type an article ID from memory; always show server-resolved candidates first and let the PM pick from the list (or supply an explicit URL when nothing matches). Never bind silently.

## Usage tracking preflight

Call `track_skill_usage` on the KB Writer MCP server at startup with `"skill_name": "select-kb-target"`. Use `skill_version` `0.3.0+codex.20261014000000` and `source_app` `codex` in Codex, or `skill_version` `0.2.31` and `source_app` `claude_code` / `claude_cowork` in Claude Code / Cowork respectively. Match the capability name regardless of the MCP namespace prefix. This preflight is non-blocking: if the tool is unavailable or fails, continue normally without retrying or using a shell/HTTP fallback. Never expose tracking results, identity, credentials, or errors to the PM.


## Connectivity

Requires the KB Writer MCP server, whether it comes from the plugin's own `kb-writer` entry or from the KB Writer MCP desktop extension that Cowork sessions rely on. The extension's tools carry a different namespace prefix, so match on the capability name and ignore the prefix. MCP is required for state-changing operations: if it is unavailable, stop and ask the PM to connect KB Writer rather than using raw HTTP. Treat it as unavailable only after searching the tool catalog for a capability name as a substring and finding nothing — not because a guessed full tool name failed to match.

## Inputs

Use the active ticket or Workspace context to identify the UPDATE item. If the context is absent, ask the PM for the ticket or article they want to update, then resolve the underlying Workspace and item yourself. Never ask the PM for internal IDs or item keys.

## Resolve candidates

1. Call `discover_article_targets` to list server-resolved candidates for this UPDATE item.
2. Present candidates as a numbered PM-readable shortlist, best match first. For each candidate show title, canonical URL, and a source-grounded reason it matches. Show an impact summary only when the server returned one; otherwise say the affected content needs review.
3. If no candidates are returned, say so plainly and ask the PM for a URL or external ID. Call `resolve_article_target` with that reference and show the resolved target as the only candidate.

This is item-level target discovery. For ticket-level semantic suggestions of articles that may need a new UPDATE task, use `review-related-kb-articles`.

## Confirmation gate

Pause and wait for the PM's explicit choice before any binding call. Accept: a candidate number, a candidate title, an explicit URL, "cancel", or an edited candidate list. Do not proceed on silence, on "looks good" without a selection, or on the assumption that the top-ranked candidate is acceptable.

## Bind explicitly

After the PM explicitly picks one candidate, restate the binding ("把《<item 标题>》关联到 <文章标题>") and only then call `select_update_target` with the current Manifest, selected target, and idempotency values.

Never bind a target without the PM's explicit selection. Never pick the top-ranked candidate automatically.

## Verify

After binding, confirm the item is ready. Reply with the selected article, what will be updated, and the next action. Do not expose internal identifiers, status fields, versions, API paths, or request parameters unless the PM asks for technical detail.
