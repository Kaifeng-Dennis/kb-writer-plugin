---
name: kb-writer
description: Use when a PM has an ambiguous KB Writer or RingCentral product-work request and does not know which focused KB Writer skill to start with.
---

# KB Writer

Route the request to the focused skill that owns its workflow. This is an
entry point, not a separate workflow and not a runtime sub-skill caller:
adopt the selected skill's complete instructions before acting. Do not repeat
its usage tracking preflight; the selected skill owns it.

## Route the requested outcome

| Request | Focused skill |
| --- | --- |
| Install, sign in, configure, or update the plugin | `setup` |
| Jira key, KB ticket, ticket/workspace status, drafting, review, or publication | `kb-ticket` |
| Turn a completed local coding session into KB work | `create-kb-intent`; this creates or resumes planning, while drafting remains a later explicitly approved action |
| Explicit active-workspace action | `check-kb-status`, `select-kb-target`, `approve-kb-manifest`, `review-kb-draft`, `publish-kb-draft`, or `review-related-kb-articles`, according to the action |
| PRD, codebase behavior, feasibility, competitor research, analytics tracking, feature gating, or TestIt evidence | The matching `pm-*` skill or `testit-features` |

If a Jira key supports a PM-analysis request rather than a KB workflow action,
route to the PM skill and treat the key as context. For multiple independent
outcomes, use the stated order and complete independent read-only checks before
stopping at the first focused skill's mutation confirmation. Ask about order
only when the outcomes conflict or it is absent and material. If no route is
clear, ask one concise question about the desired outcome. Do not ask for
internal identifiers the PM has not provided.

## Preserve workflow boundaries

Use read-only state only to choose the route. The focused skill owns every
write and its confirmation: workspace creation, Manifest edits, draft start,
review decisions, and publication. Never infer authorization from a request to
check status or prepare a draft.

For follow-up work, use the persisted identity returned by the backend. Jira
keys, titles, URLs, and user wording are discovery or display signals, not a
substitute for a Workspace, Manifest item, Work Item, or Draft identity.

Reply in PM language: state the outcome, what it means, and one next action.
Do not expose internal IDs, lifecycle codes, version tokens, API paths, or MCP
implementation detail unless the PM requests technical detail.
