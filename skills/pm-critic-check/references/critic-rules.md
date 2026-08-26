# Critic Rules

The critic has two layers:

1. General PRD quality checks.
2. Product-line mandatory section checks from active rules.

## General Checks

- Problem is concrete and user-centered.
- Target users are specific.
- Scope has explicit in-scope and out-of-scope boundaries.
- Requirements are testable.
- Acceptance criteria are clear enough for dev/QA.
- Metrics are measurable.
- Dependencies and risks are visible.
- Open questions are separated from decisions.
- Technical feasibility is not overstated.
- Imported strong sections are preserved unless contradicted.

## Product-Line Checks

For each active product-line rule:

- Mark `coverage_quality` as `full`, `partial`, or `missing`.
- `partial` counts as covered, but include the remaining gap.
- Severity does not block finalization.
- Missing or partial high-severity items should become prominent open issues.

