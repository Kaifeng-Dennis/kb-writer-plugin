# Workflow Reference

## Product Goal

Help PMs turn rough ideas, partial drafts, near-final PRDs, or solution-first proposals into structured, reviewable, developer-ready PRDs.

The agent is a product thinking partner, not a passive writer. It should challenge framing, surface gaps, and keep assumptions visible.

There is one workflow. Different inputs do not get different paths; they get different **stage plans** over the same set of stages.

Default PRD output is flexible Confluence-ready Markdown. The agent should choose the structure that best fits the input, product context, and handoff need instead of forcing a fixed template.

PM-facing output should lead with the agent's synthesized understanding, recommended next step, and clear choices. Questions are allowed only after the agent has used available artifacts and must identify owner and PM actionability.

When metric/data information is provided as text, tables, screenshots, or images, the agent should interpret what product problems the data suggests and summarize those insights for PM review before asking follow-up questions.

## Input Shapes And Typical Plans

These are starting points for the stage plan, not fixed paths. The agent proposes; the PM approves and edits.

| Input shape | Typical plan | Notes |
|---|---|---|
| Rough idea or low-completeness notes | Almost everything `generate`; `gap_analysis` is `not_applicable` | Nothing exists to verify |
| Partial draft or structured notes | Mixed. Sections present become `verify`; missing sections `generate` | Watch for escalation when a `verify` stage finds whole sections absent |
| Near-final PRD | Mostly `verify`; unrun checks such as pattern reuse and QA case impact stay `generate` | Best candidate for batch confirmation |
| Solution-first proposal | Problem frame and scope `verify` with high scrutiny; evidence often `generate`; direction `verify` with explicit challenge | The common failure is confirming a direction whose problem frame was never evidenced |

The fourth row deserves attention. A solution-first proposal usually arrives with no evidence, and `problem_framing` caps priority at medium without evidence and at low with none. Run `evidence_capture` before verifying the problem frame, or the frame verification has nothing to judge against.

## Stage Model

Twelve stage atoms plus `code_context` as a shared resource. Groups are a presentation aid only and **do not trigger pauses**.

| Group | Stages |
|---|---|
| Diagnose | `parse_input`, `clarify`, `gap_analysis` |
| Build | `evidence_capture`, `problem_framing`, `scope_expansion`, `solution_options` |
| Validate | `tech_check`, `pattern_reuse`, `testit_case_impact` |
| Draft and review | `draft_prd`, `critic_review`, final handoff |

`code_context` sits outside the groups as an on-demand shared resource, at the same level as project registry resolution.

## Dependency Order

- `problem_framing` depends on input understanding and evidence, and runs **before** `scope_expansion`.
- `scope_expansion` depends on an approved problem frame.
- `solution_options` depends on confirmed scope.
- `tech_check` and `testit_case_impact` depend on a stable selected direction.
- `draft_prd` depends on approved scope, approved problem frame, and a selected direction.

Approval chain: **problem frame → scope → direction → final PRD.** Forward-only. A later approval never invalidates an earlier one.

Confirming scope before the problem frame is approved is a known failure: `problem_framing` explicitly offers the PM `narrow` and `reframe`, either of which would void a scope that was already locked.

## Scale

Scale is a second, independent dimension of the stage plan. Stage mode answers whether the work has already been done; scale answers whether the work is worth doing for a request of this size. Without scale, a button copy change and a new transcription feature receive the same plan.

`references/scale-rules.md` is authoritative. Four tables: H locks high and cannot be downgraded, S suggests high and the PM may downgrade, L lists conditions that must all hold for low, D lists contexts that disqualify low. Medium is the default and the normal answer.

Scale effect on stage depth:

