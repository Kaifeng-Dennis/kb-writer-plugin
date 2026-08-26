---
name: pm-competitive-analysis
description: Produce evidence-backed feature competitive analysis in Chinese or English as Word or HTML. Use for competitor UX, pricing, capability gaps, and roadmap across RingCentral product lines.
---

# PM Competitive Analysis

## Start

1. Treat the current conversation as one competitive analysis workspace. Do not create separate local workflow state.
2. Complete all Step 0 gates before any research, browsing, screenshot capture, or report drafting.
3. Accept feature requests, corrections, confirmations, and follow-up instructions in Chinese or English.

## Goal

Produce a polished, evidence-backed report in the user-selected language and output format that answers:

1. Who offers the feature?
2. How is it implemented and packaged?
3. How deep is each implementation?
4. What should our product build, buy, partner on, defer, or watch?

Write for PM, design, engineering, and leadership. Keep an executive decision layer, a product/UX evidence layer, and an engineering depth layer in one report.

## Operating rules

- Center the analysis on one feature or tightly coupled capability cluster.
- Browse before drafting. Treat feature availability, pricing, packaging, roadmaps, and screenshots as time-sensitive.
- Prefer official product pages, help centers, developer docs, pricing pages, release notes, and changelogs. Use credible secondary sources only to fill gaps or add customer perspective.
- Attach a source URL and access date to every material external finding.
- Mark unsupported precision as `Unknown`, estimates as `[Est.]`, and evidence-based inference as `[Inferred]`.
- Distinguish missing evidence from missing capability. Never convert "not found" into `✗`.
- Do not invent screenshots, prices, customer impact, win/loss evidence, or roadmap commitments.
- Finish research and the evidence matrix before drafting narrative conclusions.
- Use user-provided products, competitors, scope, templates, and output locations before defaults.
- Before the report language is locked, use the language of the user's latest substantive message for setup prompts. After it is locked, use the selected report language for the artifact and normal progress communication unless the user asks otherwise.
- Do not browse, search connected sources, collect screenshots, or start analysis until the product line, competitor set, report language, and output format pass the gates in Step 0.

## Step 0 — Configure the analysis

Treat this step as a mandatory interaction gate. Complete all applicable gates before any research. Do not repeat a choice the user already stated explicitly; ask only for missing choices.

### Gate A — Product-line selection

Do not infer a product line from the feature name and silently continue.

If the user has not explicitly selected a product line, present these choices and ask them to choose one:

1. Video / Meetings — RCV
2. Apps — RingCentral app surfaces, messaging, phone, and related in-app functions
3. Service Web — web-based service and administration
4. RCX — RingCX contact center / CCaaS
5. AI — RingSense / RingCX AI, conversational AI, voice AI, IVA, and agents
6. Integrations — integrations and marketplace
7. DPW — Developer Platform / Web, APIs, SDKs, and embeddable communications
8. Cross-product — a feature intentionally spanning multiple product lines

Use a concise prompt in the user's current language:

> 开始分析前，请先选择产品线：Video / Meetings、Apps、Service Web、RCX、AI、Integrations、DPW，或 Cross-product。也可以直接回复编号。

> Before the analysis starts, choose a product line: Video / Meetings, Apps, Service Web, RCX, AI, Integrations, DPW, or Cross-product. You can reply with its number.

Pause for the answer. If the triggering request already names one of these product lines explicitly, treat it as the selection and move directly to Gate B. Do not treat a feature-based inference as an explicit selection.

For `Cross-product`, ask the user to name the included product lines and select one primary "Our Product" framing.

### Gate B — Competitor confirmation

After the product line is selected:

1. Retrieve the matching `Our Product` and default competitors from the table below.
2. Show the selected product line, `Our Product`, and full competitor list.
3. Ask whether the list is correct and invite the user to add, remove, replace, or reorder competitors.
4. Require confirmation before continuing.

Treat the default competitor table as persistent skill configuration and the confirmed competitor list as task-local state:

