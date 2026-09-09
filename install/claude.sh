#!/usr/bin/env bash
# One-shot installer and updater for the KB Writer plugin, for both Claude Code
# and Claude Cowork.
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/Kaifeng-Dennis/kb-writer-plugin/main/install/claude.sh | bash
#   curl -fsSL ... | KB_WRITER_ACCESS_TOKEN=kbw_pat_xxx bash
#
# The access token is handed to `claude plugin install --config`, which stores it
# in the OS keychain because the plugin manifest declares KB_WRITER_ACCESS_TOKEN
# as a sensitive userConfig option. It is never written to settings.json, and the
# plugin's own .mcp.json reads it back as ${user_config.KB_WRITER_ACCESS_TOKEN}.
#
# Cowork keeps a separate configuration root from Claude Code: user settings live
# in cowork_settings.json and plugins in cowork_plugins/, both reached by passing
# --cowork to `claude plugin`. Configuring only one of the two leaves the other
# client without KB Writer, so every step below runs once per client.
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
CLAUDE_DIR="${HOME}/.claude"

# "<label>|<user settings file>|<claude plugin flag>"
TARGETS=(
  "Claude Code|${CLAUDE_DIR}/settings.json|"
  "Claude Cowork|${CLAUDE_DIR}/cowork_settings.json|--cowork"
)

info() { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m!!\033[0m %s\n' "$*"; }

if [ -z "$SKIP_PLUGIN_INSTALL" ]; then
  command -v claude >/dev/null 2>&1 || { echo "Claude Code CLI is required"; exit 1; }
fi
command -v python3 >/dev/null 2>&1 || { echo "python3 is required"; exit 1; }

# $1 is either empty or --cowork; it never contains spaces, so leaving the
# expansion unquoted is how an absent flag collapses to no argument at all.
marketplace_exists() {
  claude plugin marketplace list ${1} --json | python3 -c '
import json, sys
marketplace = sys.argv[1]
sys.exit(0 if any(item.get("name") == marketplace for item in json.load(sys.stdin)) else 1)
' "$MARKETPLACE_NAME"
}

plugin_exists() {
  claude plugin list ${1} --json | python3 -c '
import json, sys
plugin_id = sys.argv[1]
sys.exit(0 if any(item.get("id") == plugin_id and item.get("scope") == "user" for item in json.load(sys.stdin)) else 1)
' "$PLUGIN_ID"
}

patch_settings() {
  local settings_file="$1"
  mkdir -p "$(dirname "$settings_file")"
  [ -f "$settings_file" ] || echo '{}' > "$settings_file"
  SETTINGS_FILE="$settings_file" \
  MARKETPLACE_NAME="$MARKETPLACE_NAME" \
  PLUGIN_ID="$PLUGIN_ID" \
  REPO_GITHUB="$REPO_GITHUB" \
  API_BASE_URL="$API_BASE_URL" \
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

json.dump(settings, open(settings_path, 'w'), indent=2)
PYEOF
}

# `claude plugin install --config` exits 0 even when it refuses the value: if the
# installed manifest predates the userConfig declaration it just prints
# "Installed, but --config not applied: ...". Discarding that output is how this
# script used to report a keychain write that never happened, leaving Cowork with
# a plugin whose ${user_config.KB_WRITER_ACCESS_TOKEN} never expands and thus no
# kb-writer tools at all. So inspect the output, and scrub the token out of
# anything quoted back.
STORE_FAILURE=''
store_token() {
  local flag="$1" output status=0 reason
  output="$(claude plugin install "$PLUGIN_ID" --scope user --yes ${flag} \
    --config "KB_WRITER_ACCESS_TOKEN=${ACCESS_TOKEN}" 2>&1)" || status=$?

  if [ "$status" -ne 0 ]; then
    STORE_FAILURE="claude plugin install exited ${status}"
    return 1
  fi

  case "$output" in
    *'--config not applied'*)
      reason="${output#*--config not applied: }"
      STORE_FAILURE="${reason%%$'\n'*}"
      STORE_FAILURE="${STORE_FAILURE//$ACCESS_TOKEN/<token>}"
      return 1
      ;;
  esac
  return 0
}

configured_clients=0
failed_clients=0

for target in "${TARGETS[@]}"; do
  IFS='|' read -r label settings_file flag <<< "$target"
  info "Configuring ${label}"

  if [ -n "$SKIP_PLUGIN_INSTALL" ]; then
    info "Skipping marketplace and plugin installation for configuration verification"
  elif marketplace_exists "$flag" >/dev/null; then
    info "Refreshing KB Writer marketplace"
    claude plugin marketplace update "$MARKETPLACE_NAME" ${flag}
  else
    info "Adding KB Writer marketplace"
    claude plugin marketplace add "$REPO_GITHUB" ${flag}
  fi

  if [ -n "$SKIP_PLUGIN_INSTALL" ]; then
    :
  elif plugin_exists "$flag"; then
    info "Updating ${PLUGIN_ID}"
    claude plugin update "$PLUGIN_ID" --scope user ${flag}
  else
    info "Installing ${PLUGIN_ID}"
    claude plugin install "$PLUGIN_ID" --scope user --yes ${flag}
  fi

  patch_settings "$settings_file"

  if [ -n "$ACCESS_TOKEN" ]; then
    # Re-running install against an already-installed plugin is how the CLI
    # applies --config without a prompt, so this doubles as token rotation.
    if store_token "$flag"; then
      info "Stored the access token in the OS keychain for ${label}"
      configured_clients=$((configured_clients + 1))
    else
      warn "Could not store the access token for ${label}: ${STORE_FAILURE}"
      failed_clients=$((failed_clients + 1))
    fi
  fi
done

if [ "$failed_clients" -gt 0 ]; then
  warn "KB Writer will have no tools in the client(s) above until the token is stored."
  warn "Most likely the installed plugin predates the KB_WRITER_ACCESS_TOKEN userConfig"
  warn "option, so the marketplace still serves an older manifest. Try:"
  warn "  1) claude plugin marketplace update ${MARKETPLACE_NAME}   (add --cowork for Cowork)"
  warn "  2) re-run this script, or run \`/plugin configure ${PLUGIN_ID}\` in Claude"
  exit 1
fi

if [ -z "$ACCESS_TOKEN" ]; then
  warn "No KB_WRITER_ACCESS_TOKEN provided."
  warn "Get one from KB Writer (avatar menu -> Claude Plugin Setup -> Generate token), then either:"
  warn "  1) re-run: KB_WRITER_ACCESS_TOKEN=kbw_pat_xxx bash <this script>, or"
  warn "  2) run \`/plugin configure ${PLUGIN_ID}\` in Claude and paste it there"
fi

info "Done. Restart Claude, then open a new thread to load KB Writer."
