# Project Registry

The PM Toolkit project registry is loaded dynamically from Agent CLI Platform. Do not maintain a project or TestIt mapping table in this skill.

## Source Order

1. Request `GET https://agent-cli-platform.int.rclabenv.com/api/pm-toolkit/projects`.
2. Use a 5-second timeout and retry once.
3. Accept only a JSON object with `schema_version: 1` and a non-empty `projects` array.
4. If the request fails, returns invalid JSON, or uses an unsupported schema, load `references/project-registry-fallback.json` from the installed skill package. In a source checkout, the canonical build-time snapshot is `skills/_shared/project-registry-fallback.json`.
5. Record whether project context came from `api` or `fallback_snapshot`. Do not expose raw registry responses or network errors to the PM.

The fallback snapshot is generated from the API and must not be edited by hand. When it is used, CodeAsk may continue for projects present in the snapshot. If TestIt is used, state that the TestIt mapping came from a fallback snapshot and may be stale.

## Resolution Rules

- Match confirmed PM input against `project_id` and `aliases` case-insensitively using exact normalized strings.
- Do not use fuzzy matching to silently select a project. When more than one project is plausible, ask the PM to choose from the registry results.
- Construct `project_context` from the matched object:

```json
{
  "supported": true,
  "project_id": "<project_id>",
  "codebase_project": "<codebase_project>",
  "testit_supported": true,
  "testit_project": "<testit_project-or-empty-string>",
  "display_name": "<display_name>",
  "unavailable_reason": "",
  "registry_source": "api | fallback_snapshot",
  "recommended_project_list": ["<codebase_project>"],
  "available_project_list": ["<all codebase_project values from active registry>"],
  "confirmed_project_list": [],
  "confirmation_status": "pending | confirmed | cancelled | unavailable"
}
```

- Call `qa_codebase` only after the Codebase Project Confirmation Gate below succeeds, using the confirmed `codebase_project` values in `project_list`.
- Call `testit-features` only when `testit_supported` is true and `testit_project` is non-empty.
- If no registry entry matches, do not guess and do not call CodeAsk or TestIt. Continue the PM workflow with technical/QA confidence lowered and an owner-specific follow-up.
- For cross-surface questions, resolve each selected surface against the active registry, combine the confirmed `codebase_project` values into one `project_list`, and send a single `qa_codebase` request. Do not invent aggregate project keys.

## Codebase Project Confirmation Gate

Before every `qa_codebase` request, including follow-ups in the same conversation, run this gate. Do not reuse a previous confirmation even when the recommended list is unchanged.

1. Build `recommended_project_list` from the currently matched registry `codebase_project` values (one or more for cross-surface questions).
2. Build `available_project_list` from every `projects[].codebase_project` in the active registry source (`api` or `fallback_snapshot`). Never hard-code the list.
3. Show the PM a friendly Markdown confirmation that includes:
   - Recommended codebase projects as `display_name` only
   - All available codebase projects from the active registry as `display_name` only
4. Ask the PM to choose one of: use the recommended list, modify the list (add/remove/replace using only active-registry `display_name` values), or cancel the codebase lookup.
5. Pause the conversation and wait for the PM's next message. Write the confirmation in Markdown and end the turn. Do not call `qa_codebase` in the same turn as the confirmation request.
6. After the PM confirms or edits, map the accepted `display_name` values back to registry `codebase_project` values, set `confirmed_project_list`, set `confirmation_status` to `confirmed`, and only then send the 12-minute wait notice and call `qa_codebase`.
7. If the PM cancels, leaves the list empty, picks a value absent from the active registry, or the registry has no usable projects, set `confirmation_status` accordingly, do not call `qa_codebase`, lower technical confidence, and continue with available non-code evidence plus Engineering/Codebase Analysis follow-up.

In the confirmation UI, show only `display_name`. Do not show `codebase_project` or `project_id`; keep those for internal mapping to `project_list`.

Example confirmation shape:

```markdown
### Codebase project confirmation

Recommended codebase projects for this lookup:
- Jupiter

All available codebase projects (from current registry):
- Jupiter
- ...

Waiting for PM input: reply with "confirm", an edited list of display names from the list above, or "cancel".
```

## Registry API Contract

Each project object contains only PM-facing routing data:

```json
{
  "project_id": "fiji",
  "display_name": "Jupiter",
  "description": "FIJI is the Jupiter desktop/web application.",
  "aliases": ["fiji", "jupiter", "jupiter web", "jupiter-web"],
  "codebase_project": "fiji",
  "testit_supported": true,
  "testit_project": "jupiter"
}
```

An absent TestIt artifact is represented by `testit_supported: false` and `testit_project: null`. This does not make CodeAsk unsupported.
