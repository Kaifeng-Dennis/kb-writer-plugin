# Schemas

## Working Memory

```json
{
  "stage_plan": {},
  "product_line_rules": [],
  "project_context": {
    "supported": false,
    "project_id": "",
    "codebase_project": "",
    "testit_supported": false,
    "testit_project": "",
    "display_name": "",
    "unavailable_reason": "",
    "registry_source": "api | fallback_snapshot | unavailable",
    "recommended_project_list": [],
    "available_project_list": [],
    "confirmed_project_list": [],
    "confirmation_status": "pending | confirmed | cancelled | unavailable"
  },
  "raw_input": "",
  "imported_artifacts": [],
  "facts": [],
  "pm_inputs": [],
  "assumptions": [],
  "unknowns": [],
  "scenario_map": {
    "core_scenario": "",
    "expanded_scenarios": [],
    "in_scope_scenarios": [],
    "out_of_scope_scenarios": [],
    "uncertain_scenarios": []
  },
  "evidence": {},
  "data_metric_insights": [],
  "problem_frame": {},
  "gap_analysis": {},
  "solution_options": [],
  "selected_option": {},
  "code_context": {},
  "testit_context": {},
  "tech_check": {},
  "pattern_check": {},
  "prd": {},
  "critic": {},
  "verification_results": [],
  "open_issues": []
}
```

## Stage Plan

The stage plan is generated after intake, approved by the PM, and is the authoritative record of what runs, what already ran, and what was deliberately skipped. It replaces the old fixed route step lists and the repair queue.

```json
{
  "plan_version": 1,
  "approved": false,
  "estimated_exchanges": 0,
  "scale": "high | medium | low",
  "scale_basis": "",
  "scale_locked": false,
  "matched_rules": [],
  "downgraded_by": "",
  "downgrade_reason": "",
  "stages": [
    {
      "stage": "problem_framing",
      "mode": "generate | verify | not_applicable",
      "basis": "",
      "checkpoint": "none | strong",
      "status": "pending | in_progress | done | reopened",
      "escalated_from": "",
      "reopened_reason": ""
    }
  ]
}
```

Field rules:

- `mode` is `verify` whenever the input already contains content for that stage. `not_applicable` is only for work that genuinely does not need doing.
- `basis` is required for every `not_applicable` stage and for every `verify` stage. It states what content was found, or why the work is unnecessary.
- `checkpoint` is `strong` for `problem_framing`, `scope_expansion`, `solution_options`, and final handoff. Strong checkpoints occur regardless of mode.
- `escalated_from` is set to `"verify"` when a verification found more than half its criteria failing or whole required sections absent, and the stage was promoted to `generate`.
- A `critic_review` loopback sets the target stage `status` to `reopened`, sets `mode`, fills `reopened_reason`, and increments `plan_version`.

Scale fields, governed by `references/scale-rules.md`:

- `scale` is classified at intake, independently of stage modes, and combined with content presence to produce each `mode`.
- `scale_locked` is `true` when a Table H row matched. A locked scale cannot be downgraded by anyone, including the PM.
- `matched_rules` holds every matched rule ID, for example `["H8", "S1"]`. It must be shown to the PM so a misclassification can be corrected.
- `scale_basis` states in one sentence why this scale was chosen.
- `downgraded_by` and `downgrade_reason` are set only when the PM downgrades a Table S classification or moves medium to low. The agent never fills these on its own judgment of size.
- Scale may move a stage to `not_applicable`, but never when the input already contains content for that stage. Existing content is always at least `verify`.

Valid `stage` values:

`parse_input`, `clarify`, `gap_analysis`, `evidence_capture`, `problem_framing`, `scope_expansion`, `solution_options`, `tech_check`, `pattern_reuse`, `testit_case_impact`, `draft_prd`, `critic_review`, `final_handoff`

`code_context` is not a plan stage. It is an on-demand shared resource fetched before the first stage that needs it and cached for the session.

## Verification Result

Produced by any stage running in `verify` mode. `has_findings` is the machine-checkable input to batch confirmation; `criteria_checked` being non-empty is the auditable evidence that the confirmation was not empty.

```json
{
  "stage": "",
  "criteria_source": "",
  "criteria_checked": [],
  "criteria_passed": [],
  "findings": [
    {
      "criterion": "",
      "issue": "",
      "evidence": "",
      "suggested_fix": "",
      "owner": "PM | Engineering | Design | Data | QA | Agent | Unknown",
      "pm_action_required": false,
      "severity": "high | medium | low"
    }
  ],
  "has_findings": false,
  "escalation_recommended": false,
  "escalation_reason": "",
  "confidence": "high | medium | low"
}
```