| Stage | Low | Medium | High |
|---|---|---|---|
| `evidence_capture` | not done | lightweight | full |
| `problem_framing` | minimal | full | full |
| `scope_expansion` | minimal | full | full |
| `solution_options` | not done | may be skipped when direction is singular | required |
| `pattern_reuse` | not done | as needed | required |
| `tech_check` | lightweight | full | full |
| `testit_case_impact` | required | required | required |
| `draft_prd`, `critic_review`, final handoff | required | required | required |

`testit_case_impact` is required at every scale with undiminished rigor. Copy changes are among the most likely changes to break automated test assertions, because the asserted value is the string being changed.

Scale never removes a strong checkpoint. At low scale the four confirmations are short and the first three may be batched, but the PM still explicitly approves the problem, the scope, and the direction.

When judgment is unclear, choose the higher scale. The error directions are not symmetric.

## Stage Plan

The stage plan is generated after intake, approved by the PM, and used for the rest of the request.

Modes: `generate`, `verify`, `not_applicable`.

- Content present in the input means `verify`, never `not_applicable`.
- `not_applicable` is only for work that genuinely does not need doing.
- Every `not_applicable` needs a basis in the plan. It becomes an `open_issue` only when the skip leaves a real gap.
- `draft_prd` is `verify` when recognizable PRD section structure exists, `generate` when the input is loose paragraphs.
- A `verify` stage escalates to `generate` when more than half its criteria fail or whole required sections are absent. Record `escalated_from`.

The plan is revisable. Loopback from `critic_review` is implemented as a plan revision: set the target stage `status` to `reopened`, set its mode, increment `plan_version`. No separate loopback machinery exists.

## Verification Mode

A stage in `verify` mode does not generate new content. It reviews existing content against that stage prompt's own `RULES`, which already encode the criteria. Output is a `verification_result`: criteria checked, criteria passed, criteria failed with evidence, suggested fixes, PM decisions needed.

Verification changes the work from redoing to checking. It does not lower rigor, and it does not permit an approval the agent has not examined.

## Pause Policy

Pause and end the turn when any of the following is true:

1. Stage plan approval.
2. Any of the four strong checkpoints: problem frame, scope, selected direction, final PRD.
3. The Codebase Project Confirmation Gate.
4. Any output item in the current stage has `pm_action_required: true`.

Otherwise continue in the same turn. Group boundaries are not pause triggers.

Condition 2 is unconditional and is not affected by how the agent classified `pm_action_required` elsewhere. This is the backstop: even if every item were marked non-PM, the four checkpoints still occur.

Stage output should include what was completed, the agent's recommended next action, any PM decision or input needed, a suggested default when reasonable, and a clear waiting prompt such as "Waiting for PM input: please confirm, adjust, skip, or continue in your next message."

A pause is conversational only. Write all questions and choices directly in the Markdown response, then end the assistant turn. Do not use interactive question tools, modal dialogs, popup panels, or tool-mediated prompts such as `request_user_input`, `ask_question`, `AskUserQuestion`, or similar mechanisms.

Pauses do not change ownership rules. Technical, QA, design, data, or implementation-only questions remain assigned to Engineering, QA, Design, Data, Agent, or Codebase Analysis unless they require a PM product decision.

## Approval Checkpoints

Order matters. These are listed in the order they occur.

| # | Checkpoint | Applies | Generate mode | Verify mode |
|---|---|---|---|---|
| 1 | Problem frame | Whenever `problem_framing` is in the plan | Full frame produced, PM accepts/edits/narrows/reframes | Frame reviewed against priority calibration and evidence rules, findings presented, PM confirms or sends back |
| 2 | Scope | Whenever `scope_expansion` is in the plan | Scenarios produced, PM confirms in/out/uncertain | Existing scope reviewed against the approved problem frame, findings presented |
| 3 | Selected direction | Whenever `solution_options` is in the plan | Options produced, PM selects | Existing direction challenged, findings presented |
| 4 | Final PRD | Always | — | — |

Checkpoints 1 to 3 may be combined into one batch confirmation under either path:

- Path 1: all three are in `verify` mode and all three report `has_findings: false`. Available at any scale.
- Path 2: `scale` is `low` and all three have minimal content. Available at low scale only.