- Never edit, overwrite, or permanently remove an entry from the default competitor table merely because a user changes the competitor set for one analysis.
- Apply additions, removals, replacements, and ordering changes only to the current analysis unless the user explicitly asks to update the skill's defaults.
- Start every new analysis from the full default list for its selected product line, regardless of edits made in earlier analyses.
- When the user asks to change the skill's defaults, distinguish that request explicitly from a task-local competitor edit before modifying the table.

Use the response pattern matching the user's current language:

> 已选择产品线：**[Product Line]**  
> 我方产品：**[Our Product]**  
> 默认竞品：**[Competitor A]、[Competitor B]、…**  
>  
> 请确认这组竞品是否正确。你可以回复“确认”，也可以直接说明需要添加、删除、替换或调整顺序的竞品。

> Selected product line: **[Product Line]**  
> Our Product: **[Our Product]**  
> Default competitors: **[Competitor A], [Competitor B], ...**  
>  
> Please confirm whether this competitor set is correct. Reply `confirm`, or tell me which competitors to add, remove, replace, or reorder.

If the user replies `确认`, `confirm`, `confirmed`, `looks good`, `proceed`, or another unambiguous approval, lock the default list. If the user supplies an explicit replacement list or clear edits and says to proceed, lock the edited list. If the edits are ambiguous or do not clearly authorize proceeding, restate the resulting list and ask for confirmation once more.

After locking the list:

- Use exactly the confirmed competitors for research and report tables.
- Do not reintroduce omitted defaults.
- Do not silently add "obvious" competitors.
- Record user-added competitors and removals as task-local scope choices, not market findings or changes to the skill's default configuration.
- Reopen Gate B if the user changes the product line later.

### Gate C — Report language and output format

Require one report-language choice and one output-format choice before research:

- Report language: `中文` / `Chinese` or `English` / `英文`
- Output format: `Word` / `.docx` or `HTML` / `.html`

Normalize common replies such as `zh`, `zh-CN`, `中文报告`, `Chinese report`, `en`, `英文`, `English report`, `docx`, `Word document`, `网页`, and `HTML page`. Do not treat the language of the user's instruction as the report-language choice unless the user explicitly says the report should use that language.

If both choices are missing, use the prompt matching the user's current language:

> 请选择报告语言和输出格式：  
> 语言：1. 中文　2. English  
> 格式：A. Word（.docx）　B. HTML（.html）  
> 可以直接回复 `1A`、`1B`、`2A` 或 `2B`。

> Choose the report language and output format:  
> Language: 1. Chinese　2. English  
> Format: A. Word (.docx)　B. HTML (.html)  
> Reply with `1A`, `1B`, `2A`, or `2B`.

If one choice is already explicit, ask only for the missing choice. Restate the locked configuration:

> 报告语言：**[中文 / English]**  
> 输出格式：**[Word / HTML]**

> Report language: **[Chinese / English]**  
> Output format: **[Word / HTML]**

After locking these choices:

- Write headings, narrative, table labels, captions, alt text, recommendations, and limitations in the selected report language.
- Preserve official product names, plan names, API names, URLs, and source titles unless a verified localized name is available.
- Continue to understand user instructions in either Chinese or English even when they differ from the selected report language.
- Reopen Gate C only if the user changes the requested language or format.

### Gate D — Feature scope and context

After the product line, competitor set, report language, and output format are confirmed:

1. Confirm the feature name and boundary only if they remain unclear.
2. Record a one-sentence scope statement and explicit in-scope/out-of-scope lists.
3. Inspect internal context supplied by the user. If a relevant connected source is available, search it for the feature, product, confirmed competitors, PRDs, design mocks, win/loss notes, research, and roadmap material. Otherwise continue with public evidence and state the limitation.

Do not ask the user to choose a "strategy" or "product" mode. Combine both.

### Product-line defaults

Use this table only after the user selects a product line. Treat it as persistent starting configuration, not current market evidence. Do not mutate it based on a user's choices in an individual analysis. Re-check public product naming during research.

