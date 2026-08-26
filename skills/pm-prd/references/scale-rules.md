# Scale Rules

Scale answers a different question from stage mode.

- **Stage mode** (`generate` / `verify` / `not_applicable`) answers: *has this work already been done?*
- **Scale** (`high` / `medium` / `low`) answers: *is this work worth doing for a request of this size?*

The two are evaluated independently and then combined:

| | Content absent | Content present |
|---|---|---|
| Stage is needed at this scale | `generate` | `verify` |
| Stage is not needed at this scale | `not_applicable` | `verify` |

The bottom-right cell is deliberate. **Scale may downgrade a stage from generate to not-done. It may never cause existing content to be silently discarded.** When the PM already supplied the content, verifying it is nearly free and always worth doing.

## Extension Protocol

Read this before adding a row.

- **Adding a row to Table H or Table D is monotonically safe.** These tables only tighten classification. Anyone may add a row without review.
- **Adding a row to Table L widens classification.** These rows let requests into the minimal path. Every addition requires review.
- **Every row carries the version it was added in.** When a misclassification is found later, the responsible rule can be identified and dated.
- Never delete a row from Table H or Table D to unblock a specific request. Downgrade that request through the PM authority path instead, which leaves an auditable record.

## Table H — High scale lock

Matching any row forces `scale: high`. **Not downgradable, including by the PM.** Record the matched rule ID in the plan.

| ID | Category | Triggers when the request | Added |
|---|---|---|---|
| H1 | Billing, pricing, plan entitlement | Affects charged amounts, billing logic, metering, or what a plan includes | 0.3.0 |
| H2 | Permissions, roles, admin-visible configuration | Changes who can see or do something, or what an admin can configure | 0.3.0 |
| H3 | Data compliance, retention, privacy | Touches collection, retention, export, or deletion of recordings, transcripts, call logs, or personal data | 0.3.0 |
| H4 | Security and authentication | Touches login, tokens, sessions, encryption, or access control | 0.3.0 |
| H5 | Cross product line | Affects more than one product line | 0.3.0 |
| H6 | New user-visible capability | Lets a user do something they previously could not | 0.3.0 |
| H7 | Legal or compliance copy | Changes consent text, disclaimers, disclosures, or legal terms | 0.3.0 |
| H8 | Call behavior | Changes any aspect of how a call behaves | 0.3.0 |
| | *reserved for extension* | | |

### H8 judgment list

H8 is the broadest rule and the one most likely to be under-applied. Treat the request as call behavior when it touches any of the following. This list is illustrative, not exhaustive — when a request affects calls in a way not listed here, H8 still applies.

- Call setup, dialing, answering, or rejection
- Routing: answering rules, call handling rules, forwarding, queues, IVR, ring groups, delegation
- In-call actions: hold, park, mute, transfer, merge, conference, flip
- Call termination and disconnect behavior
- Recording start, stop, pause, consent prompts, or notification
- Media behavior: codec, quality, audio path, video path, screen share within a call
- Presence or availability where it determines call delivery
- DTMF, keypad, and in-call input handling
- Voicemail delivery, greeting playback, and message handling
- **Emergency calling, E911 registration, and emergency address handling**
- Caller ID, number presentation, and blocked/anonymous call handling
- Device or endpoint selection and failover during a call
- Region-specific call regulation behavior

Emergency calling is called out explicitly because it is the highest-consequence item in this list. When a request touches emergency calling in any way, including copy shown during an emergency flow, H8 applies without exception.

## Table S — High scale signals

Suggests `scale: high`. **The PM may downgrade to medium** with a stated reason, recorded in the plan. These are heuristics, not policy, so a wrong guess must not lock the PM out of a shorter path.

| ID | Signal | Added |
|---|---|---|
| S1 | Needs backend support or a new interface | 0.3.0 |
| S2 | Affects more than three surfaces or clients | 0.3.0 |
| S3 | The input already proposes multiple mutually exclusive approaches | 0.3.0 |
| S4 | The PM raised uncertainty or disagreement in the input | 0.3.0 |
| | *reserved for extension* | | |

## Table L — Low scale admission

**All rows must hold** for a request to be eligible for `scale: low`. Eligibility is necessary but not sufficient; Table D must also clear.

