# Feature Control Matrix Template

When generating the final deliverable, strictly follow the structure below. Output format is an **HTML file** (`.html`), not Markdown.

---

## HTML Document Structure

Output a complete, browser-renderable HTML file containing the following sections in fixed order:

1. **Feature Overview**: One or two sentences describing what the feature does
2. **Control Mechanism Decisions**: The core table, grouped by phase if multiple phases apply
3. **Minimum Necessary Mechanisms**: Explain why this is the minimal set
4. **Open Items**: List questions that still need to be confirmed

---

## Style Specification

- Overall tone: clean and professional, suitable for in-browser reading and screenshot sharing
- Font: system default sans-serif
- Tables: bordered, dark header background (`#2c3e50` white text), alternating row colors (white / `#f8f9fa`)
- Status badge colors:
  - "Required": green background `#d4edda`, dark green text `#155724`
  - "Not Required": light gray background `#e2e3e5`, dark gray text `#383d41`
  - "To Be Confirmed": yellow background `#fff3cd`, dark yellow text `#856404`
- Warning blocks (⚠️ operation order, etc.): orange left border `#fd7e14`, light orange background `#fff8f0`
- Phase headings (Beta / Pre-GA Transition / Post-GA): use `<h2>` with a divider to separate sections

---

## Table Rows

The core table must include a row for each of the following mechanisms. Rows for mechanisms judged "Not Required" should still appear in the table for completeness — omitting them makes it harder for reviewers to confirm nothing was missed.

| Mechanism | Required? | Control Method | Rationale / Notes |
|---|---|---|---|
| Entitlement (Provisioning level) | Required / Not Required / To Be Confirmed | e.g., Bind to XX license | one-sentence rationale |
| Service Parameter (SP) | Required / Not Required / To Be Confirmed | e.g., New SP; scope: brand level (RC brand only) + account level (phased rollout to specific accounts). Describe all applicable scopes in this cell. | one-sentence rationale |
| Feature Flag (FFS) | Required / Not Required / To Be Confirmed | e.g., A/B test 50/50 split at account level | one-sentence rationale |
| App Parameter | Required / Not Required / To Be Confirmed | e.g., Scope: account level, default off; super admin opt-in. Or: Scope: user level, default off; per-user opt-in. Describe all applicable scopes in this cell. | one-sentence rationale |
| User Permission — Feature operation access | Required / Not Required / To Be Confirmed | e.g., Reuse existing "Manage XX" permission / New "XX" permission | one-sentence rationale |
| User Permission — App Parameter operator | Required / Not Required / To Be Confirmed | e.g., Only super admin can toggle; reuse existing admin permission | one-sentence rationale |
| SCP Permission — Purpose A (SCP toggle access) | Required / Not Required / To Be Confirmed | e.g., New SCP permission: only TAM/SE can toggle | one-sentence rationale |
| SCP Permission — Purpose B (customer account access) | Required / Not Required / To Be Confirmed | e.g., New SCP permission: only support agents can operate on customer accounts | one-sentence rationale |

**Important**: SP and App Parameter each use a single row in the table. Do not split them into separate rows by scope level (e.g., do not create separate "SP — Brand level" and "SP — Account level" rows). Instead, describe all applicable scopes within the "Control Method" and "Rationale / Notes" columns of that single row.

---

## Filling Guidelines

- The "Required?" column must strictly use "Required / Not Required / To Be Confirmed" — no vague expressions like "maybe needed." Force a clear decision or explicitly mark as To Be Confirmed.
- "Control Method" must be specific enough for engineers to understand how to implement it (e.g., don't just write "phased rollout" — write "enable for 3 pilot accounts first, then expand to 10% after two weeks of validation"). If the PM hasn't decided yet, write "TBD — pending alignment with XX team."
- The "Minimum Necessary Mechanisms" section is for reviewers (e.g., engineering lead, other PMs). Its purpose is to prove that the design is neither over-engineered nor missing a critical control point — so ground every claim in specific business facts from the intake.
- If the PM requests additional sections (e.g., rollback plan, launch timeline), add them as needed. Do not proactively add sections the PM didn't request — the scope of this skill's output is the Feature Control Matrix itself.
- Multi-phase features (e.g., Beta → GA) must have separate tables per phase. Do not mix different phases into a single table.
- At the end of each phase, explicitly state the **availability condition** (e.g., `Entitlement = true AND FFS = true`) so engineers do not have to reverse-engineer the AND logic.
