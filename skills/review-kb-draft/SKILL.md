---
name: review-kb-draft
description: Review a generated KB draft, assign a content owner, submit for content review, approve for publish, or return to PM review. Use when a work item has a draft ready and the PM needs to drive the review workflow.
---

# Review KB draft

Drive the content review workflow for one work item. All state transitions use the work item's current `version` as the CAS token.

## Connectivity

Requires `KB_WRITER_API_BASE_URL` and `KB_WRITER_BEARER_TOKEN` in the environment. If the `kb-writer` MCP server is registered, prefer its tools over raw HTTP.

## Inspect

1. Call `GET /v1/intent-workspaces/{workspaceId}/tasks` to list work items with their status, version, and draft ID.
2. For items with a draft, call `GET /v1/intent-workspaces/drafts/{draftId}` to show the draft content, title, and version.
3. Present the draft to the PM. Do not summarize or truncate the content; show it in full or provide a clear way to expand it.

## Act

Ask the PM which action to take, then call the matching endpoint. All calls use `Idempotency-Key` header and `expectedWorkItemVersion` in the body:

- **Assign content owner**: `POST /v1/intent-workspaces/tasks/{workItemId}/assign-content-owner` with `{"expectedWorkItemVersion": <version>, "ownerIdentity": "<identity>"}`
- **Submit for content review**: `POST /v1/intent-workspaces/tasks/{workItemId}/submit-content-review` with `{"expectedWorkItemVersion": <version>}`
- **Approve for publish**: `POST /v1/intent-workspaces/tasks/{workItemId}/approve-content-for-publish` with `{"expectedWorkItemVersion": <version>}`
- **Return to PM review**: `POST /v1/intent-workspaces/tasks/{workItemId}/return-to-pm-review` with `{"expectedWorkItemVersion": <version>, "reason": "<reason>"}`

After each action, report the new `version` from the response. The PM needs it for the next action.

## Edit draft

If the PM wants to edit the draft content before review, call:

```bash
curl -sS -X PATCH "$KB_WRITER_API_BASE_URL/v1/intent-workspaces/drafts/{draftId}" \
  -H "Authorization: Bearer $KB_WRITER_BEARER_TOKEN" \
  -H "Content-Type: application/json" \
  -H "Idempotency-Key: <key>" \
  -d '{"expectedVersion": <draftVersion>, "content": {"markdown": "<new content>"}}'
```

The response returns the new draft `version`.
