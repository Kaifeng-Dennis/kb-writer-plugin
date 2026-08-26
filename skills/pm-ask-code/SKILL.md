---
name: pm-ask-code
description: Use when a PM wants standalone PM-friendly codebase answers using qa_codebase, including follow-ups, functional logic, change impact, and diagnosis.
---

# PM Ask Code

Answer PM codebase questions with remote codebase analysis, then explain the result in the form the PM actually needs. This is a standalone Q&A skill, not a PRD writer, feasibility workflow, TestIt lookup, Jira creator, or code implementation tool.

**The core contract of this skill:** stay PM-friendly without forcing every answer into a delivery-plan template.

- When the PM asks about **code logic, feature logic, a feature flag, a click flow, or "all logic"**, the main answer must explain functional behavior: what the user/system does, what controls it, defaults, branches, fallbacks, and visible outcomes. Do not add "Suggested Next Steps" unless the user asks what to do next or there is a concrete blocking action.
- When the PM asks about **whether to change something**, answer in decision terms: scope, owner, risk, dependencies, rollout, and next steps.
- When the PM asks **why something behaves a certain way**, answer as a diagnosis: expected vs unexpected behavior, trigger condition, root cause, and owner/workaround when relevant.

Raw implementation detail is supporting evidence and lives only in the appendix.

## Start

1. Treat the current conversation as one code Q&A workspace.
2. Read `references/qa-codebase.md`.
3. Read `references/output-examples.md` before writing your first answer in a conversation. It contains good/bad output patterns, especially for functional logic questions.

Load reference files with a file read, not by printing them through the shell, and never echo their contents back into the conversation.
4. Parse the PM's question, project/product surface, and any Jira, Confluence, or wiki context.
5. Classify the question (see Question Triage below) — this determines the output template and appendix depth.
6. If Jira, Confluence, or wiki links are present and MCP is available, gather concise context before asking the codebase question. If MCP is unavailable, ask the PM to paste the key content and continue with lower confidence.
7. Follow the dynamic registry and packaged fallback flow in `references/qa-codebase.md` when the user names a project, product surface, product line, or alias.

## Question Triage

Classify each question into one of three types. The type determines the main output template.

| Type | Signals | Appendix depth |
|---|---|---|
| **A. Functional logic** — "how does X work", "what happens when the user clicks Y", "tell me all the logic of Z" | Wants understanding of behavior | Full flow walkthrough allowed in appendix |
| **B. Change assessment** — "can we change X", "what if we raise the limit", "how hard is it to add Y" | Wants effort/impact of a change | Appendix limited to the touched components only |
| **C. Behavior diagnosis** — "why does it behave like this", "customer reports X, is it expected" | Wants root cause + whether it's by design | Appendix limited to the decision point in code |

Type A is the default for feature flag, config, gating, and "all logic" questions unless the user explicitly asks for effort, change feasibility, or roadmap implications.

## Codebase Lookup

Use `https://agent-cli-platform.int.rclabenv.com/qa_codebase` for supported projects only.

Before every API call, including follow-ups, complete the Codebase Project Confirmation Gate in `references/qa-codebase.md`:

1. Resolve recommended codebase projects from the active registry.
2. Show recommended codebase projects and all available codebase projects as `display_name` only.
3. Pause for the PM to confirm, edit using registry `display_name` values, or cancel.
4. Map confirmed `display_name` values to `codebase_project` for the API `project_list`.
5. Do not reuse a previous confirmation even if the recommended list is unchanged.

Only after the PM confirms or edits the list, send a short user-facing update:

> I am checking the codebase now. This lookup can take up to 12 minutes, so please wait while the codebase analysis completes.

Then call the API with:

```json
{
  "question": "<PM question plus relevant conversation context>",
  "project_list": ["<confirmed codebase_project values>"],
  "async": false
}
```

**Enrich the question before sending it.** Append instructions to the `question` field so the codebase agent surfaces PM-relevant facts. For Type A, ask for: user-visible behavior, trigger/entry points, gate order, feature flags, config values, permissions, defaults, null/empty handling, fallback paths, local vs remote config, and hard-coded constants. For Type B/C, also ask for owners, risks, dependencies, and likely change impact.

Use a 720 second wait budget. Do not treat the API as unavailable before 12 minutes unless it returns an explicit error.

For cross-surface questions, resolve each selected surface against the active registry, combine the confirmed `codebase_project` values into one `project_list`, and send a single `qa_codebase` request. Do not invent aggregate project keys.

If the project is absent from the active registry source, unclear, or the PM cancels codebase project confirmation:

- Do not call `qa_codebase`.
- Ask the PM to choose from the projects returned by the active registry source when a project choice is required.
- If enough non-code context exists, answer only with clear limitations and low technical confidence.

## Follow-Up Questions

For PM follow-ups in the same conversation, continue using `qa_codebase` when the follow-up asks for any new codebase evidence, deeper validation, another module, another scenario, cross-project comparison, dependency check, or implementation implication.

