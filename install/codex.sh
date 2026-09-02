#!/usr/bin/env bash
# One-shot installer for the KB Writer plugin in Codex.
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/Kaifeng-Dennis/kb-writer-plugin/main/install/codex.sh | bash
#   curl -fsSL ... | KB_WRITER_ACCESS_TOKEN=kbw_pat_xxx bash
#
# What it does:
#   1. Installs the plugin into ~/.codex/plugins/cache/<marketplace>/kb-writer/<version>
#   2. Optionally writes KB_WRITER_API_BASE_URL / KB_WRITER_ACCESS_TOKEN into
#      ~/.codex/config.toml [env] (when KB_WRITER_ACCESS_TOKEN is provided)
# After it finishes, open a new Codex thread.
set -euo pipefail

MARKETPLACE_NAME="kb-writer"
PLUGIN_NAME="kb-writer"
REPO_GIT="https://github.com/Kaifeng-Dennis/kb-writer-plugin.git"
API_BASE_URL="${KB_WRITER_API_BASE_URL:-https://kb-companion.int.rclabenv.com}"
ACCESS_TOKEN="${KB_WRITER_ACCESS_TOKEN:-}"

CODEX_DIR="${HOME}/.codex"
CONFIG_FILE="${CODEX_DIR}/config.toml"
INSTALL_ROOT="${CODEX_DIR}/plugins/cache/${MARKETPLACE_NAME}/${PLUGIN_NAME}"

info() { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m!!\033[0m %s\n' "$*"; }

command -v git >/dev/null 2>&1 || { echo "git is required"; exit 1; }
command -v python3 >/dev/null 2>&1 || { echo "python3 is required"; exit 1; }

info "Fetching kb-writer plugin from GitHub"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "${TMP_DIR}"' EXIT
git clone --depth 1 "${REPO_GIT}" "${TMP_DIR}/repo" -q
PLUGIN_VERSION="$(python3 -c "import json; print(json.load(open('${TMP_DIR}/repo/.codex-plugin/plugin.json'))['version'])")"
INSTALL_DIR="${INSTALL_ROOT}/${PLUGIN_VERSION}"
rm -rf "${INSTALL_DIR}"
mkdir -p "${INSTALL_ROOT}"
mv "${TMP_DIR}/repo" "${INSTALL_DIR}"
rm -rf "${INSTALL_DIR}/.git"
info "Plugin ${PLUGIN_NAME} v${PLUGIN_VERSION} installed to ${INSTALL_DIR}"

if [ -n "${ACCESS_TOKEN}" ]; then
  info "Writing env into ${CONFIG_FILE}"
  mkdir -p "${CODEX_DIR}"
  [ -f "${CONFIG_FILE}" ] || touch "${CONFIG_FILE}"
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
    # Drop stale keys inside the existing [env] section, then append fresh ones.
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

info "Done. Open a new Codex thread to use the kb-writer skills."
