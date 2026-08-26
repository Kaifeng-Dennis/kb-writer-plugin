---
name: pm-feasibility-check
description: Use when a PM wants a standalone feasibility check for a product problem or solution using codebase analysis, Jira/Confluence context, QA signals, and risk framing.
---

# PM Feasibility Check

Run a standalone code-grounded feasibility diagnostic. Do not implement code.

## Start

1. Read `references/mcp.md`, `references/projects.md`, and `references/schemas.md`. Load reference files with a file read, not by printing them through the shell, and never echo their contents back into the conversation.
2. Treat the current conversation as the feasibility workspace. Do not create, resume, or export separate local workflow state.
3. Parse the PM's problem/proposal, project clues, product surface, product line, and Jira/Confluence/wiki context.
4. If Jira, Confluence, or wiki links are present and MCP is available, gather concise context before finalizing the project guess. If MCP is unavailable, ask the PM to paste the relevant content and continue with lower confidence.

## Project Confirmation Gate

Resolve and confirm project context before any codebase or TestIt lookup.

1. Follow `references/projects.md` to fetch the dynamic registry or its packaged fallback, then infer the most likely project from explicit project names, returned aliases, product surfaces, and external context.
2. Build `recommended_project_list` from the matched `codebase_project` values and `available_project_list` from every registry `codebase_project`. Do not hard-code either list.
3. Pause and run the Codebase Project Confirmation Gate from `references/projects.md` before any `qa_codebase` call. Show recommended codebase projects and all available codebase projects as `display_name` only, and ask the PM to confirm, edit, or cancel. Example: `Recommended: Jupiter. Confirm, edit the display-name list, or cancel.`
4. After PM confirmation or edit, construct `project_context` from the matched registry object(s), set `confirmed_project_list`, and set `confirmation_status` to `confirmed`.
5. If no registry project matches, the PM cancels, or the confirmed list is empty/invalid, do not call `qa_codebase`, do not call `testit-features`, and do not run `prompts/code_context.md`, `prompts/tech_check.md`, or `prompts/testit_case_impact.md`. Return a PM-readable assessment with `feasibility: unclear`, low technical confidence, available Jira/Confluence/PM-input evidence, and Engineering/QA open issues for missing codebase/TestIt validation.

## Supported Project Flow

For supported projects with a confirmed `confirmed_project_list`:

1. Use `project_context.confirmed_project_list` for `qa_codebase project_list`. Re-run the Codebase Project Confirmation Gate before every `qa_codebase` request, including follow-ups.
2. Call `testit-features` only when `project_context.testit_supported` is true and `project_context.testit_project` is non-empty. Use `project_context.testit_project` as the `--project` value.
3. After codebase project confirmation succeeds, send a short user-facing update: `I am checking the codebase now. This lookup can take up to 12 minutes, so please wait while the codebase analysis completes.`
4. Run `prompts/code_context.md` as the single place that calls `https://agent-cli-platform.int.rclabenv.com/qa_codebase` with `"async": false`, the confirmed `project_list`, and a 720 second wait budget. Do not make a separate `qa_codebase` call from this SKILL before or after that prompt.
5. Run `prompts/tech_check.md` against the problem/proposed solution as the implicit selected direction.
6. When the TestIt gate is satisfied, query TestIt/Jenkins feature evidence with the `testit-features` skill, then run `prompts/testit_case_impact.md` to summarize QA impact and coverage signals. Otherwise, skip the lookup and state that the supported project's TestIt artifact has not been synced.
7. Return the PM-readable feasibility assessment first, then QA coverage signal, supporting related files/modules, dependencies, risks, non-PM technical unknowns, and limitations.

## Rules

- No code changes.
- If codebase context cannot be accessed, mark feasibility as `unclear`.
- If project context is unsupported or unknown, or codebase project confirmation was cancelled, do not attempt codebase/TestIt lookup and mark feasibility as `unclear`.
- If project context supports CodeAsk but not TestIt, run codebase analysis normally after confirmed projects and report QA case evidence as unavailable because the TestIt artifact has not been synced.
- Separate product uncertainty from technical uncertainty.
- Prefer precise file/module references over broad guesses.
- Summarize Jira, Confluence, and codebase API results for a PM. Do not return raw tool/API responses.
- Translate implementation findings into PM-facing meaning: delivery complexity, scope impact, cross-surface consistency, dependency owner, rollout risk, or launch decision. File paths/modules/APIs are supporting evidence, not the main answer.
- Assign each unknown to PM, Engineering, Design, Data, QA, Agent, or Codebase Analysis. PM-owned unknowns should require a PM product decision.
- Do not mark codebase context unavailable before the 720 second wait budget unless the API returns an explicit error.
- Use the registry flow and Codebase Project Confirmation Gate in `references/projects.md` as the supported project source of truth; do not infer support from a memorized list.
