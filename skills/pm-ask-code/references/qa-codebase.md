# QA Codebase Reference

## Project Registry

Before deciding whether CodeAsk is supported, request:

```text
GET https://agent-cli-platform.int.rclabenv.com/api/pm-toolkit/projects
```

Use a 5-second timeout and retry once. Accept only a JSON object with `schema_version: 1` and a non-empty `projects` array.

If the request fails, returns invalid JSON, or uses an unsupported schema, load `references/project-registry-fallback.json` from the installed package; in a source checkout use `skills/_shared/project-registry-fallback.json`. Record `registry_source: fallback_snapshot`; do not expose raw registry data or errors to the PM.

Match PM input against `project_id` and `aliases` case-insensitively using exact normalized strings. Build `project_context` from `project_id`, `display_name`, and `codebase_project`. If no project matches, do not guess or call CodeAsk.

For cross-surface questions, resolve each selected surface against the active registry, combine the confirmed `codebase_project` values into one `project_list`, and send a single `qa_codebase` request. Never invent aggregate project keys.

## Codebase Project Confirmation Gate

Before every `qa_codebase` request, including follow-ups in the same conversation, complete this gate. Do not reuse a previous confirmation even when the recommended list is unchanged.

1. Build `recommended_project_list` from the matched `codebase_project` values.
2. Build `available_project_list` from every `projects[].codebase_project` in the active registry source.
3. Show the PM recommended codebase projects and all available codebase projects as `display_name` only.
4. Ask the PM to confirm, edit the list using only active-registry `display_name` values, or cancel.
5. Pause and wait for the PM's next message. Do not call `qa_codebase` in the same turn as the confirmation request.
6. After confirmation or edit, map accepted `display_name` values to `codebase_project`, set `confirmed_project_list`, and set `confirmation_status: confirmed`. Only then send the 12-minute wait notice and call CodeAsk.
7. If the PM cancels, leaves the list empty, or picks a value absent from the active registry, do not call CodeAsk; lower technical confidence and continue with available non-code evidence.

In the confirmation UI, show only `display_name`. Do not show `codebase_project` or `project_id`.

## CodeAsk Request

Endpoint:

```text
POST https://agent-cli-platform.int.rclabenv.com/qa_codebase
```

Use `"async": false`; allow up to 720 seconds. Call only after the Codebase Project Confirmation Gate succeeds. Capture the task ID when present.

```json
{
  "question": "<enriched PM question>",
  "project_list": ["<confirmed codebase_project values>"],
  "async": false
}
```

Use `confirmed_project_list` as `project_list`. Use the returned `result` as evidence. Do not expose raw JSON unless debugging was explicitly requested.

## Question Enrichment

Never send the PM question without context. Append the relevant parts of this discovery block:

```text
In addition to answering the question above, also identify:
1. Behavior controlled by feature flags, service parameters, remote config, or
   configurable constants, including names and current/default values.
2. Relevant hard-coded values, fixed limits, and where they are owned.
3. The service, module, or layer that owns each component.
4. License, permission, or entitlement gates.
5. Rate limits, caps, fallbacks, and degraded paths.
```

For follow-ups, prepend a concise summary of prior findings before the new question and enrichment block.

## Good Questions

Ask about existing behavior, likely affected modules, reusable patterns, technical constraints, backend/config/permission/analytics dependencies, cross-surface differences, configurable versus hard-coded behavior, and owner boundaries.

## Failure Handling

If the registry and fallback do not resolve the project, codebase project confirmation was cancelled, or CodeAsk fails or times out:

- Do not guess.
- State what could not be validated and set technical confidence low.
- Assign implementation validation to Engineering, Agent, or Codebase Analysis.
- Do not ask the PM to resolve implementation-only unknowns.
- Preserve the output template and mark unvalidated controls or owners clearly.