Only answer from the existing result without another API call when the follow-up is purely asking to rephrase, summarize, translate, or format information already returned.

When calling the API for a follow-up, re-run the Codebase Project Confirmation Gate first, then include the relevant prior findings and the new question in the `question` field so the codebase answer has continuity.

## Output Templates

Return PM-readable Markdown. Choose the template that matches the question type.

**Hard rule for every body section:** no file paths, no class/component/function names, no code identifiers. Translate everything into product language ("the frontend message module", "a backend license parameter", "a hard-coded frontend limit"). Code identifiers are only allowed inside Technical Appendix.

### Type A: Functional Logic Template

Use this for "how does it work", "tell me the logic", feature flag, config, gating, and click-flow questions. Do **not** include Suggested Next Steps by default.

### 1. Answer

One short paragraph that answers the functional question directly: what behavior exists, what controls it, and what happens in the main on/off/default cases.

### 2. Functional Logic

Explain the behavior in product terms:

| Step / Condition | Behavior |
|---|---|
| Entry point | What starts the flow |
| Main path | What happens when the control is available/on |
| Off / unavailable path | What happens when the control is off, empty, or unavailable |
| Error / fallback path | What happens when retrieval or dependency fails |

Use only rows that apply. Keep the wording PM-readable.

### 3. Functional Controls

List every control, default, and hard-coded value that changes behavior:

| Control | Current value / default | Type | Controls what |
|---|---|---|---|
| e.g. Feature flag | On/off or fetched value | FFS/config | Entry visibility or behavior |
| e.g. Local default | Empty string / true / false | Hard-coded default | Fallback behavior |
| e.g. License gate | Service parameter | Entitlement | Who can use it |

If no control exists, say that explicitly. If a value is unknown because live config was not queried, mark it as "not confirmed by codebase analysis."

### 4. Key Branches

Call out the branches that matter for product behavior, such as logged-in vs logged-out, Web vs Desktop, feature flag present vs null, permission granted vs denied, or local cache vs remote fetch. Use bullets or a compact table.

### 5. Unknowns / Limits

Only include real unknowns that affect the answer, such as live production config values, remote rollout audience, or unresolved fallback ownership. Do not add generic "next steps."

### 6. Confidence & Sources

- Product confidence and technical confidence, each with one-line justification.
- Sources: Jira keys, Confluence page titles/URLs, codebase analysis task ID.
- Never claim high technical confidence if the API failed, timed out, or was not called.

### 7. Technical Appendix

The only place for: step-by-step code flow, component/class/file names, API endpoints, event names, analytics event names, error-handling specifics. Keep it scannable; do not dump raw API JSON, raw MCP output, or long code excerpts unless the user explicitly asks for debugging.

### Type B: Change Assessment Template

Use this when the user asks whether something can change, how hard it is, what would be impacted, or what a requirement implies.

1. **Answer**
2. **Levers & Owners** table: configurable values, hard-coded values, owner boundary, change path
3. **PM Decision Impact**: scope, delivery risk, dependencies, rollout/launch, packaging/licensing implications
4. **Unknowns**
5. **Suggested Next Steps** by role, only where there is a real action
6. **Confidence & Sources**
7. **Technical Appendix**

### Type C: Behavior Diagnosis Template

Use this when the user asks why something happened, whether it is expected, or how to explain a reported behavior.

1. **Answer**
2. **Expected vs Actual**
3. **Trigger Conditions**
4. **Root Cause / Control Logic**
5. **User Impact and Workaround** (only if relevant)
6. **Confidence & Sources**
7. **Technical Appendix**

## Self-Check Before Sending

Before returning the answer, verify:

1. Does any file path or code identifier appear outside Technical Appendix? Move it to the appendix or translate it.
2. For Type A, did the answer clearly cover functional behavior, controls/defaults, and key branches? If not, rewrite.
3. For Type B, is the Levers & Owners table present and non-trivial? If missing, the answer is incomplete.
4. Did you avoid Suggested Next Steps for Type A unless the user asked for next actions or a concrete action is required?
5. Is the technical detail more than ~40% of total length? Trim the appendix.

## Rules

- Use PM-friendly language. For Type A, translate implementation details into functional behavior and controls. For Type B/C, translate implementation details into product scope, dependency, risk, launch, and owner impact.
- Do not dump raw API JSON, raw MCP output, long code excerpts, or raw command output unless the user explicitly asks for debugging.
- Do not claim high technical confidence if the API fails, times out, or was not called.
- Do not ask PMs to answer implementation-only questions. Assign those to Engineering, Agent, or Codebase Analysis.
- Do not use TestIt automation; direct QA coverage questions to `testit-features`, `pm-prd`, or `pm-feasibility-check`.
- Do not create PRDs, Jira tickets, or code changes.
- Answer in the language the PM used (e.g., Chinese question -> Chinese answer), and keep the selected template's section structure.