| Product Line | Covers | Our Product | Default Competitors |
|---|---|---|---|
| Video / Meetings | Video meetings, webinars, rooms | RCV | Zoom, Microsoft Teams, Google Meet, Cisco Webex, 8x8 |
| Apps | UCaaS app, messaging, phone, and related in-app functions | Apps | 8x8, Zoom, Slack, Microsoft Teams, Cisco Webex |
| Service Web | Web-based service and administration | SW | Zoom, 8x8, Dialpad, Cisco Webex |
| RCX | Contact center / CCaaS | RingCX | Genesys Cloud CX, NICE CXone, Five9, Amazon Connect, Avaya, Twilio Flex |
| AI | Conversational AI, voice AI, IVA, and agents | RingSense / RingCX AI | Poly.ai, Zoom IVA, Sierra AI, Cresta, Cognigy, Dialpad, Omilia, xAI, Vapi |
| Integrations | Third-party integrations and marketplace | RingCentral Integrations | Zoom, 8x8, Cisco Webex, Vonage |
| DPW | Developer Platform / Web, APIs, SDKs, and embeddable communications | RingCentral Developer Platform | Twilio |

## Step 1 — Research

Begin only after Step 0 is complete. Research every confirmed competitor and no unconfirmed competitors before writing. Run independent searches in parallel when the available tools allow it.

For each competitor, investigate:

- `[competitor] [feature] how it works`
- `[competitor] [feature] help OR documentation`
- `[competitor] [feature] pricing OR plans`
- `[competitor] [feature] changelog OR release notes`
- `[competitor] [feature] API OR integration`, when relevant

Capture:

- status: full, partial, absent, unknown, beta, roadmap, or discontinued;
- entry point and end-to-end interaction model;
- sub-capabilities and limitations;
- plan/tier availability, add-ons, usage limits, and price signal;
- technical constraints, dependencies, APIs, integrations, data handling, and admin controls;
- source URL, source type, publication/update date when visible, and access date;
- a real product screenshot or clearly labeled illustrative diagram for each competitor included in the UX section.

Prefer primary sources for facts. Use reviews, analyst material, forums, or videos as corroboration or user-sentiment evidence and label them as secondary. Resolve conflicts by favoring the newest authoritative source and noting the discrepancy.

### Visual evidence workflow

Acquire visuals in this order:

1. Search official product pages, help centers, developer docs, release notes, and changelogs.
2. Open public interactive pages in the in-app browser when client-side rendering, expansion, or scrolling is required.
3. Use user-provided or authorized connected internal sources.
4. Use current, credible secondary sources when official imagery is unavailable.
5. Use an official demo video and record its URL and timestamp. Capture a frame only when tools and source terms permit it.
6. Create a simplified illustrative diagram only when no usable real visual is available.

Follow these truthfulness rules:

- Never label an AI-generated or reconstructed visual as a screenshot.
- Never infer exact styling, labels, or controls unsupported by the source.
- Never expose private account data, personal information, or material outside authorized access.
- Preserve the source URL and capture/access date.
- Treat marketing artwork as marketing imagery, not proof of product behavior.
- Do not crop away qualifiers, beta labels, plan names, or context that changes interpretation.

For an illustrative fallback:

1. Read the source documentation closely.
2. Use the available image-generation skill to create a neutral product-flow or wireframe diagram.
3. Include only evidenced entry points, actions, states, and terminology.
4. Avoid photorealistic or pixel-identical imitation.
5. Place `ILLUSTRATIVE — BASED ON PUBLIC DOCUMENTATION` visibly in the image.
6. Cite the source documentation and mark inferred elements.

Include at least one evidence-bearing visual per competitor discussed in depth and no more than three. Prefer entry point, configuration, and result/confirmation views. Redact unrelated personal, customer, or tenant data.

For Word, embed visuals no wider than 6.5 inches. For HTML, use responsive visuals with `max-width: 100%`. Preserve aspect ratio, add useful alt text, and keep captions with visuals. Use:

