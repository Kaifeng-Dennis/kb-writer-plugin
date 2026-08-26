# Schemas

## Working Memory

```json
{
  "product_line_id": "",
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
  "open_issues": []
}
```

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

Use this shape after resolving project input from `references/projects.md`. Populate `recommended_project_list` and `available_project_list` from the active registry before the Codebase Project Confirmation Gate. Set `confirmed_project_list` and `confirmation_status: confirmed` only after the PM confirms or edits the codebase project list for the current `qa_codebase` call. Re-run confirmation before every call, including follow-ups.

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
