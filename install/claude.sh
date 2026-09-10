#!/usr/bin/env bash
# One-shot installer and updater for the KB Writer plugin in Claude Code.
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/Kaifeng-Dennis/kb-writer-plugin/main/install/claude.sh | bash
#   curl -fsSL ... | KB_WRITER_ACCESS_TOKEN=kbw_pat_xxx bash
#
# Claude Cowork is deliberately out of scope. Cowork's desktop app resolves its
# plugins from the account-level (server-side) marketplace, not from anything
# under ~/.claude, so nothing this script writes reaches it -- and the one-time
# local-to-remote marketplace migration is already sentinel-stamped, so a
# locally added marketplace is never synced up either. Cowork users have to add
# the marketplace through Customize -> Plugins -> + -> Add marketplace and paste
# the token into Cowork's own configuration prompt. Note that Cowork also has no
# way to set KB_WRITER_API_BASE_URL, so it can only ever reach production.
#
# The plugin's own .mcp.json authenticates with ${user_config.KB_WRITER_ACCESS_TOKEN},
# which Claude Code resolves from pluginConfigs["kb-writer@kb-writer"].options in
# ~/.claude/settings.json. This script writes that entry itself, the same way it
# writes enabledPlugins, and then reads the file back to confirm it landed.
#
# It does not go through `claude plugin install --config`. That command exits 0
# and prints an unqualified success line whether or not it stored anything, and
# on CLI 2.1.263 it stores nothing at all -- no pluginConfigs entry, no keychain
# item -- so earlier versions of this script announced a keychain write that had
# never happened and left the client with a plugin whose token placeholder could
# not expand, hence zero kb-writer tools.
#
# The trade-off is that the token sits in settings.json in cleartext rather than
# the OS keychain. `/plugin configure kb-writer@kb-writer` inside Claude still
# stores it the keychain way; the settings entry can be deleted afterwards.
#
# This is a fresh-install path only. It does not migrate configuration written by
# earlier installers; anyone upgrading from one of those has to clear the old
# plaintext token and MCP registration themselves.
set -euo pipefail

MARKETPLACE_NAME="kb-writer"
PLUGIN_NAME="kb-writer"
PLUGIN_ID="${PLUGIN_NAME}@${MARKETPLACE_NAME}"
REPO_GITHUB="Kaifeng-Dennis/kb-writer-plugin"
DEFAULT_API_BASE_URL="https://kb-companion.int.rclabenv.com"
API_BASE_URL="${KB_WRITER_API_BASE_URL:-$DEFAULT_API_BASE_URL}"
ACCESS_TOKEN="${KB_WRITER_ACCESS_TOKEN:-}"
SKIP_PLUGIN_INSTALL="${KB_WRITER_INSTALL_SKIP_PLUGIN:-}"
SETTINGS_FILE="${HOME}/.claude/settings.json"

info() { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m!!\033[0m %s\n' "$*"; }

if [ -z "$SKIP_PLUGIN_INSTALL" ]; then
  command -v claude >/dev/null 2>&1 || { echo "Claude Code CLI is required"; exit 1; }
fi
command -v python3 >/dev/null 2>&1 || { echo "python3 is required"; exit 1; }

require_noninteractive_plugin_install() {
  if ! claude plugin install --help 2>&1 | grep -Eq '(^|[^[:alnum:]-])--yes([^[:alnum:]-]|$)'; then
    echo "Claude Code CLI support for 'claude plugin install --yes' is required."
    echo "Upgrade Claude Code to 2.1.260 or newer, then re-run this installer."
    exit 1
  fi
}

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

patch_settings() {
  mkdir -p "$(dirname "$SETTINGS_FILE")"
  [ -f "$SETTINGS_FILE" ] || echo '{}' > "$SETTINGS_FILE"
  SETTINGS_FILE="$SETTINGS_FILE" \
  MARKETPLACE_NAME="$MARKETPLACE_NAME" \
  PLUGIN_ID="$PLUGIN_ID" \
  REPO_GITHUB="$REPO_GITHUB" \
  API_BASE_URL="$API_BASE_URL" \
  ACCESS_TOKEN="$ACCESS_TOKEN" \
  python3 << 'PYEOF'
import json, os

settings_path = os.environ['SETTINGS_FILE']
settings = json.load(open(settings_path))

settings.setdefault('extraKnownMarketplaces', {})[os.environ['MARKETPLACE_NAME']] = {
    'source': {'source': 'github', 'repo': os.environ['REPO_GITHUB']},
    'autoUpdate': True,
}
settings.setdefault('enabledPlugins', {})[os.environ['PLUGIN_ID']] = True

# The base URL is not a secret and has a safe default baked into the plugin's
# .mcp.json, so it stays a plain env entry. Trailing slashes would turn the
# server URL into "...//mcp".
settings.setdefault('env', {})['KB_WRITER_API_BASE_URL'] = os.environ['API_BASE_URL'].rstrip('/')

# Overwriting rather than merging is what makes a re-run double as token
# rotation. The token deliberately does not go into `env`: that would export it
# to every process Claude Code spawns, while pluginConfigs keeps it scoped to
# this plugin and is the same key /plugin configure writes.
token = os.environ['ACCESS_TOKEN']
if token:
    settings.setdefault('pluginConfigs', {}) \
            .setdefault(os.environ['PLUGIN_ID'], {}) \
            .setdefault('options', {})['KB_WRITER_ACCESS_TOKEN'] = token

json.dump(settings, open(settings_path, 'w'), indent=2)
PYEOF
}

# Reads the file back in a separate process, so a write that silently did not
# land -- which leaves the plugin loaded but toolless -- cannot pass as success.
token_stored() {
  SETTINGS_FILE="$SETTINGS_FILE" PLUGIN_ID="$PLUGIN_ID" ACCESS_TOKEN="$ACCESS_TOKEN" \
  python3 << 'PYEOF'
import json, os, sys

settings = json.load(open(os.environ['SETTINGS_FILE']))
options = settings.get('pluginConfigs', {}).get(os.environ['PLUGIN_ID'], {}).get('options', {})
sys.exit(0 if options.get('KB_WRITER_ACCESS_TOKEN') == os.environ['ACCESS_TOKEN'] else 1)
PYEOF
}

info "Configuring Claude Code"

if [ -n "$SKIP_PLUGIN_INSTALL" ]; then
  info "Skipping marketplace and plugin installation for configuration verification"
else
  # Piped installers cannot prompt. Check before marketplace mutation so an
  # older CLI cannot leave a partial KB Writer installation behind.
  require_noninteractive_plugin_install

  if marketplace_exists >/dev/null; then
    info "Refreshing KB Writer marketplace"
    claude plugin marketplace update "$MARKETPLACE_NAME"
  else
    info "Adding KB Writer marketplace"
    claude plugin marketplace add "$REPO_GITHUB"
  fi

  if plugin_exists; then
    info "Updating ${PLUGIN_ID}"
    claude plugin update "$PLUGIN_ID" --scope user
  else
    info "Installing ${PLUGIN_ID}"
    claude plugin install "$PLUGIN_ID" --scope user --yes
  fi
fi

patch_settings

if [ -n "$ACCESS_TOKEN" ]; then
  if token_stored; then
    info "Stored the access token in ${SETTINGS_FILE}"
  else
    warn "Could not store the access token in ${SETTINGS_FILE}."
    warn "KB Writer will have no tools until it is: the plugin's .mcp.json cannot"
    warn "expand \${user_config.KB_WRITER_ACCESS_TOKEN} without it, so its MCP"
    warn "server never connects. Check that the file is writable and valid JSON,"
    warn "then re-run this script, or run \`/plugin configure ${PLUGIN_ID}\` instead."
    exit 1
  fi
else
  warn "No KB_WRITER_ACCESS_TOKEN provided."
  warn "Get one from KB Writer (avatar menu -> Claude Plugin Setup -> Generate token), then either:"
  warn "  1) re-run: KB_WRITER_ACCESS_TOKEN=kbw_pat_xxx bash <this script>, or"
  warn "  2) run \`/plugin configure ${PLUGIN_ID}\` in Claude and paste it there"
fi

info "Done. Restart Claude Code, then open a new thread to load KB Writer."