- Real: `Figure [N]: [Competitor] — [what the image demonstrates]. Source: [URL]. Captured [Month Year].`
- Illustrative: `Figure [N]: [Competitor] — illustrative [flow/state]. Source: Illustrative, based on [URL]. [Month Year].`
- Internal: `Figure [N]: [Competitor] — [description]. Source: [document/file identifier]. Accessed [Month Year].`

## Step 2 — Build the evidence matrix

Create a working matrix before drafting:

| Claim or sub-capability | Our Product | Competitor A | Competitor B | Source | Confidence | Notes |
|---|---|---|---|---|---|---|

Use:

- `High`: current official documentation, product UI, pricing page, or release note;
- `Medium`: credible recent secondary source or multiple consistent indirect sources;
- `Low`: weak, stale, conflicting, or single-source indirect evidence.

Use `?` whenever evidence is insufficient. Keep recommendations separate from verified facts.

## Step 3 — Draft the report

Use this section order exactly. Render section titles in the selected report language:

| # | English | 中文 |
|---|---|---|
| 1 | Cover Page | 封面 |
| 2 | Executive Summary | 执行摘要 |
| 3 | Feature Scope Definition | 功能范围定义 |
| 4 | Competitive Landscape Snapshot | 竞争格局概览 |
| 5 | Feature Depth Table | 功能深度对比 |
| 6 | UX & Interaction Analysis | 用户体验与交互分析 |
| 7 | Pricing & Packaging | 定价与包装 |
| 8 | Roadmap Implications & Prioritized Backlog | 路线图影响与优先级 Backlog |
| 9 | Strategic Recommendations | 战略建议 |
| 10 | Appendix | 附录 |

Translate all fixed labels, status words, confidentiality notices, table headers, and recommendation metadata into the selected report language while preserving the defined categories and meaning.

### 1. Cover Page

Include the report title, a localized equivalent of `Feature Deep-Dive — Internal Use Only`, current date, localized prepared-for and prepared-by lines, and a localized equivalent of `Confidential — Internal Use Only`. Omit the running header and footer on the cover.

### 2. Executive Summary

Keep to half a page and 3–5 conclusion-first bullets. End with one sentence naming the single most important action. Tie conclusions to supported customer, competitive, product, or technical implications.

### 3. Feature Scope Definition

State the boundary in one short paragraph followed by `In scope` and `Out of scope` bullets.

### 4. Competitive Landscape Snapshot

| Competitor | Has Feature? | Tier Available | Maturity | One-Line Summary |
|---|---|---|---|---|

Use `Mature`, `GA`, `Beta`, `Roadmap`, or `None`. Mark estimates `[Est.]`.

### 5. Feature Depth Table

| Sub-capability | Our Product | Competitor A | Competitor B | … | Depth Notes |
|---|---|---|---|---|---|

- Place `Our Product` immediately after `Sub-capability` and shade it `F5F5F5`.
- Use `✓` for full, `~` for partial, `✗` for verified absence, and `?` for unknown.
- Group 10–30 rows under bold capability-area rows.
- Use `Depth Notes` for best-in-class interaction, implementation nuance, limitation, or engineering implication.

### 6. UX & Interaction Analysis

For each competitor with meaningful evidence, include:

- **Entry point**
- **Key UX pattern** in 2–4 sentences
- **What they do well** in 1–3 bullets
- **What is weak or missing** in 1–3 bullets
- **Visual evidence** with a real screenshot or explicitly illustrative diagram

Mark UI descriptions derived from docs rather than direct observation as `[Inferred from docs]`.

### 7. Pricing & Packaging

| Competitor | Feature Availability | Tier | Price Signal | Notes |
|---|---|---|---|---|

Decide whether the feature is table stakes, a paid differentiator, an enterprise gate, an add-on, or not commercially packaged. State the implication for our packaging.

### 8. Roadmap Implications & Prioritized Backlog

| Capability Gap | Competitors Who Have It | Deal/Retention Impact | Effort | Recommended Call | Target Quarter |
|---|---|---|---|---|---|

