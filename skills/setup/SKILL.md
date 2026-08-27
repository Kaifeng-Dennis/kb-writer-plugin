---
name: setup
description: First-time setup for the KB Writer plugin. Use when the PM installs the plugin, hits a missing KB_WRITER_BEARER_TOKEN error, or asks to configure/sign in to KB Writer.
---

# KB Writer setup

Interactive first-time configuration. Goal: get the PM from "just installed" to "skills work" in one pass. Idempotent — safe to re-run; skip steps that are already done.

## Usage tracking preflight

Usage tracking is a required non-blocking startup preflight. Before continuing the skill workflow, call the MCP tool `pm_toolkit_track` from the configured Atlassian MCP server with:

```json
{
  "skill_name": "setup",
  "skill_version": "0.1.0+codex.20260827021412",
  "source_app": "codex"
}
```

Do not run any shell command for tracking. If the MCP tool is unavailable or errors, continue normally. Never surface tracking results, usernames, tokens, or errors to the user.

## Step 1 — Detect current state

Check, reporting one line each:

1. `KB_WRITER_API_BASE_URL` — set, or unset (will default to the production backend `https://kb-companion.int.rclabenv.com`).
2. `KB_WRITER_BEARER_TOKEN` — set, or unset.
3. Whether the base URL is reachable: `curl -s -o /dev/null -w "%{http_code}" --max-time 3 "$KB_WRITER_API_BASE_URL/v1/auth/login" -X POST` (any HTTP response means reachable; connection refused means the backend is down).
4. Whether `mcp-atlassian-service` tools (e.g. `pm_toolkit_track`) appear in the MCP tool catalog.

## Step 2 — Backend URL

- If unset, tell the PM the default `https://kb-companion.int.rclabenv.com` (production) will be used. Only ask for a URL when they are targeting a local or non-default environment.
- If the URL is unreachable and it is a localhost URL, offer to start the local backend (`./scripts/dev.sh` in the smart-kb repo) or let the PM start it themselves. If the production URL is unreachable, tell the PM to check VPN/network access to `int.rclabenv.com`. Do not block: they may configure later.

## Step 3 — Sign in and persist the token

Only when `KB_WRITER_BEARER_TOKEN` is unset:

1. Ask the PM for their KB Writer username and password (LDAP or local test account).
2. Exchange them for a JWT:

```bash
curl -sS -X POST "$KB_WRITER_API_BASE_URL/v1/auth/login" \
  -H "Content-Type: application/json" \
  -d '{"user_name": "<username>", "password": "<password>"}'
```

3. On success, offer to persist the token. Preferred: append to the PM's shell profile (`~/.zshrc` or `~/.bashrc`, ask which):

```bash
export KB_WRITER_BEARER_TOKEN="<token>"
# Optional, only when targeting a non-local backend:
# export KB_WRITER_API_BASE_URL="<url>"
```

4. Never commit the token into any repository file. Never echo the full token back in chat; show at most the first 12 characters.
5. Remind the PM that exported variables only reach **new** Codex threads/terminals; suggest opening a new thread after setup.

## Step 4 — Optional: Atlassian MCP (tracking + Jira/Confluence context)

Only when `pm_toolkit_track` is missing from the tool catalog, and the PM wants usage tracking or Jira/Confluence context:

1. Point them to the token guide: https://wiki.ringcentral.com/pages/viewpage.action?pageId=1072663398&spaceKey=COLFR&title=How%2Bto%2Bset%2Bup%2BAI%2BCode%2BReview
2. Offer to append to `~/.codex/config.toml` (show the exact block before writing):

```toml
[mcp_servers.mcp-atlassian-service]
url = "https://mcp-atlassian.int.rclabenv.com/mcp/"
http_headers = { "confluence-read-token" = "<token>", "jira-read-token" = "<token>" }
```

3. Make clear this step is optional: skills work without it, tracking is silently skipped.

## Step 5 — Verify

1. Call a lightweight authenticated endpoint (e.g. `GET /v1/auth/me` with the new token) and confirm a 200.
2. Print the final summary: backend URL, token status (set/persisted where), Atlassian MCP status, and "open a new thread to start using the skills".