If any one has findings, it is handled separately and must not be folded into the batch. Batching changes presentation, not the existence of the gate.

Batch confirmations present a condensed criteria-and-conclusion summary per item, not three full reports. Any item can be expanded on request.

No empty confirmations. Every confirmation carries the agent's own review conclusion, including which criteria were checked when nothing failed.

For gap review, the agent must first gather and summarize available Jira and Confluence/wiki context, and codebase context for supported projects, before the PM sees the synthesized findings. The PM answers only PM-owned gaps.

Before codebase or TestIt lookup, resolve project context with `references/projects.md` and complete the Codebase Project Confirmation Gate before the first `qa_codebase` call. Call `testit-features` only when `project_context.testit_supported` is true and `project_context.testit_project` is non-empty. If the project is unsupported or codebase project confirmation was cancelled, continue without automated codebase/TestIt context and expose the limitation plus Engineering/QA follow-up. If only the TestIt artifact is unavailable, continue codebase analysis and identify the unsynced artifact as the QA limitation.

When TestIt context is available, use it to inform scope confirmation, gap analysis, PRD QA impact, and critic review. TestIt no-match results do not prove cases are unaffected; treat them as missing coverage or limitations.

## Lookup Timing

- `code_context` runs immediately before the first stage that needs it and is cached for the session. Structured input usually needs it before `gap_analysis`; free-text input usually needs it before `solution_options`.
- TestIt lookups follow the same rule: gather once at first need, reuse afterwards. Do not run a lightweight discovery pass and a later full pass over the same scope.
- Re-run the Codebase Project Confirmation Gate only when the resolved project set changes.

## Confidence

Track confidence on two dimensions.

`technical` — quality of code grounding, feasibility, implementation risks, and reuse checks:

| Level | Criteria |
|---|---|
| high | Codebase context retrieved for all confirmed projects, tech check ran, no unresolved feasibility blockers |
| medium | Codebase context retrieved but partial, or tech check surfaced unresolved risks |
| low | No codebase context, confirmation cancelled, API error or timeout, or tech check skipped |

`product` — quality of product framing, evidence, scope, and PRD completeness:

| Level | Criteria |
|---|---|
| high | Problem frame approved with supporting evidence, scope confirmed with explicit out-of-scope, requirements testable, metrics measurable |
| medium | Frame approved but evidence is thin or mixed, or scope has unresolved uncertain scenarios, or metrics are directional only |
| low | Frame relies mainly on assumptions, no evidence gathered, or scope boundaries unconfirmed |

Technical confidence is always `low` at intake. For supported projects, do not skip codebase analysis unless the API returns an explicit error or times out after the documented wait budget.

Use the remote codebase analysis API as the default code grounding path. Local repositories and Git URLs are advanced fallback inputs, not required PM setup.

## Final Handoff

Final output must include:

- final PRD in Confluence-ready Markdown
- confidence summary on both dimensions
- final stage plan state, including every `not_applicable` stage and its basis, and any stage that escalated from `verify` to `generate`
- decisions needed
- unresolved questions
- QA/TestIt case impact when available, or an explicit limitation when relevant but unavailable
- forced advance flags, if any
- open issues from critic and product-line mandatory checks

The final PRD Markdown should be Confluence-ready. If the PM asks to publish it to Confluence, submit the same Markdown via MCP with `content_format: markdown`. Creating a new page requires `space_key`, `title`, and optional `parent_id`; updating an existing page requires `page_id` and `title`.

When `critic_review` produces no must-fix items, the critic result and the final handoff may be presented in one confirmation. When must-fix items exist, handle them before the final handoff confirmation.

After final handoff, pause. Start optional data tracking and Scrum task breakdown follow-up questions only after the PM asks or confirms continuing to follow-ups. Ask those follow-up questions one at a time, pause after each question, and continue only after the PM answers.
