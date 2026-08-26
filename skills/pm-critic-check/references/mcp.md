# MCP And Context Reference

Use configured MCP tools whenever available. If a tool is unavailable or authentication fails, ask the PM to paste the relevant artifact and continue with reduced confidence.

Never return raw MCP tool JSON or unprocessed API output to the PM. Convert Jira, Confluence, registry, and codebase findings into a concise PM-readable synthesis with sources, confidence, and remaining owner-specific questions.

## Atlassian

Use Jira MCP for Jira issue keys, existing requirement tickets, comments, status, labels, components, and linked issues.

Use Confluence MCP for `wiki.*` URLs, URLs containing `/wiki/` or `/pages/<page_id>`, and existing PRD or product spec pages.

Extract and synthesize the problem statement, prior decisions, scope, open questions, linked artifacts, customer/user pain, constraints, dependencies, launch timing, and PM/EM/Designer comments. Preserve issue keys and page URLs as sources. Do not paste raw fields, full tool responses, or long page excerpts.

Technical details that do not need PM action belong to Engineering or Codebase Analysis rather than the PM.

## Project Resolution

Read `references/projects.md` before any codebase or TestIt lookup. It defines the dynamic registry endpoint, exact alias matching, the packaged fallback snapshot, the Codebase Project Confirmation Gate, and safe failure behavior.

Do not reproduce or infer a supported-project list in this file. Build `project_context` only from a validated registry API response or the packaged fallback snapshot.

## Codebase Analysis

Endpoint:

```text
https://agent-cli-platform.int.rclabenv.com/qa_codebase
```

Use `"async": false`. Before every call, including follow-ups, complete the Codebase Project Confirmation Gate in `references/projects.md`: show recommended codebase projects and all available codebase projects as `display_name` only, pause for PM confirm/edit/cancel, then map confirmed names to `codebase_project` and proceed only with the confirmed list. Only after confirmation, tell the PM the lookup can take up to 12 minutes and configure a 720-second wait budget.

Use `project_context.confirmed_project_list` as the `project_list` value. For a cross-surface question, resolve each selected surface against the active registry, combine the confirmed `codebase_project` values into one `project_list`, and send a single `qa_codebase` request. Do not invent aggregate project keys or call `qa_codebase` with an unconfirmed recommendation.

Example:

```bash
curl -X POST "https://agent-cli-platform.int.rclabenv.com/qa_codebase" \
  -H "Content-Type: application/json" \
  -d '{"question": "How is login implemented?", "project_list": ["fiji"], "async": false}'
```

Codebase synthesis rules:

- Ask product-relevant implementation questions about existing behavior, affected modules, reusable patterns, constraints, analytics hooks, configuration, permissions, or backend dependencies.
- Summarize the returned `result`; do not expose raw JSON unless debugging was explicitly requested.
- Translate findings into scope, delivery risk, dependencies, launch considerations, and non-PM open issues.
- If the API fails or reaches the documented wait limit, continue with technical confidence low.
- Do not require PMs to clone supported repositories and do not modify code during PM workflows unless implementation was explicitly requested.

## TestIt / QA Case Context

Use `testit-features` only when the resolved `project_context.testit_supported` is true and `project_context.testit_project` is non-empty. Pass `project_context.testit_project` as the artifact `--project` value.

If CodeAsk is supported but TestIt is unavailable, continue codebase analysis and describe only the missing TestIt artifact; do not label the whole project unsupported.

When `registry_source` is `fallback_snapshot`, mention that the TestIt mapping may be stale.

TestIt synthesis rules:

- Use `impact-candidates` for Jira keys, feature names, requirement phrases, and core scenarios.
- Use `coverage-matrix --fetch-full --full-candidate-max 2` for scenario or acceptance-criteria checks.
- A no-match is missing evidence, not proof of no impact.
- Convert results into affected cases, related unaffected cases, and missing coverage; assign missing coverage to QA unless a PM scope decision is required.
