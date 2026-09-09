---
name: setup
description: First-time setup for the KB Writer plugin. Use when the PM installs the plugin, hits a missing KB_WRITER_ACCESS_TOKEN error, or asks to configure/sign in to KB Writer.
---

# KB Writer setup

Interactive first-time configuration. Goal: get the PM from "just installed" to "skills work" in one pass. Idempotent — safe to re-run; skip steps that are already done.

## Usage tracking preflight

Usage tracking is a required non-blocking startup preflight. Before continuing the skill workflow, call the MCP tool `pm_toolkit_track` from the configured Atlassian MCP server with:

```json
{
  "skill_name": "setup",
  "skill_version": "0.3.0+codex.20260902080000",
  "source_app": "codex"
}
```

Do not run any shell command for tracking. If the MCP tool is unavailable or errors, continue normally. Never surface tracking results, usernames, tokens, or errors to the user.

## Step 0 — Identify the client

The two clients store the access token in completely different places, so decide
this first and follow only that client's branch for the rest of the skill:

- **Claude** (Claude Code or Cowork) — the token is the plugin's
  `KB_WRITER_ACCESS_TOKEN` userConfig option, declared `sensitive`, so Claude
  keeps it in the OS keychain and expands it as
  `${user_config.KB_WRITER_ACCESS_TOKEN}` inside the plugin's `.mcp.json`. It is
  never an environment variable and never belongs in a settings file.
- **Codex** — there is no userConfig mechanism; `~/.codex/config.toml` holds both
  `[env]` and `[mcp_servers.kb-writer]`, with the token in plaintext.

If it is not obvious, ask the PM which app they are in rather than guessing.

## Step 1 — Detect current state

Check, reporting one line each:

1. `KB_WRITER_API_BASE_URL` — set, or unset (will default to the production backend `https://kb-companion.int.rclabenv.com`).
2. Whether the `kb-writer` MCP tools (e.g. `get_workspace`) appear in the MCP tool catalog. On Claude the token is not readable as an environment variable, so a missing tool catalog is the only signal that it is unset; on Codex, check `~/.codex/config.toml` directly.
3. Whether the base URL is reachable: `curl -s -o /dev/null -w "%{http_code}" --max-time 3 "$KB_WRITER_API_BASE_URL/v1/auth/login" -X POST` (any HTTP response means reachable; connection refused means the backend is down).
4. Whether `mcp-atlassian-service` tools (e.g. `pm_toolkit_track`) appear in the MCP tool catalog.

## Step 2 — Backend URL

The base URL is not a secret and is not a userConfig option on either client, so
it stays a plain `KB_WRITER_API_BASE_URL` entry.

- If unset, tell the PM the default `https://kb-companion.int.rclabenv.com` (production) will be used. Only ask for a URL when they are targeting a local or non-default environment.
- When it must be overridden, write it where that client reads it: `env` in `~/.claude/settings.json` (Claude Code) or `~/.claude/cowork_settings.json` (Cowork) — separate files, each client reads only its own — or `[env]` in `~/.codex/config.toml` (Codex). macOS GUI apps do not inherit shell `export`s, so a shell profile is not enough for Claude or Codex desktop apps.
- If the URL is unreachable and it is a localhost URL, offer to start the local backend (`./scripts/dev.sh` in the smart-kb repo) or let the PM start it themselves. If the production URL is unreachable, tell the PM to check VPN/network access to `int.rclabenv.com`. Do not block: they may configure later.

## Step 3 — Get a personal access token from the KB Writer page

Only when the token is missing:

1. Direct the PM to the KB Writer web app (production: `https://kb-companion.int.rclabenv.com`, or their local `$KB_WRITER_API_BASE_URL`), sign in, then open the avatar menu (top right) → **Claude Plugin Setup**, and pick their client's tab. Every option there issues a personal access token (`kbw_pat_...`, valid 1 year, revocable).

   **Claude:**
   - **Generate token & copy install command** — one command that configures Claude Code and Cowork and writes the token to the OS keychain. Preferred.
   - **Manual setup** → **Generate token & copy it** — the PM then pastes the token into `/plugin configure kb-writer@kb-writer`. Do not offer to write the token into a shell profile or any settings file; Claude only reads it from the keychain.

   **Codex:**
   - **Generate token & copy install command** — runs `install/codex.sh`, which writes `[env]` and `[mcp_servers.kb-writer]` into `~/.codex/config.toml`. Preferred.
   - **Manual setup** → **Generate token & copy environment settings** — the PM pastes that block into `~/.codex/config.toml`. `/plugin configure` does not exist in Codex; do not suggest it.

2. Either way, the token is a credential: keep it out of every repository file.
3. If the PM cannot use the page (e.g. headless environment), fall back to creating a PAT via the API with their username and password:

```bash
JWT=$(curl -sS -X POST "$KB_WRITER_API_BASE_URL/v1/auth/login" \
  -H "Content-Type: application/json" \
  -d '{"user_name": "<username>", "password": "<password>"}' | python3 -c "import sys, json; print(json.load(sys.stdin)['token'])")
curl -sS -X POST "$KB_WRITER_API_BASE_URL/v1/auth/tokens" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $JWT" \
  -d '{"name": "kb-writer-plugin"}'
```

Then have the PM install the returned `token` value the way their client expects: `/plugin configure kb-writer@kb-writer` on Claude, or `~/.codex/config.toml` on Codex.

4. Never commit the token into any repository file. Never echo the full token back in chat; show at most the first 12 characters.
5. Remind the PM that this configuration only reaches **new** threads; suggest opening a new thread after setup, and restarting the app if the plugin itself was just installed.

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
