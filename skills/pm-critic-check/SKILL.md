---
name: pm-critic-check
description: Use when a PM wants a standalone critic review of an existing PRD with Jira/Confluence context, optional product-line rule checks, and PM-readable open issues.
---

# PM Critic Check

Run a standalone diagnostic review. Do not rewrite the whole PRD unless the user asks to convert into the full `pm-prd` workflow.

## Diagnostic Review

1. Read `references/mcp.md`, `references/projects.md`, `references/schemas.md`, and `references/critic-rules.md`. Load reference files with a file read, not by printing them through the shell, and never echo their contents back into the conversation.
2. Treat the current conversation as the standalone review workspace. Do not create, resume, or export separate local workflow state.
3. If the PM asks to create, edit, delete, or manage Product-Line Rules, direct them to `https://agent-cli-platform.int.rclabenv.com/product_line_rules`. This skill consumes rules already configured in Agent CLI Platform; it does not create or edit rules.
4. When Product-Line Rules may be useful for the review, request metadata from `https://agent-cli-platform.int.rclabenv.com/api/product-line-rules/metadata`. If metadata returns no available rules, continue the review immediately using the agent's own PRD critic knowledge and general critic checks; set `product_line_rules` to an empty list and do not pause for rule selection. If metadata returns one or more available rules, show the available General and Personal rules to the PM, pause the conversation, and wait for the PM to choose rule names before continuing the review. After the PM selects rules, request details from `https://agent-cli-platform.int.rclabenv.com/api/product-line-rules/resolve` with `{"rule_names": [...]}` and store the returned active rules in `product_line_rules`. If the API is unavailable, continue with general critic checks only and state the limitation.
5. When the input names a project or product surface, follow `references/projects.md` to fetch the dynamic registry, use its packaged fallback if necessary, and resolve project context before codebase or TestIt lookup. Before any `qa_codebase` call, run the Codebase Project Confirmation Gate: show recommended codebase projects and all available codebase projects as `display_name` only, pause for confirm/edit/cancel, map confirmed names to `codebase_project`, and continue only with the confirmed list.
6. Gather MCP context for Jira, Confluence, wiki if present.
7. If `project_context.supported` is true and `confirmation_status` is `confirmed`, run `prompts/code_context.md` with `qa_codebase` before critic review. Use `project_context.confirmed_project_list` for `project_list`. Re-run the Codebase Project Confirmation Gate before every `qa_codebase` request, including follow-ups.
8. If `project_context.supported` is true and the PRD has a proposed solution, acceptance criteria, technical claim, dependency, or implementation-facing requirement, run `prompts/tech_check.md` using the PRD's proposed behavior as the implicit selected direction.
9. If `project_context.testit_supported` is true, `project_context.testit_project` is non-empty, and the PRD contains QA coverage, acceptance criteria, TestIt, or case-impact claims, use the `testit-features` skill with `project_context.testit_project` and run `prompts/testit_case_impact.md` before critic review.
10. If the project is unsupported or unknown, or the PM cancels codebase project confirmation, do not call `qa_codebase` or `testit-features`; keep the review going and mark automated codebase/TestIt context unavailable. If the project supports CodeAsk but not TestIt artifacts, run codebase checks normally after confirmed projects, skip `testit-features`, and state that the TestIt artifact has not been synced.
11. Run `prompts/critic_review.md` with missing workflow fields set to empty objects.
12. Output findings, readiness results, mandatory section results, open issues, confidence, and limitations.

## Rules

- Diagnostic only by default.
- For supported projects, technical confidence should reflect the gathered codebase context and tech check. If codebase analysis fails or is unavailable, downgrade technical confidence and explain the limitation.
- Missing problem frame, scenario map, feasibility check, or reusable pattern check must be named in limitations.
- Missing automated TestIt context must be named in limitations when QA case impact is relevant but unsupported, unknown, unavailable, or not synced. Do not describe a CodeAsk-supported project as unsupported merely because its TestIt artifact is unavailable.
- Final response should be directly usable by a PM who may not know implementation details.
- Lead with PM decision impact: what is strong enough to keep, what PM-owned decision is still missing, what risk affects scope/timeline/launch, and what can be handed to Engineering.
- Translate technical findings into product language. Use file paths, modules, APIs, classes, and config names only as supporting evidence when they help Engineering follow up.
- Summarize Jira, Confluence, and codebase findings. Do not return raw MCP/API responses.
- Every open issue or question should include an owner and whether PM action is required.
- Technical open questions should be assigned to Engineering, Agent, or Codebase Analysis unless they require a PM product decision.
- QA case coverage questions should be assigned to QA unless they require a PM product scope decision.
- If the PRD claims codebase or TestIt validation without evidence, flag it as an unverified claim.