- `criteria_source` names the prompt whose `RULES` were used as criteria, for example `prompts/problem_framing.md`.
- `criteria_checked` must be non-empty. An empty list means no verification happened and the confirmation would be an empty confirmation.
- `has_findings` is `true` when `findings` is non-empty. Only stages with `has_findings: false` are eligible for batch confirmation.
- `escalation_recommended` is `true` when more than half of `criteria_checked` failed, or when whole required sections are absent.

## PM-Facing Question

```json
{
  "id": "",
  "question": "",
  "owner": "PM | Engineering | Design | Data | QA | Agent | Unknown",
  "pm_action_required": false,
  "why_owner_is_needed": "",
  "suggested_default": "",
  "impact_if_unanswered": "",
  "priority": "high | medium | low"
}
```

## Product Line Rule

```json
{
  "id": "",
  "rule_name": "",
  "scope": "general | personal",
  "display_name": "",
  "version": 1,
  "section": "",
  "description": "",
  "check_guidance": "",
  "severity": "high | medium | low",
  "active": true
}
```

## PRD

Final PRDs use flexible Confluence-ready Markdown. This JSON shape is a working-memory representation for synthesis and review, not a required output structure.

```json
{
  "feature_name": "",
  "status": "",
  "owners": [],
  "links": [],
  "problem": {},
  "target_users": [],
  "objectives": [],
  "scope": {
    "in_scope": [],
    "out_of_scope": [],
    "uncertain": []
  },
  "requirements": [],
  "metrics": [],
  "dependencies": [],
  "risks": [],
  "launch_considerations": [],
  "open_issues": [],
  "questions": [],
  "chosen_markdown_structure": []
}
```

## PRD Readiness Result

```json
{
  "area": "",
  "covered": false,
  "coverage_quality": "full | partial | missing",
  "placeholder_values_remaining": [],
  "format_or_readiness_issue": "",
  "evidence": "",
  "suggested_fix": ""
}
```

## Data Metric Insight

Use when the PM provides data or metric information in text, tables, screenshots, images, Jira, Confluence, or analytics summaries.

```json
{
  "source": "user_text | table | screenshot | image | jira | confluence | analytics | unknown",
  "metric_or_signal": "",
  "observed_pattern": "",
  "problem_indicated": "",
  "product_implication": "",
  "confidence": "high | medium | low",
  "needs_pm_review": false
}
```

## Open Issue

```json
{
  "rule_id": "",
  "section": "",
  "owner": "PM | Engineering | Design | Data | QA | Agent | Unknown",
  "pm_action_required": false,
  "severity": "high | medium | low",
  "suggested_fix": "",
  "pm_note": "",
  "status": "to_be_addressed"
}
```

## Project Context

Use this shape after resolving project input from `references/projects.md`. Populate `recommended_project_list` and `available_project_list` from the active registry before the Codebase Project Confirmation Gate. Set `confirmed_project_list` and `confirmation_status: confirmed` only after the PM confirms or edits the codebase project list. The confirmation holds for the conversation; re-run it only when the resolved project set changes, the registry source changes, or the PM asks to change it.

```json
{
  "supported": false,
  "project_id": "",
  "codebase_project": "",
  "testit_supported": false,
  "testit_project": "",
  "display_name": "",
  "unavailable_reason": "",
  "registry_source": "api | fallback_snapshot | unavailable",
  "recommended_project_list": [],
  "available_project_list": [],
  "confirmed_project_list": [],
  "confirmation_status": "pending | confirmed | cancelled | unavailable"
}
```

## TestIt Context

Use this shape for QA case impact findings from the `testit-features` skill. Populate it from Jenkins artifacts only when `project_context.testit_supported` is true and `project_context.testit_project` is non-empty. For a CodeAsk-supported project without a synced TestIt artifact, use `source: "unavailable"` and explain that artifact sync is unavailable rather than calling the entire project unsupported.

```json
{
  "source": "testit-features | unavailable",
  "project": "",
  "source_context": "",
  "searched_terms": [],
  "matched_terms": [],
  "no_match_terms": [],
  "affected_cases": [
    {
      "case_id": "",
      "feature_file": "",
      "scenario_summary": "",
      "impact": "",
      "confidence": "high | medium | low",
      "source_context": ""
    }
  ],
  "related_unaffected_cases": [
    {
      "case_id": "",
      "feature_file": "",
      "scenario_summary": "",
      "reason_unaffected": "",
      "confidence": "high | medium | low",
      "source_context": ""
    }
  ],
  "missing_coverage": [
    {
      "scenario_or_requirement": "",
      "why_coverage_is_expected": "",
      "searched_terms": [],
      "owner": "QA | PM",
      "pm_action_required": false,
      "suggested_follow_up": "",
      "confidence": "high | medium | low"
    }
  ],
  "limitations": [],
  "confidence": "high | medium | low"
}
```
