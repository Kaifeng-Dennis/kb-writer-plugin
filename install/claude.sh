#!/usr/bin/env bash
# One-shot installer and updater for the KB Writer Claude Code plugin.
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/Kaifeng-Dennis/kb-writer-plugin/main/install/claude.sh | bash
#   curl -fsSL ... | KB_WRITER_ACCESS_TOKEN=kbw_pat_xxx bash
set -euo pipefail

MARKETPLACE_NAME="kb-writer"
PLUGIN_NAME="kb-writer"
PLUGIN_ID="${PLUGIN_NAME}@${MARKETPLACE_NAME}"
REPO_GITHUB="Kaifeng-Dennis/kb-writer-plugin"
API_BASE_URL="${KB_WRITER_API_BASE_URL:-https://kb-companion.int.rclabenv.com}"
ACCESS_TOKEN="${KB_WRITER_ACCESS_TOKEN:-}"
SKIP_PLUGIN_INSTALL="${KB_WRITER_INSTALL_SKIP_PLUGIN:-}"
SETTINGS_FILE="${HOME}/.claude/settings.json"

info() { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m!!\033[0m %s\n' "$*"; }

if [ -z "$SKIP_PLUGIN_INSTALL" ]; then
  command -v claude >/dev/null 2>&1 || { echo "Claude Code CLI is required"; exit 1; }
fi
command -v python3 >/dev/null 2>&1 || { echo "python3 is required"; exit 1; }

marketplace_exists() {
  claude plugin marketplace list --json | python3 -c '
import json, sys
marketplace = sys.argv[1]
sys.exit(0 if any(item.get("name") == marketplace for item in json.load(sys.stdin)) else 1)
' "$MARKETPLACE_NAME"
}

plugin_exists() {
  claude plugin list --json | python3 -c '
import json, sys
plugin_id = sys.argv[1]
sys.exit(0 if any(item.get("id") == plugin_id and item.get("scope") == "user" for item in json.load(sys.stdin)) else 1)
' "$PLUGIN_ID"
}

if [ -n "$SKIP_PLUGIN_INSTALL" ]; then
  info "Skipping plugin installation for configuration verification"
elif marketplace_exists >/dev/null; then
  info "Refreshing KB Writer marketplace"
  claude plugin marketplace update "$MARKETPLACE_NAME"
else
  info "Adding KB Writer marketplace"
  claude plugin marketplace add "$REPO_GITHUB"
fi

if [ -n "$SKIP_PLUGIN_INSTALL" ]; then
  :
elif plugin_exists; then
  info "Updating ${PLUGIN_ID}"
  claude plugin update "$PLUGIN_ID" --scope user
else
  info "Installing ${PLUGIN_ID}"
  claude plugin install "$PLUGIN_ID" --scope user
fi

mkdir -p "$(dirname "$SETTINGS_FILE")"
[ -f "$SETTINGS_FILE" ] || echo '{}' > "$SETTINGS_FILE"

info "Enabling KB Writer marketplace auto-update"
export SETTINGS_FILE MARKETPLACE_NAME PLUGIN_ID REPO_GITHUB API_BASE_URL ACCESS_TOKEN
python3 << 'PYEOF'
import json, os

settings_path = os.environ['SETTINGS_FILE']
settings = json.load(open(settings_path))
marketplace = os.environ['MARKETPLACE_NAME']
settings.setdefault('extraKnownMarketplaces', {})[marketplace] = {
    'source': {'source': 'github', 'repo': os.environ['REPO_GITHUB']},
    'autoUpdate': True,
}
settings.setdefault('enabledPlugins', {})[os.environ['PLUGIN_ID']] = True
legacy_mcp_servers = settings.get('mcpServers')
if legacy_mcp_servers:
    legacy_mcp_servers.pop('kb-writer', None)
if os.environ.get('ACCESS_TOKEN'):
    env = settings.setdefault('env', {})
    env['KB_WRITER_API_BASE_URL'] = os.environ['API_BASE_URL']
    env['KB_WRITER_ACCESS_TOKEN'] = os.environ['ACCESS_TOKEN']
json.dump(settings, open(settings_path, 'w'), indent=2)
PYEOF

if [ -n "$ACCESS_TOKEN" ]; then
  claude mcp remove kb-writer --scope user 2>/dev/null || true
  claude mcp add kb-writer "${API_BASE_URL%/}/mcp" \
    --scope user \
    --transport http \
    --header "Authorization: Bearer ${ACCESS_TOKEN}"
  info "Wrote KB Writer environment settings and registered its remote MCP"
else
  warn "No KB_WRITER_ACCESS_TOKEN provided."
  warn "Get one from KB Writer (avatar menu → Claude Plugin Setup → Generate token), then either:"
  warn "  1) re-run: KB_WRITER_ACCESS_TOKEN=kbw_pat_xxx bash <this script>, or"
  warn "  2) export it in your shell profile (~/.zshrc)"
fi

info "Done. Restart Claude, then open a new thread to load KB Writer."
