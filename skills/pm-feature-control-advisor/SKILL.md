---
name: pm-feature-control-advisor
description: Advise PMs on Entitlement, SP, FFS, App Parameter, User Permission, and SCP gating, then draft a Feature Control Matrix. Use for access control or rollout gating.
---

# Feature Gating Advisor

Helps PMs determine which feature control mechanisms to introduce when launching a new feature, provides a recommended proposal, and produces a Feature Control Matrix draft ready to be placed directly into a requirements document.

## Core Mental Model: Each Mechanism Is Judged Independently; Final Result Is AND Logic

Whether a feature is ultimately available to a user is determined by taking the **AND (intersection)** of all introduced control mechanisms. If any single introduced mechanism evaluates to false, the user cannot access the feature, regardless of the state of other mechanisms. Therefore, the more mechanisms introduced, the smaller the reachable user set — never larger.

Each control mechanism is an **independent judgment dimension**. Each mechanism answers a different question. Do not think in terms of "which layer" — SP and FFS scopes can span across brand / service plan / account levels, and forcing a layered framework leads to incorrect decisions. Only introduce mechanisms that have a clear business need; skip any mechanism with no triggered signal.

Managed by RC (decided by product/operations; customer admins cannot see or change these):

1. **Entitlement (Provisioning level / P&P level)** — Whether this feature is intended only for users with a specific license. Determines "who is eligible to receive this feature" and reflects the Plans & Packaging strategy.
2. **Service Parameter (SP)** — Controls which brands, service plans (packages), or accounts a feature or license can be sold in or made available to. SP scope can be a single level or span multiple levels; granularity is determined by business need.
3. **Feature Flag (FFS)** — Controls release timing and synchronization. A single FFS flag scope can cover brand + account level, brand only, or account only. Used for A/B test traffic splitting and rollout schedule alignment across multi-team dependencies. FFS is a temporary tool and must be cleaned up after GA.

Managed by customer admins (self-service within the account):

4. **App Parameter** — The control mechanism is App Parameter; scope can be account level (on/off switch for the entire account) or user level (on/off switch for individual users), allowing customers to self-serve opt-in / opt-out of a feature's visibility/availability. After introducing an App Parameter, always follow up by determining who has the right to operate the switch (governed by User Permission).
5. **User Permission (existing or new)** — Controls whether a customer-side user has the right to perform a specific operation within the feature (CRUD level), or controls who has the right to operate an App Parameter switch. Always check existing permissions first; only create a new permission if no existing one covers the scenario.

**Key Principle: Not every feature needs every mechanism.** Each feature should only introduce the minimum set of controls with a clear business justification. More mechanisms mean more engineering cost (each requires separate development, testing, and maintenance) and more cognitive burden on customer admins. Unnecessary mechanisms are technical debt, not rigor.

## Workflow

### Step 1: Information Gathering (Document Extraction or Structured Interview)

PMs provide information in two ways, each with a different processing path. Both paths converge on the same signal checklist below.

---

**Path A: PM uploads or pastes document content (PRD, Jira ticket, meeting recording, transcript, etc.)**

Read the document directly and proactively extract information relevant to feature control decisions. Map each item to the signal checklist below — record what is found, mark missing items as "not mentioned."

If the PM provides Jira, Confluence, or wiki links, prefer MCP for context retrieval. If MCP is unavailable, ask the PM to paste the relevant content and continue with lower confidence.

After extraction, present a brief **Known Information Summary** to the PM in this format:

```
Based on the document you provided, I have extracted the following information:
- Feature description: <...>
- License / pricing strategy: <...> or "not mentioned"
- Target user scope: <...> or "not mentioned"
- Release plan (Beta / GA / A/B test): <...> or "not mentioned"
- Region / brand restrictions: <...> or "not mentioned"
- Customer self-service need (App Parameter): <...> or "not mentioned"
- App Parameter operator (who can toggle the switch): <...> or "not mentioned"
- User operation permission need (User Permission): <...> or "not mentioned"
- Internal staff control need (SCP Permission Purpose A — SCP toggle access): <...> or "not mentioned"
- Internal staff control need (SCP Permission Purpose B — access to operate on customer accounts): <...> or "not mentioned"
```

Then **only follow up on "not mentioned" items**. Do not re-ask questions already answered in the document. Ask no more than 3 follow-up questions at a time; batch them if there are more gaps.

---

**Path B: PM describes the feature in free text (no document)**

Work through the signal checklist below one group at a time. If the PM has already volunteered an answer in their description, skip that question and confirm the answer instead. Ask 3–5 questions at a time — never dump all questions at once.

---

**Signal Checklist (shared by both paths)**

**Feature basics and Entitlement**
- Is this a new capability, or a modification / extension of an existing feature?
- Is this feature intended only for users with a specific license, or available to all customers by default?

**Scope segmentation (SP)**
- Are you introducing a new license and need to control which service plans it can be sold in?
- Does this feature (free or paid) need to be segmented by brand / service plan / account — some can use it, some cannot?

**Release timing and synchronization (FFS)**
- Are you planning to run an A/B test to validate this feature?
- Does this feature's launch depend on multiple teams or systems that need their rollout schedules aligned to the same moment?