| ID | Condition | Added |
|---|---|---|
| L1 | Presentation-layer change only: copy, icon, layout, ordering, color | 0.3.0 |
| L2 | No behavior changes | 0.3.0 |
| L3 | No stored data or data model changes | 0.3.0 |
| L4 | No permission or visibility changes | 0.3.0 |
| L5 | No new interface or integration | 0.3.0 |

## Table D — Low scale blockers

Matching any row disqualifies `scale: low`, even when all of Table L holds.

| ID | Blocker | Added |
|---|---|---|
| D1 | Any Table H row matches | 0.3.0 |
| D2 | The change appears in legal, compliance, consent, or disclosure content | 0.3.0 |
| D3 | The change appears in a billing, permission, or security flow | 0.3.0 |
| D4 | The change appears in a call, recording, or emergency flow, including in-call UI | 0.3.0 |
| D5 | The string is asserted by automated tests, as reported by `testit_case_impact` | 0.3.0 |
| | *reserved for extension* | | |

D2, D3, and D4 exist because a presentation change is technically presentation-layer and satisfies all of Table L, yet can carry legal, financial, or safety consequence. **Table L describes the *shape* of a change; Table D describes its *context*. Both must be checked.**

These rows deliberately say "the change" rather than "the copy". An icon, color, ordering, or layout change inside a call, billing, or consent surface carries the same risk as a wording change there. A mute icon that reads as the wrong state has real consequence even though no behavior changed.

D5 can only be evaluated after `testit_case_impact` runs. When it fires late, reclassify: raise scale to medium, revise the stage plan, increment `plan_version`, and tell the PM which rule caused the change.

## Medium is the default

A request that does not clear Table L and does not match Table H is `medium`. Do not treat medium as a judgment failure; it is the correct answer for most requests.

## Classification Procedure

1. Evaluate Table H. Any match sets `high` and `scale_locked: true`. Stop.
2. Evaluate Table S. Any match sets `high` and `scale_locked: false`.
3. Evaluate Table L. If any row fails, set `medium`.
4. Evaluate Table D. If any row matches, set `medium`.
5. Otherwise set `low`.
6. Record every matched rule ID in `matched_rules` and show them to the PM.

**When judgment is unclear, choose the higher scale.** The two error directions are not symmetric: classifying a large request as small skips evidence and option comparison, which degrades requirement quality — precisely what this skill exists to prevent. Classifying a small request as large only costs a few exchanges.

## Scale Effect On The Stage Plan

| Stage | Low | Medium | High |
|---|---|---|---|
| `evidence_capture` | not done | lightweight | full |
| `problem_framing` | minimal | full | full |
| `scope_expansion` | minimal | full | full |
| `solution_options` | not done | may be skipped when the direction is genuinely singular | **required** |
| `pattern_reuse` | not done | as needed | required |
| `tech_check` | lightweight | full | full |
| `testit_case_impact` | **required** | required | required |
| `draft_prd` | required | required | required |
| `critic_review` | required | required | required |
| final handoff | required | required | required |

`testit_case_impact` is required at every scale and its rigor does not drop at low scale. Copy changes are among the most likely changes to break automated tests, because the asserted value is the string being changed. This stage is worth more on a small request than on a large one.

`minimal` for `problem_framing` and `scope_expansion` means a short frame and a short in/out statement, still presented to the PM for confirmation. It does not mean skipping the checkpoint.

## Downgrade Authority

| Origin | Who may downgrade | Record |
|---|---|---|
| Table H match | Nobody, including the PM | `scale_locked: true` and the matched rule ID |
| Table S match only | PM may downgrade to medium | `downgraded_by: "PM"` and `downgrade_reason` |
| Medium to low | PM may downgrade with an explicit statement | `downgraded_by: "PM"` and `downgrade_reason` |
| Agent downgrading to low | Only when all of Table L holds and no Table D row matches | `matched_rules` and the objective basis |
| Any upward change | Always allowed, no reason required | `matched_rules` if newly triggered |

The agent never downgrades on its own judgment of size. It downgrades only by satisfying objective conditions.

## Checkpoints Are Not Affected

Scale changes the depth of stages, never the existence of the four strong checkpoints. Problem frame, scope, selected direction, and final PRD are confirmed at every scale.

At low scale these confirmations are short, and they may be combined into one batch confirmation under batch path 2. Combining them is a change in presentation, not a removal of the gate: the PM still explicitly approves the problem, the scope, and the direction.
