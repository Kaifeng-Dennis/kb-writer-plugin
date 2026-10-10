---
name: review-related-kb-articles
description: Review the KB ticket's semantic suggestions for published articles that may need new UPDATE tasks. Use when the PM wants to inspect or act on related-article suggestions for a KB Writer ticket or Intent Workspace.
---

# Review related KB articles

Review the ticket-level semantic suggestions already persisted for this Workspace. These suggestions are advisory: they may identify articles worth reviewing, but never create a task or establish an UPDATE target by themselves.

## Usage tracking preflight

Before continuing, call the MCP tool `pm_toolkit_track` from the configured Atlassian MCP server with:

```json
{
  "skill_name": "review-related-kb-articles",
  "skill_version": "0.1.0+codex.20260923163000",
  "source_app": "codex"
}
```

If tracking is unavailable or fails, continue normally. Never surface tracking results or errors to the PM.

## Read suggestions

1. Resolve the active ticket to its Workspace when needed.
2. Call `get_related_article_suggestions` with the Workspace ID.
3. If `scan` is absent, say the ticket has not been scanned yet. Do not substitute item-level `discover_article_targets` results or invent a query.
4. If `scan.records` is empty, say the latest ticket-level scan found no matching published articles.
5. Otherwise show the ranked records as “可能需要更新的相关文章”. For each show title, URL, and a short matched excerpt when available. State that rank is advisory and do not display a score or claim the article must change.

## Add only after explicit selection

Wait for the PM to choose a candidate number, title, or URL. Do not add anything on “looks good” or silence.

After an explicit choice:

1. Call `add_related_article_suggestion` with the current Manifest ID and the selected suggestion's `key`.
   This server-side action uses only the persisted suggestion snapshot to create the stable target and add one `MANUAL` `UPDATE` item. Do not call `resolve_article_target`, `select_update_target`, or `add_manifest_item` for this flow.
2. Confirm the new item and its target title.
3. Confirm the new task and direct the PM to review the Manifest. Do not start drafting.

Never create a task for an already planned UPDATE target. Target resolution, task creation, approval, and drafting remain separate PM-confirmed actions.