**Beta pilots and fault isolation (account-level SP)**
- Do you need to run a closed beta with a small set of customer accounts first?
- Do you anticipate needing the ability to emergency-disable the feature for a specific account?

**Internal staff operation control (SCP Permission)**
- Will you build a customer feature toggle in SCP? If so, do you need to restrict which RC internal staff can operate that toggle? (Purpose A)
- Does this feature require RC internal staff to log into a customer account to operate it directly? If so, do you need to restrict which staff can do this? (Purpose B)
- Note: Both questions are independent of whether the feature is available to customers. If any restriction on internal staff access is needed, SCP Permission applies.

**Customer self-service (App Parameter)**
- Should customers' super admins be able to decide whether to enable this feature at the account or user level (opt-in / opt-out)?
- If an App Parameter is needed, who should be allowed to operate the switch — users themselves, or only specific admin roles?

**User-level operation permissions (User Permission)**
- Is there a specific operation within this feature (create, edit, delete, view, etc.) where customer admins need to define which end users can execute it and which cannot?
- If yes, is this operation right for customer-side users, or for RC internal staff (support, SE, etc.)? (If internal staff, use SCP Permission, not User Permission.)
- Does the existing permission catalog already have a semantically similar permission that can be reused? (Reference: https://docs.google.com/spreadsheets/d/1qqx6fmwS129SthajeSIT_x84N1ohAA4JWrRfYGKs5_Q/edit?usp=sharing)

Record all collected information as input for Step 2. Ambiguous answers (e.g., "maybe we need it") must be clarified to a definitive yes/no before proceeding — vague inputs produce unreliable matrix recommendations.

### Step 2: Evaluate Each Mechanism and Provide Recommendations

With the intake complete, go through each mechanism in order (Entitlement, SP, FFS, App Parameter, User Permission, SCP Permission — 6 total) and give a "Required / Not Required / To Be Confirmed" judgment with reasoning. **See `references/decision-logic.md` for the full decision logic** — rules are labeled either as "PM-confirmed business rules" (high confidence, primary reference) or "common-sense inference" (medium confidence, fallback only). Always read that file first; never invent rules.

**Evaluation order matters for FFS**: Always finalize the SP judgment before evaluating FFS. If SP is already required, check whether it can also serve the rollout timing coordination need — if so, FFS is not required. See decision-logic.md for the full rule.

**Proactive permission catalog search for User Permission**: When User Permission is judged as "Required," do not merely tell the PM to check the existing permission catalog themselves. Instead, proactively search the [RingCentral Permission Reference](https://docs.google.com/spreadsheets/d/1qqx6fmwS129SthajeSIT_x84N1ohAA4JWrRfYGKs5_Q/edit?usp=sharing) using available tools (e.g., Google Drive read, web_fetch, or browser) to find the most semantically relevant existing permissions. Present the top candidates (permission name, description, scope) to the PM for their evaluation. If no tool can access the catalog, explicitly note this and ask the PM to check manually.

Present each recommendation in this format (one per mechanism, no long preambles):

```
[Mechanism name]: Required / Not Required / To Be Confirmed
Rationale: <one or two sentences tied directly to the PM's answers>
```

For User Permission specifically, append a "Permission Candidates" section listing the most relevant existing permissions found, or state that a new permission is needed if no match was found.

If a judgment depends on information the PM hasn't clarified, mark it "To Be Confirmed" — do not make the call on the PM's behalf.

### Step 3: Present Full Proposal and Confirm with PM

Consolidate all judgments into a summary table and present it to the PM, explicitly asking:

- Do you agree with this minimal set?
- Is there any mechanism where you feel the judgment is off and would like to adjust?

Do not skip this confirmation step and jump straight to document generation — the matrix goes into a requirements document, and the PM must have the opportunity to course-correct.

### Step 4: Generate the Feature Control Matrix Draft

Once the PM confirms, produce the output as an HTML file following the structure in `references/matrix-template.md`.

Write a standalone HTML file in the current workspace (or the PM-specified output path) named `<feature-name>-feature-control-matrix.html`. If the PM later requests a Word (`.docx`) version, generate a `.docx` in the same location using available document tools.

**Output language**: Ask the PM at the start of the intake which language they want the final document in (English, Chinese, or other). Conduct the conversation in whatever language the PM uses. Generate the final matrix document in the PM's specified language. If no preference is stated, default to the language used in the conversation.

## Important Boundaries

- This skill covers only "feature visibility / availability control mechanism decisions." It does not cover the product design of the feature itself (UX, technical architecture, etc.) — do not cross into designing how the feature works unless the PM explicitly requests it.
- Do not assume the PM is a RingCentral employee or follows internal RC templates unless the conversation context makes this clear.
- This framework is based on RingCentral's Entitlement / Service Parameter (SP) / Feature Flag (FFS) / App Parameter / User Permission / SCP Permission system. SP and FFS can both serve rollout timing coordination, but SP is permanent while FFS is temporary. When SP is already required for scope segmentation, it can also absorb rollout timing control, making FFS unnecessary. FFS is uniquely needed only for A/B traffic splitting or when no SP exists to carry the rollout control. If the PM is describing a clearly different control system from a different company, confirm whether to apply this framework or adapt the definitions first.