- Describe gaps in user-facing language.
- Use `High`, `Medium`, or `Low` impact with fills `FFEBEE`, `FFF9C4`, and `F0FFF4`.
- Use `S`, `M`, `L`, or `XL` effort.
- Commit to `Build`, `Buy`, `Partner`, `Defer`, or `Watch`.
- Use a concrete quarter only when justified; otherwise use `Defer` or `Watch`.
- Sort by impact descending, then effort ascending.

Add 3–6 short paragraphs covering the minimum viable cluster, the top three items with dependencies and risks, and explicit deferrals with reasons.

### 9. Strategic Recommendations

Write 3–5 numbered recommendations:

> **[N]. [Action verb + specific action]**  
> *Rationale:* [finding-backed reason]  
> *Audience:* [PM / Engineering / Leadership / Design]  
> *Priority:* [P0 / P1 / P2]

Make the first recommendation the build/no-build decision. Use `P0` for this quarter, `P1` for next quarter, and `P2` for watch/defer unless the user provides another convention.

### 10. Appendix

Include sources and URLs with access dates, screenshot credits, the `✓ / ~ / ✗ / ?` legend, `[Est.]` and `[Inferred]` definitions, freshness and evidence limitations, and internal-source identifiers when permitted.

## Step 4 — Build and verify the selected output

Apply these requirements to both formats:

- Keep the exact ten-section order from Step 3.
- Use the selected report language consistently.
- Preserve evidence status, source URLs, access dates, legends, and visual truthfulness.
- Remove raw tool-citation tokens and internal QA notes from the deliverable.
- Inspect the complete final artifact after the last content or layout change.

### Word output

Use the available `documents` skill and follow its render-and-verify workflow. Load its workspace document dependencies. Do not rely on system Python, system Node, or ad hoc global packages.

Use the `standard_business_brief` preset unless the user supplies a template. Apply these report overrides:

- US Letter portrait, 1-inch margins, 9360 DXA usable width;
- Arial 11 pt body; Heading 1 at 28 pt, Heading 2 at 22 pt, Heading 3 at 16 pt;
- real Word headings, outline levels, bullets, and numbering;
- table header fill `D5E8F0`, bold text, repeating headers;
- cell margins: top/bottom 80 DXA, left/right 120 DXA;
- no fixed row heights;
- centered footer: `Page X of Y`;
- running header after the cover: title left and `Confidential — Internal Use Only` right;
- captions immediately after visuals, centered, italic, 9 pt, color `666666`.

Render and inspect every page at 100%. Check for clipping, overlap, missing glyphs, broken tables, weak padding, bad page breaks, incorrect headers/footers/captions, fake bullets/headings, unsupported claims, raw tool-citation tokens, and disagreements between claims, tables, and sources. Fix, re-render, and inspect again.

Deliver only the final `.docx`, not QA files, unless asked.

### HTML output

Create a single standalone `.html` file unless the user supplies a template or explicitly requests a multi-file site. Do not deploy or host it unless the user asks.

- Use semantic HTML: one `<h1>`, ordered `<h2>` sections, meaningful `<h3>` subsections, `<nav>` table of contents, `<figure>/<figcaption>`, and proper `<table>`, `<thead>`, `<tbody>`, and `<th scope>` structure.
- Embed CSS in the file. Use an Arial-first font stack, the same restrained business palette as the Word report, readable line lengths, sticky or repeatable table headers where practical, and responsive horizontal scrolling for wide comparison tables.
- Keep images self-contained with data URIs when practical. If image size makes this unreasonable, place assets beside the HTML in one output folder and use relative paths; state that the folder must remain intact.
- Add descriptive `alt` text in the selected report language and preserve visible qualifiers such as beta labels or illustrative-image notices.
- Make every source URL clickable. Add a print stylesheet that keeps headings with their first content block, avoids splitting figures when practical, and renders cleanly on US Letter.
- Avoid unnecessary JavaScript. If filtering or table navigation genuinely improves a large report, keep it local, dependency-free, and usable without JavaScript.
- Verify the HTML through the available browser-control skill using a local HTTP server. Inspect the entire report at a desktop viewport and a narrow mobile viewport, test the table of contents and source links, and check print layout. Fix overflow, clipped tables, broken images, unreadable text, missing alt text, and console errors.

