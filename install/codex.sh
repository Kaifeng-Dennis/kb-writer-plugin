#!/usr/bin/env bash
# One-shot installer and refresher for the KB Writer Codex plugin.
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/Kaifeng-Dennis/kb-writer-plugin/main/install/codex.sh | bash
#   curl -fsSL ... | KB_WRITER_ACCESS_TOKEN=kbw_pat_xxx bash
set -euo pipefail

MARKETPLACE_NAME="kb-writer"
PLUGIN_NAME="kb-writer"
PLUGIN_ID="${PLUGIN_NAME}@${MARKETPLACE_NAME}"
MARKETPLACE_SOURCE="https://github.com/Kaifeng-Dennis/kb-writer-plugin.git"
API_BASE_URL="${KB_WRITER_API_BASE_URL:-https://kb-companion.int.rclabenv.com}"
ACCESS_TOKEN="${KB_WRITER_ACCESS_TOKEN:-}"

CODEX_DIR="${HOME}/.codex"
CONFIG_FILE="${CODEX_DIR}/config.toml"

info() { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m!!\033[0m %s\n' "$*"; }

command -v codex >/dev/null 2>&1 || { echo "Codex CLI is required"; exit 1; }
command -v python3 >/dev/null 2>&1 || { echo "python3 is required"; exit 1; }

marketplace_exists() {
  codex plugin marketplace list --json | python3 -c '
import json, sys
marketplace = sys.argv[1]
catalog = json.load(sys.stdin)
sys.exit(0 if any(item.get("name") == marketplace for item in catalog.get("marketplaces", [])) else 1)
' "$MARKETPLACE_NAME"
}

if marketplace_exists >/dev/null; then
  info "Refreshing KB Writer marketplace"
  codex plugin marketplace upgrade "$MARKETPLACE_NAME"
else
  info "Adding KB Writer marketplace"
  codex plugin marketplace add "$MARKETPLACE_SOURCE" --ref main
fi

info "Installing ${PLUGIN_ID} from the refreshed marketplace"
codex plugin add "$PLUGIN_ID"

if [ -n "$ACCESS_TOKEN" ]; then
  info "Writing env into ${CONFIG_FILE}"
  mkdir -p "$CODEX_DIR"
  [ -f "$CONFIG_FILE" ] || touch "$CONFIG_FILE"
  export CONFIG_FILE API_BASE_URL ACCESS_TOKEN
  python3 << 'PYEOF'
import os, re

path = os.environ['CONFIG_FILE']
src = open(path).read()

lines = [
    f'KB_WRITER_API_BASE_URL = "{os.environ["API_BASE_URL"]}"',
    f'KB_WRITER_ACCESS_TOKEN = "{os.environ["ACCESS_TOKEN"]}"',
]

if re.search(r'^\[env\]\s*$', src, flags=re.M):
    pattern = re.compile(r'(\[env\]\s*\n)(.*?)(?=^\[|\Z)', flags=re.M | re.S)
    def replace(match):
        body = '\n'.join(
            line for line in match.group(2).splitlines()
            if line.strip() and not line.strip().startswith('KB_WRITER_')
        )
        return match.group(1) + (body + '\n' if body else '') + '\n'.join(lines) + '\n\n'
    src = pattern.sub(replace, src, count=1)
else:
    if not src.endswith('\n'):
        src += '\n'
    src += '\n[env]\n' + '\n'.join(lines) + '\n'

open(path, 'w').write(src)
PYEOF
else
  warn "No KB_WRITER_ACCESS_TOKEN provided."
  warn "Get one from KB Writer (avatar menu → Claude Plugin Setup → Generate token), then either:"
  warn "  1) re-run: KB_WRITER_ACCESS_TOKEN=kbw_pat_xxx bash <this script>, or"
  warn "  2) add it to ${CONFIG_FILE} under [env]"
fi

info "Done. Open a new Codex thread to use the KB Writer skills."
info "Workspace-wide daily updates require an admin to import this repository's Codex marketplace."
