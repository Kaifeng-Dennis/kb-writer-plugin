# Feature Control Decision Logic (v2 — Updated with PM-confirmed business rules)

> Rules labeled **[PM Rule]** come directly from real business scenarios provided by the PM and carry high confidence — use them as the primary reference. Rules labeled **(common-sense inference)** carry medium confidence and serve only as a fallback when no PM-confirmed rule applies. When a PM's stated facts conflict with any rule here, the PM's facts take precedence.

## Core Premise: All Mechanisms Use AND Logic

Whether a feature is ultimately available to a user is determined by taking the **AND** of all introduced control mechanisms:

**Feature available = Entitlement AND SP AND FFS AND App Parameter AND User Permission AND SCP Permission (only for mechanisms that have been introduced)**

If any single introduced mechanism evaluates to false, the user cannot access the feature regardless of all other mechanisms. Therefore:

- **The more mechanisms introduced, the smaller the reachable user set — never larger.** Unnecessary mechanisms are technical debt, not rigor.
- **Only introduce a mechanism when there is a clear business signal.** Skip any mechanism with no triggered signal.
- **Requirements documents must explicitly state the availability condition for each phase** (e.g., Beta phase = Entitlement=true AND FFS=true) so engineers do not have to reverse-engineer the AND logic themselves.

## SP and FFS Are Two Independent Mechanisms, Not Two Names for the Same Thing

SP (Service Parameter) governs **scope / eligibility segmentation** — which brands, service plans, or accounts a feature or license can be sold in or made available to. FFS (Feature Flag / Flag Service) governs **release timing and synchronization** — A/B test traffic splitting and rollout schedule alignment across multi-team dependencies. They serve entirely different purposes. A feature may need both, or only one. Judge them separately; never combine into a single decision.

## Evaluate Each Mechanism Independently — Do Not Force a Layered Framework

The following mechanisms (Entitlement, SP, FFS, App Parameter, User Permission, SCP Permission) are **independent judgment dimensions**. Each answers a different question. Do not think in terms of "which layer" — SP and FFS scopes can span brand / service plan / account levels, and forcing a layered framework leads to incorrect decisions.

Only introduce mechanisms that are actually needed. Skip any mechanism with no triggered signal.

---

### Entitlement (Provisioning level / P&P level)

**Decision signal**: Is this feature intended only for users who hold a specific license?