Deliver only the final `.html` file or its self-contained output folder, not QA screenshots or temporary server files, unless asked.

## Style

- Lead with conclusions, then evidence.
- Use short, active sentences.
- Avoid marketing adjectives, emoji, exclamation marks, and hedging filler.
- Name exact tiers, prices, limits, patterns, and dates when verified.
- Separate facts, estimates, inferences, and recommendations.
- Use a professional internal-report voice.

## Output

Save to the user-requested location. Otherwise use the workspace's user-facing `outputs/` directory:

- Word: `feature-comp-[product-line]-[feature-slug].docx`
- HTML: `feature-comp-[product-line]-[feature-slug].html`

Deliver the selected format only. If the user explicitly requests both Word and HTML, confirm that exception and generate both from the same locked evidence matrix. For Word, follow the `documents` skill's final-delivery link/citation contract. For HTML, provide a direct link to the final local artifact. Summarize the result in one sentence without a process postamble.

## Calibration example — CSV export and scheduling

Treat this as hypothetical structure and tone guidance only. Never reuse its claims, prices, impact statements, or dates as evidence.

### Executive takeaways

- Scheduled export is the largest gap in the hypothetical set: two competitors offer recurring delivery while Our Product supports manual export only.
- Competitor A combines column selection, scheduling, SFTP, and notifications in one workflow.
- Competitor B gates scheduling to Enterprise, while A offers it one tier lower.
- First action: validate demand, then prioritize column selection, recurring schedules, and email delivery as one cluster.

### Scope

**In:** CSV/XLSX, field selection, schedules, download/email/SFTP/cloud delivery, completion/failure notifications.

**Out:** API export, webhooks, streaming, PDF/chart export, and migration tooling.

### Depth-table sample

| Sub-capability | Our Product | Competitor A | Competitor B | Competitor C | Depth Notes |
|---|---|---|---|---|---|
| One-click export | ✓ | ✓ | ✓ | ✓ | Hypothetical table stakes |
| Column selection | ✗ | ✓ | ✓ | ✗ | A uses a reorderable field picker |
| Recurring schedule | ✗ | ✓ | ✓ | ? | A exposes daily, weekly, monthly presets |
| Email delivery | ✗ | ✓ | ✓ | ✗ | A permits external recipients |
| SFTP/cloud storage | ✗ | ✓ | ✓ | ✗ | A supports SFTP and object storage |
| Completion notification | ✗ | ✓ | ✓ | ✗ | Verify failure-state UX separately |

### Roadmap sample

| Capability Gap | Competitors Who Have It | Impact | Effort | Call | Target |
|---|---|---|---|---|---|
| Receive reports on a schedule | A, B | High | M | Build | `[validated quarter]` |
| Choose and reorder fields | A, B | High | M | Build | `[validated quarter]` |
| Deliver by email | A, B | High | S | Build | `[validated quarter]` |
| Deliver to SFTP/cloud | A, B | Medium | L | Partner | Watch |
| Notify a collaboration channel | A | Low | M | Defer | Defer |

Use field selection, recurring schedules, and email delivery as the hypothetical minimum viable cluster. Defer SFTP until enterprise demand and credential ownership are validated. Defer collaboration notifications because they do not complete the core workflow.

### Recommendation sample

> **1. Build the minimum scheduled-export cluster after demand validation.**  
> *Rationale:* Manual export alone does not close the demonstrated workflow gap.  
> *Audience:* PM, Engineering, Leadership  
> *Priority:* P0

> **2. Package scheduling below the top enterprise tier if pricing research supports it.**  
> *Rationale:* A lower gate could differentiate without giving away automation.  
> *Audience:* PM, Leadership  
> *Priority:* P0

> **3. Defer SFTP until security, credential ownership, and deal demand are clear.**  
> *Rationale:* It adds enterprise value but expands implementation and operational risk.  
> *Audience:* PM, Engineering  
> *Priority:* P1
