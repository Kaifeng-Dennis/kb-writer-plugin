---
name: create-kb-intent
description: Reduce a completed local coding session into a PM-reviewed CompletionEnvelopeV1 and create a KB Writer Intent Workspace. Use for explicit local-session “create KB intent” requests; do not use it to infer article identity, bind targets, start drafts, or publish.
---

# Create KB intent

Prepare a bounded transfer from authorized local-session evidence. KB Writer owns the envelope contract, durable Workspace, interpretation, targets, Manifest, generation, and publication state.

Before constructing an envelope, read [the accepted CompletionEnvelopeV1 schema](references/completion-envelope.schema.json). Emit no fields outside it.

## Usage tracking preflight

Usage tracking is a required non-blocking startup preflight. Before continuing the skill workflow, call the MCP tool `pm_toolkit_track` from the configured Atlassian MCP server with:

```json
{
  "skill_name": "create-kb-intent",
  "skill_version": "0.1.0+codex.20260827021238",
  "source_app": "codex"
}
```

Do not run any shell command for tracking, including legacy local tracker scripts, `/bin/sh`, or `curl`. If the MCP tool is unavailable, missing from the tool catalog, or returns an error, continue the skill workflow normally without retrying through the shell. Never surface tracking results, usernames, tokens, or errors to the user.


## Connectivity

This plugin calls the KB Writer backend over authenticated HTTPS. Resolve configuration from the host environment:

- `KB_WRITER_API_BASE_URL` — base URL of the KB Writer backend (for example the local dev backend on `http://localhost:8080` or a deployed environment URL).
- `KB_WRITER_BEARER_TOKEN` — the PM's own JWT from `POST /v1/auth/login`, or a personal access token when available.

If either variable is missing, stop and ask the PM to configure it; never invent a base URL, token, or alternate identity.

If the host has the `kb-writer` MCP server registered, prefer its tools over raw HTTP for capability calls; the tool schemas pass stable IDs, idempotency keys, and concurrency tokens unchanged. Raw HTTPS via the two variables remains the fallback when MCP is not registered.

## Reduce locally

Use only evidence available through the current host-authorized local session: the user's statements, session summary, changed-artifact descriptors, validation output, and raw content the PM may choose to transfer. Do not supplement it with backend article search, a guessed Jira issue, inferred article identity, unrelated repository history, the full transcript, environment variables, credentials, or unselected files.

Keep three labels in the transfer preview:

- **Facts**: direct user statements or observed session evidence, each with provenance.
- **Inferences**: proposed interpretations that are visibly non-factual. Do not silently turn them into decisions or evidence.
- **Unknowns**: missing or unresolved information; place relevant feature unknowns in `feature.unresolvedIssues`.

For every included raw `selectedEvidence` item:

1. show its declared type and provenance;
2. scan it with the host's secret/PII policy tools;
3. calculate `integrityHash` as lowercase `sha256:<64 hex>` over the exact UTF-8 content that would be sent;
4. use only `text/plain`, `text/markdown`, or `application/json` inline content;
5. keep each item at or below 262,144 UTF-8 bytes and all items together at or below 524,288 bytes;
6. set `included: true` and omit `uploadHandle`.

Artifact paths are descriptors, not identity. Preliminary hashes support transfer integrity only; the server computes the authoritative persisted content identity.

## Show the complete transfer preview

Before any state-changing capability call, display one preview containing:

- editable feature goal and completion summary;
- Facts, Inferences, and Unknowns with provenance;
- decisions, constraints, validation results, and unresolved issues;
- every changed-artifact descriptor;
- every included evidence item with declared type, provenance, digest, byte size, and expandable exact raw content;
- excluded transcript, files, outputs, secrets, policy-rejected content, and user exclusions, each with a reason;
- destination KB Writer account and authenticated identity;
- the exact idempotency key and complete outbound `CompletionEnvelopeV1` JSON;
- actions equivalent to `Cancel`, `Edit scope`, and `Confirm and create KB intent`.

Do not call `create_intent_workspace` while rendering or editing this preview. An earlier request to hurry, infer scope, skip preview, or “send whatever context you have” is not the required confirmation: confirmation must be an explicit PM action after seeing this exact preview.

## Submit only after confirmation

After the PM explicitly chooses **Confirm and create KB intent**, submit the exact previewed envelope unchanged:

```bash
curl -sS -X POST "$KB_WRITER_API_BASE_URL/v1/intent-workspaces" \
  -H "Authorization: Bearer $KB_WRITER_BEARER_TOKEN" \
  -H "Content-Type: application/json" \
  -H "Idempotency-Key: <the previewed idempotency key>" \
  --data-binary @<the exact previewed envelope JSON file>
```

Pass the exact previewed envelope and idempotency key unchanged. Do not add a Jira key, target, inferred article, server state, Manifest state, generation trigger, approval, or publication input. The response returns `workspaceId`, `workspaceVersion`, and `planningJobId`.

For read-only follow-up in the same session, poll planning status with:

```bash
curl -sS "$KB_WRITER_API_BASE_URL/v1/intent-workspaces/planning-jobs/<planningJobId>" \
  -H "Authorization: Bearer $KB_WRITER_BEARER_TOKEN"
```

If validation rejects evidence or otherwise changes the reviewed transfer scope, render the complete revised preview and require a new explicit confirmation. A retry of the same accepted request may reuse its exact idempotency key and payload; never reuse a key with changed input.

After acceptance, retain only the minimal server Workspace handle (`workspaceId`, `workspaceVersion`, `planningJobId`) needed to reopen the work. You may explain or poll the returned planning job. Article discovery remains read-only; never bind even a top-ranked candidate. Target selection, Manifest approval (`POST /v1/intent-workspaces/{id}/manifest/start-drafts`), Draft overwrite, destination choice, and publication are separate explicit PM actions governed by server-returned stable IDs and concurrency tokens.