- **[PM Rule #3]** Feature is intended only for users with a specific license → **Entitlement required.**
- Feature is a baseline capability available to all customers by default, not tied to any specific license → **Not required.** (common-sense inference)

---

### Service Parameter (SP) — Brand / Service Plan / Account Scope Segmentation

SP is a unified mechanism. The key question is **whether SP is needed for scope segmentation**. SP scope can be brand, service plan (package), or account level — or span multiple levels simultaneously — determined by actual business need.

**Decision signals**:

- **[PM Rule #5]** Introducing a new license and need to control which service plans it can be sold in → **SP required** (scope: service plan level).
- **[PM Rule #6]** New feature (free or paid) needs to segment which brands / service plans / accounts can use it and which cannot → **SP required** (scope determined by business need).
- Running a beta pilot with specific customer accounts, or needing fault isolation (ability to disable a feature for a specific account for troubleshooting) → **SP required** (scope: account level). (common-sense inference)
- Feature is uniformly available to all brands, all service plans, and all accounts with no segmentation needed → **Not required.** (common-sense inference)

**Key insight**: SP solves "scope / eligibility" problems regardless of whether the feature is free or paid. Entitlement is the mechanism directly tied to individual purchase status. Do not confuse the two.

---

### FFS (Feature Flag / Flag Service) — Release Timing and Synchronization

FFS is a unified mechanism. A single FFS flag scope can cover brand + account level, brand only, or account only — determined by actual need. There is no need to create separate flags for different levels.

**Decision signals**:

- **[PM Rule #1]** Running an A/B test → **FFS required** (scope determined by the target of the traffic split: brand-level or account-level).
- **[PM Rule #2]** Feature launch depends on multiple teams or systems, and their rollout schedules must align to the same moment → **FFS may be required**, but first check whether SP has already been determined as required for other reasons (e.g., brand segmentation, account-level scope control). If SP is already being introduced, SP can simultaneously serve as the rollout timing control mechanism (by coordinating when SP values are switched for target accounts), and a separate FFS is **not required**. Only introduce FFS when there is no existing SP to piggyback on, or when the rollout requires capabilities SP cannot provide (e.g., A/B traffic splitting with percentage-based allocation).
- Feature involves no traffic-splitting experiment and no multi-party rollout synchronization requirement → **Not required.** (common-sense inference)

**Key insight**: Both SP and FFS can serve rollout timing coordination. The critical difference is: SP is a permanent mechanism (stays after GA), while FFS is temporary (must be cleaned up after GA). When SP is already required for scope segmentation, reusing it for rollout timing avoids introducing a redundant temporary mechanism. FFS is uniquely needed only for A/B traffic splitting or when no SP exists to carry the rollout control. Always evaluate FFS **after** SP — if SP is already confirmed as required, check whether it can absorb the rollout timing need before introducing FFS.

---

### App Parameter — Customer Self-Service Opt-in / Opt-out Switch

App Parameter is the control mechanism. Scope can be **account level** (on/off switch for the entire account) or **user level** (on/off switch for individual users), determined by business need. Both scopes can coexist and are each judged independently.

**Decision signals**:

- **[PM Rule #7]** New feature needs to give customers the freedom to opt-in / opt-out at the account or user level → **App Parameter required** (scope determined by the desired granularity).
- Feature is mandatory and must not be disabled by customers (e.g., security fix, compliance requirement) → **Not required.** (common-sense inference)

**After introducing an App Parameter, always follow up**: Who has the right to operate this switch? This is a separate User Permission question (see "Judgment 2" under User Permission below). Do not skip this step.

---

### User Permission — Operation Access Control

**Critical distinction between App Parameter and User Permission** (understand this before judging):

- **App Parameter**: Controls whether a feature is **visible / available** to an account or user (on/off switch). Answers: "Can this person see / use this feature?"
- **User Permission**: Controls whether a user has the right to **perform a specific operation** (CRUD-level access). Answers: "Can this person do this action?"

Both often appear together in the same feature, governing different granularities. Do not conflate them.

---

**Judgment 1: Is User Permission needed to govern operation access within the feature?**

**Decision signal**: Does the feature contain a specific operation (create, edit, delete, view, etc.) where customer admins need to define which end users can execute it and which cannot?

- **[PM Rule #4]** For a specific feature setting (free or paid), customers need the ability to define which end users can execute it and which cannot → **User Permission required.**
- Before deciding: **Is this operation right for customer-side users, or for RC internal staff?** If it's for RC internal staff (support agents, SEs, product/engineering, etc.) → do not use User Permission; use **SCP Permission** instead. Only customer-side operation rights belong here.

---

**Judgment 2: Who has the right to operate the App Parameter switch? (Required after introducing an App Parameter)**

**Decision signal**: Should users be able to self-serve toggle the switch, or only specific admin roles?

- Users self-manage (toggling their own feature on/off) → additional User Permission restriction is typically not needed; App Parameter design already supports self-service.
- Only specific roles (e.g., super admin, department admin) should be allowed to operate the switch; other users cannot self-serve → **User Permission required** to restrict the operator.

---

**Existing Permission Lookup (applies to both Judgment 1 and Judgment 2)**

Before introducing any User Permission, **always check the existing permission catalog** to confirm whether a suitable permission already exists. Creating unnecessary new permissions causes permission catalog bloat.

> 📋 Existing Permission Catalog: [RingCentral Permission Reference](https://docs.google.com/spreadsheets/d/1qqx6fmwS129SthajeSIT_x84N1ohAA4JWrRfYGKs5_Q/edit?usp=sharing)

Lookup process:
1. Search the catalog above for an existing permission with semantically similar coverage
2. Found a suitable match → **Reuse the existing permission.** Do not create a new one.
3. No suitable match → **Create a new User Permission**, and document in the requirements why no existing permission covers this scenario.

---

## Common Mistakes to Avoid

- **Do not treat SP and FFS as the same thing.** A feature may need both (SP for scope segmentation, FFS for A/B timing), or only one. Judge them separately.
- **Do not conflate App Parameter and User Permission.** App Parameter governs feature visibility/availability (on/off). User Permission governs operation access (CRUD). They answer different questions and cannot substitute for each other.
- **After introducing an App Parameter, always determine the operator's permission.** Who can operate the switch is a User Permission question. Check the existing permission catalog before creating anything new.
- **User Permission applies only to customer-side users.** If the operation access is for RC internal staff (support, SE, etc.), use SCP Permission — not User Permission.
- **Always check the existing permission catalog before creating a new permission.** Refer to the [RingCentral Permission Reference](https://docs.google.com/spreadsheets/d/1qqx6fmwS129SthajeSIT_x84N1ohAA4JWrRfYGKs5_Q/edit?usp=sharing).
- **App Parameter is not account-level only.** It can be used at account or user level for opt-in/opt-out.
- **Free features may still require SP.** SP is a broad scope-segmentation tool, not tied to paid status. Entitlement is the mechanism directly linked to purchase status.

When the PM's stated facts conflict with any rule above, the PM's facts take precedence.

---

## SCP Permission — RC Internal Staff Access Control

> This mechanism is not in the original six-layer framework diagram, but exists as an independent control dimension in real-world scenarios and must be judged separately.

**SCP Permission** is an independent permission system that exclusively controls access for RC internal roles (support agents, Solution Engineers, Product/Engineering teams, etc.). It is completely separate from customer-side User Permission:

- Customers **cannot see** this layer and **cannot operate** it
- Customer admins cannot grant SCP Permission to anyone
- It controls **RC internal staff** access to features on customer accounts

**Decision signal**: Is there a need to restrict which RC internal staff can perform certain operations? **Note: Whether to introduce SCP Permission is entirely independent of whether the feature is available to customers.** Even if a feature is customer-facing, if any restriction on internal staff access is needed, SCP Permission applies.

**SCP Permission has two distinct purposes — judge each independently, and create a separate SCP Permission for each:**

---

**Purpose A — Control who can toggle a customer's feature switch in SCP**

When a customer account-level feature toggle is built in SCP, this permission controls which RC internal staff have the right to enable/disable that toggle in the SCP interface.

- Decision signal: Is a customer feature toggle being built in SCP?
  - Yes → **Create an independent SCP Permission** to control who can operate this toggle.
  - No → This purpose does not apply.

---

**Purpose B — Control who can log into a customer account to operate a customer-facing feature**

When a customer-facing feature requires RC internal staff to log into a customer account to operate it directly, SCP Permission controls which internal staff have the right to do so.

- Decision signal: Does this feature require RC internal staff to log into a customer account to operate it?
  - Yes → **Create an independent SCP Permission** to control this access right.
  - No → This purpose does not apply.

---

**When both purposes apply**: Create two separate SCP Permissions. Describe each in the requirements document separately, clearly identifying which operation each permission protects. Do not merge them into a single permission.

---

## Cross-Mechanism Collaboration Patterns (Derived from Real Cases)

### Pattern A: "Premium package feature, but sales needs the ability to grant access case by case"

**Applicable scenario**: A feature is intended by default only for a higher-tier service plan / package, but the sales team needs the ability to grant access to specific accounts (e.g., accounts above an MRR threshold) without requiring the customer to upgrade.

**Classic case**: AI Note is available by default only to Ultra package customers, but high-MRR Core/Advanced customers can be granted access by the sales team on a case-by-case basis, without upgrading.

**Solution**: Entitlement + SP in a two-layer collaboration

1. **Entitlement**: Add to **all packages that could potentially receive this feature** (including Core and Advanced, which do not get it by default) — not just the target package (Ultra).
   - Reason: Entitlement here defines **the range of accounts the sales team can act on**. If Core/Advanced accounts have no entitlement, enabling SP for them has no effect (AND logic: entitlement=false → result is always false).
2. **SP**: Set to **disabled** by default for Core/Advanced packages; set to **enabled** by default for Ultra.
   - SP controls the "default behavior," ensuring only Ultra accounts can use the feature day-to-day.

**Sales operation path**: To grant access to a specific Core account, sales only needs to enable SP for that account. This satisfies SP=true AND Entitlement=true, with no changes to the entitlement structure needed.

**Key insight**: Entitlement does not mean "who can use it by default" — it means "who is eligible to be enabled." Default availability is controlled by SP. The value of the two-layer design: Entitlement defines the eligible universe (all potential candidates); SP controls the default switch (only the target package is enabled by default).

**Trigger signals**:
- "This feature is for XX package by default, but we want to be able to make exceptions for specific customers"
- "Sales needs the ability to manually grant access to customers who don't qualify"
- "We don't want to force customers to upgrade but still want to give them access"

---

### Pattern B: "Closed Beta → GA lifecycle, with future add-on license monetization"

**Applicable scenario**: A new feature needs a closed beta (a small number of customers using it for free) before general availability, with plans to charge via an independent add-on license at GA. Beta customers should be able to transition seamlessly to the paid model.

**Classic case**: A new feature will be monetized via an add-on license at GA; during beta it is provided free to a small set of designated customers, who continue using it post-GA upon purchasing the add-on license.

**Solution**: Two-phase Entitlement anchor migration + FFS for temporary beta control

**Beta phase**:
1. **Entitlement**: Create a new entitlement for this feature and anchor it under the **subscription license fee** of all packages that may participate in the closed beta (i.e., included at no extra charge in the existing subscription).
2. **FFS**: Create a feature flag; enable it only for designated beta accounts (by mailbox ID), providing account-level availability control during the beta.
3. **Availability condition**: Entitlement=true AND FFS=true. Entitlement ensures no extra charge; FFS ensures only beta customers can access the feature.

**Pre-GA transition**:
4. **Migrate** the entitlement from the subscription license fee anchor to the new add-on license. Beta customers who purchase the add-on license automatically satisfy entitlement=true, and their FFS flag remains enabled — seamless continuation.

**Post-GA**:
5. **Remove the FFS flag logic.** Only entitlement (whether the customer has purchased the add-on license) remains as the sole control. FFS is a temporary tool; clean it up after GA to avoid leaving a permanent flag as technical debt.

**Key insights**:
- **FFS is temporary**: Its lifecycle is tied to the beta phase. After GA, there must be a defined exit plan (remove the flag logic). If the PM hasn't mentioned this, remind them to include the FFS sunset date in the requirements.
- **Entitlement anchor migrates**: Beta phase anchors under subscription fee (free); post-GA anchors under the add-on license (paid). This is an anchor change on the same entitlement, not creating a new entitlement.
- **Smooth transition for beta customers** depends on: completing entitlement migration + confirming customers purchase the add-on license, THEN removing FFS. Reversing this order will create a service outage window for beta customers.

**Trigger signals**:
- "We want to do a closed beta first, then charge later"
- "Beta is free; we'll add an add-on license at GA"
- "How do we make sure beta customers can keep using the feature after GA"
- "When can we retire the FFS flag"

---

### Pattern C: "Closed Beta accessible only to RC internal staff; opens to customers at GA"

**Applicable scenario**: A new feature is built on top of customer accounts, but during closed beta only RC internal staff (support agents, SEs, product/engineering, etc.) can access and operate it. Customers cannot see or use it. The feature opens to customers at GA.

**Classic case**: During beta, only RC internal staff can access and validate a new feature on customer accounts; customers cannot access it on their own.

**Solution**: FFS (beta phase account scope control) + SCP Permission (internal access control) → migrate to SP at GA

**Closed Beta phase**:
1. **FFS**: Create a FFS flag to control the customer account list eligible for closed beta. Add participating customer accounts (ext 101 / mailbox ID) to the FFS flag rules.
2. **SCP Permission (Purpose B — access to operate on customer accounts)**: Introduce a new SCP Permission. Build logic in the product that requires SCP Permission to be present before the feature can be accessed.
3. **Availability condition**: FFS=true AND has SCP Permission. FFS controls "which accounts are available"; SCP Permission controls "who can operate" — combined, only RC internal staff accessing FFS-enabled accounts can use the feature. Customers cannot access it under any circumstances.

**Pre-GA transition**:
4. Introduce **SP** to replace FFS, controlling which accounts the feature is available on. Availability condition becomes: SP=true AND has SCP Permission. FFS has served its purpose; retire it to avoid accumulating technical debt.

**Post-GA (opening to customers)**:
5. If the decision is made to open the feature for customers to self-operate, customers on SP-enabled accounts can self-access the feature. SCP Permission continues to govern internal staff access independently.

**Key insights**:
- **Pattern C corresponds to SCP Permission Purpose B** (access to operate on customer accounts): RC internal staff need to log into customer accounts to directly operate this feature; SCP Permission controls which internal staff have this right. Note: whether to introduce SCP Permission is independent of whether the feature is available to customers — if any internal staff restriction is needed, SCP Permission applies.
- **FFS is still a temporary tool here**: After the beta phase, migrate to SP. Do not let FFS permanently serve as the account scope control mechanism — SP is the proper tool for that.
- **Phases and availability conditions** — document each phase separately in the requirements:
  - Closed Beta: FFS=true AND has SCP Permission
  - Pre-GA transition: SP=true AND has SCP Permission
  - Post-GA (if opened to customers): SP=true (SCP Permission remains for internal staff access control)

**Trigger signals**:
- "During beta we only want internal staff to access it, not customers"
- "Support / SE / internal teams need to validate the feature on customer accounts first"
- "Customers shouldn't be able to operate this feature themselves (at least during beta)"
- "How do we restrict access to RC internal staff only"

---

### Pattern D: "Feature included in existing package at no extra charge; sales needs to grant access case by case without going through a development process"

**Applicable scenario**: A new feature is included in an existing package for free, available by default only to higher-tier plan customers. The sales team may need to grant access to individual customers at any time, and this must be achievable without going through an engineering process.

**Classic case**: A new feature is default-on only for high-tier plans. Support / SE needs to be able to toggle access on/off for specific accounts at any time without involving engineers.

**Solution**: SP (feature availability control) + SCP Permission Purpose A (protecting the operational interface)

1. **SP**: Introduce a new Service Parameter to control feature availability. Default value set by package tier (enabled for high-tier plans, disabled for others).
2. **SCP Permission (Purpose A — SCP toggle access)**: Build a feature enablement toggle in SCP for this feature. Only internal staff with SCP Permission can see and operate this toggle. Toggling on/off directly changes the SP value (enable or disable) for the target account. Sales can self-serve without filing engineering tickets.

**Availability condition**: SP=true (controlled by sales via the SCP toggle).

**Key insights**:
- **SCP Permission here corresponds to Purpose A (SCP toggle access)**: It protects "who can modify the SP value in the SCP interface," not "who can use the feature itself." This differs from Pattern C where SCP Permission corresponds to Purpose B (access to customer accounts). Document clearly in the requirements which operation the SCP Permission is protecting.
- **SP is the actual feature control mechanism**: The SCP toggle is only the path to modify the SP value. From an engineering perspective, feature availability is determined solely by SP; SCP is the tool that writes to SP.
- **"No development process" is a key requirement constraint**: This means SP values must be modifiable in real time through the SCP interface — not by code deployment. If the PM mentions this constraint, prioritize this pattern over a ticket-based engineering flow.
- Difference from Pattern A: In Pattern A, sales grants access by manipulating the Entitlement + SP combination (eligibility scope + default value). This pattern uses only SP, with the SCP toggle as the interface — applicable when no Entitlement-level eligibility segmentation is needed, only SP default value control + real-time manual override by sales.

**Trigger signals**:
- "Sales needs to be able to grant or revoke access for individual customers at any time"
- "We don't want to file an engineering ticket every time"
- "Support or SE needs to be able to self-serve in the back end"
- "The feature is free, but not all plans have it on by default"

---

### Pattern E: "Feature involves user privacy / personal data; off by default; requires user-level granular control"

**Applicable scenario**: A new feature accesses user personal data or privacy-sensitive information. The user-side requirement is that it be off by default, enabled only for individual users on demand. Independent controls are needed at both the account level and the user level.

**Classic case**: An AI feature reads user personal profile data. It is off by default. Admins or users themselves decide whether to enable it for specific users.

**Solution**: SP (account-level master switch) + User-level App Parameter (user-level switch) + optional User Permission (governing who can operate the App Parameter)

1. **SP**: Introduce a Service Parameter as the account-level master switch for the entire feature. When SP=false, no user in the account can use the feature, regardless of their individual App Parameter state.
2. **User-level App Parameter**: Introduce an App Parameter at the user level to control whether the feature is enabled for individual users. The default value is determined by the PM based on the business context — always confirm this explicitly; do not assume. SP=true AND that user's App Parameter=true → the user can access the feature.
3. **(Optional) User Permission**: Depending on governance needs, optionally create a User Permission to control who has the right to operate the user-level App Parameter switch. If only admins should be able to enable it for users (not self-service by users themselves), this layer is needed.

**Availability condition**: SP=true AND User App Parameter=true (AND User Permission, if the third layer is introduced).

**Key insights**:
- **SP is the mandatory account-level prerequisite**: Even if a user's App Parameter is true, SP=false means the feature is still off for the entire account. SP answers "does the account want this feature enabled"; App Parameter answers "given the account decision, which specific users can use it." They govern different granularities.
- **The default value is a design decision that must be made explicitly**: The default value of App Parameter (enable or disable) depends on the specific scenario and business decision — there is no universal answer. If the PM has not stated the default value, ask explicitly and document it in the requirements. Do not assume.
- **User Permission is optional**: Whether to introduce the third layer depends on who should have the right to toggle the switch for users. User self-service → no additional Permission needed; admin-managed only (users cannot self-serve) → User Permission needed to restrict the operator. This is a governance design decision — the PM must make a clear call.
- Difference from Pattern D: In Pattern D, the switch is operated by RC internal sales staff (via SCP toggle to change SP). In this pattern, the switch is operated by the customer side (admins or users themselves). The ownership of control differs.

**Trigger signals**:
- "This feature involves user privacy / personal data"
- "It should be off by default; users or admins need to actively turn it on"
- "We need to enable it for individual users, not the entire account all at once"
- "Users should be able to choose whether they want to be covered by this feature"
