#!/usr/bin/env bash
# One-shot installer for the KB Writer plugin in the Claude desktop app.
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/Kaifeng-Dennis/kb-writer-plugin/main/install/claude.sh | bash
#   curl -fsSL ... | KB_WRITER_ACCESS_TOKEN=kbw_pat_xxx bash
#
# What it does:
#   1. Registers the kb-writer marketplace (GitHub) in ~/.claude/settings.json
#   2. Installs the plugin into ~/.claude/plugins (marketplace clone + cache)
#   3. Enables kb-writer@kb-writer in ~/.claude/settings.json
#   4. Optionally writes KB_WRITER_API_BASE_URL / KB_WRITER_ACCESS_TOKEN into
#      ~/.claude/settings.json env (when KB_WRITER_ACCESS_TOKEN is provided)
# After it finishes, restart the Claude desktop app.
set -euo pipefail

MARKETPLACE_NAME="kb-writer"
PLUGIN_NAME="kb-writer"
REPO_URL="https://github.com/Kaifeng-Dennis/kb-writer-plugin"
REPO_GIT="${REPO_URL}.git"
API_BASE_URL="${KB_WRITER_API_BASE_URL:-https://kb-companion.int.rclabenv.com}"
ACCESS_TOKEN="${KB_WRITER_ACCESS_TOKEN:-}"

CLAUDE_DIR="${HOME}/.claude"
SETTINGS_FILE="${CLAUDE_DIR}/settings.json"
KNOWN_MARKETPLACES_FILE="${CLAUDE_DIR}/plugins/known_marketplaces.json"
INSTALLED_PLUGINS_FILE="${CLAUDE_DIR}/plugins/installed_plugins.json"
MARKETPLACE_DIR="${CLAUDE_DIR}/plugins/marketplaces/${MARKETPLACE_NAME}"

info() { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m!!\033[0m %s\n' "$*"; }

command -v git >/dev/null 2>&1 || { echo "git is required"; exit 1; }
command -v python3 >/dev/null 2>&1 || { echo "python3 is required"; exit 1; }

mkdir -p "${CLAUDE_DIR}/plugins/marketplaces" "${CLAUDE_DIR}/plugins/cache"
[ -f "${SETTINGS_FILE}" ] || echo '{}' > "${SETTINGS_FILE}"
[ -f "${KNOWN_MARKETPLACES_FILE}" ] || echo '{}' > "${KNOWN_MARKETPLACES_FILE}"
[ -f "${INSTALLED_PLUGINS_FILE}" ] || printf '{\n  "version": 2,\n  "plugins": {}\n}\n' > "${INSTALLED_PLUGINS_FILE}"

info "Fetching kb-writer marketplace from GitHub"
if [ -d "${MARKETPLACE_DIR}/.git" ]; then
  git -C "${MARKETPLACE_DIR}" fetch --depth 1 origin main -q
  git -C "${MARKETPLACE_DIR}" reset --hard FETCH_HEAD -q
else
  rm -rf "${MARKETPLACE_DIR}"
  git clone --depth 1 "${REPO_GIT}" "${MARKETPLACE_DIR}" -q
fi
COMMIT_SHA="$(git -C "${MARKETPLACE_DIR}" rev-parse HEAD)"
PLUGIN_VERSION="$(python3 -c "import json; print(json.load(open('${MARKETPLACE_DIR}/.claude-plugin/plugin.json'))['version'])")"
CACHE_DIR="${CLAUDE_DIR}/plugins/cache/${MARKETPLACE_NAME}/${PLUGIN_NAME}/${PLUGIN_VERSION}"
rm -rf "${CACHE_DIR}"
mkdir -p "$(dirname "${CACHE_DIR}")"
cp -R "${MARKETPLACE_DIR}" "${CACHE_DIR}"
rm -rf "${CACHE_DIR}/.git"
info "Plugin ${PLUGIN_NAME} v${PLUGIN_VERSION} staged (${COMMIT_SHA:0:8})"

info "Updating Claude settings"
export SETTINGS_FILE KNOWN_MARKETPLACES_FILE INSTALLED_PLUGINS_FILE
export MARKETPLACE_NAME PLUGIN_NAME REPO_GIT MARKETPLACE_DIR CACHE_DIR COMMIT_SHA PLUGIN_VERSION
export API_BASE_URL ACCESS_TOKEN
python3 << 'PYEOF'
import json, os
from datetime import datetime, timezone

now = datetime.now(timezone.utc).isoformat(timespec='milliseconds').replace('+00:00', 'Z')
marketplace = os.environ['MARKETPLACE_NAME']
plugin = os.environ['PLUGIN_NAME']
plugin_key = f"{plugin}@{marketplace}"

settings_path = os.environ['SETTINGS_FILE']
settings = json.load(open(settings_path))
settings.setdefault('extraKnownMarketplaces', {})[marketplace] = {
    'source': {'source': 'github', 'repo': 'Kaifeng-Dennis/kb-writer-plugin'}
}
settings.setdefault('enabledPlugins', {})[plugin_key] = True
if os.environ.get('ACCESS_TOKEN'):
    env = settings.setdefault('env', {})
    env['KB_WRITER_API_BASE_URL'] = os.environ['API_BASE_URL']
    env['KB_WRITER_ACCESS_TOKEN'] = os.environ['ACCESS_TOKEN']
json.dump(settings, open(settings_path, 'w'), indent=2)

known_path = os.environ['KNOWN_MARKETPLACES_FILE']
known = json.load(open(known_path))
known[marketplace] = {
    'source': {'source': 'github', 'repo': 'Kaifeng-Dennis/kb-writer-plugin'},
    'installLocation': os.environ['MARKETPLACE_DIR'],
    'lastUpdated': now,
}
json.dump(known, open(known_path, 'w'), indent=2)

installed_path = os.environ['INSTALLED_PLUGINS_FILE']
installed = json.load(open(installed_path))
installed.setdefault('version', 2)
plugins = installed.setdefault('plugins', {})
plugins[plugin_key] = [{
    'scope': 'user',
    'installPath': os.environ['CACHE_DIR'],
    'version': os.environ['PLUGIN_VERSION'],
    'installedAt': now,
    'lastUpdated': now,
    'gitCommitSha': os.environ['COMMIT_SHA'],
}]
json.dump(installed, open(installed_path, 'w'), indent=2)
PYEOF

if [ -n "${ACCESS_TOKEN}" ]; then
  info "Wrote KB_WRITER_API_BASE_URL and KB_WRITER_ACCESS_TOKEN into ~/.claude/settings.json env"
else
  warn "No KB_WRITER_ACCESS_TOKEN provided."
  warn "Get one from KB Writer (avatar menu → Claude Plugin Setup → Generate token), then either:"
  warn "  1) re-run: KB_WRITER_ACCESS_TOKEN=kbw_pat_xxx bash <this script>, or"
  warn "  2) export it in your shell profile (~/.zshrc)"
fi

info "Done. Restart the Claude desktop app to load the kb-writer plugin."
