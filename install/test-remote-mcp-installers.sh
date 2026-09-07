#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../../.." && pwd)"
TEMP_HOME="$(mktemp -d)"
trap 'rm -rf "$TEMP_HOME"' EXIT

assert_configured() {
  local codex_config="$1/.codex/config.toml"
  local claude_config="$1/.claude/settings.json"
  python3 - "$codex_config" "$claude_config" <<'PYEOF'
import json, sys
codex, claude = (open(path).read() for path in sys.argv[1:])
assert '[mcp_servers.kb-writer]' in codex
assert 'url = "https://example.test/base/mcp"' in codex
assert 'Authorization = "Bearer kbw_pat_test"' in codex
assert 'unrelated-server' in codex
settings = json.loads(claude)
remote = settings['mcpServers']['kb-writer']
assert remote['url'] == 'https://example.test/base/mcp'
assert remote['headers']['Authorization'] == 'Bearer kbw_pat_test'
assert settings['mcpServers']['unrelated-server']['url'] == 'https://other.example/mcp'
PYEOF
}

mkdir -p "$TEMP_HOME/.codex" "$TEMP_HOME/.claude"
cat > "$TEMP_HOME/.codex/config.toml" <<'EOF'
[mcp_servers.unrelated-server]
url = "https://other.example/mcp"
EOF
cat > "$TEMP_HOME/.claude/settings.json" <<'EOF'
{"mcpServers":{"unrelated-server":{"url":"https://other.example/mcp"}}}
EOF

for installer in \
  "$ROOT_DIR/integrations/plugins/kb-writer/install/codex.sh" \
  "$ROOT_DIR/integrations/plugins/kb-writer/install/claude.sh" \
  "$ROOT_DIR/integrations/install/codex.sh" \
  "$ROOT_DIR/integrations/install/claude.sh"; do
  installer_output=$(HOME="$TEMP_HOME" KB_WRITER_INSTALL_SKIP_PLUGIN=1 \
    KB_WRITER_API_BASE_URL='https://example.test/base/' \
    KB_WRITER_ACCESS_TOKEN='kbw_pat_test' bash "$installer")
  [[ "$installer_output" != *'kbw_pat_test'* ]] || { echo "installer leaked token: $installer"; exit 1; }
done

assert_configured "$TEMP_HOME"

NO_TOKEN_HOME="$(mktemp -d)"
trap 'rm -rf "$TEMP_HOME" "$NO_TOKEN_HOME"' EXIT
mkdir -p "$NO_TOKEN_HOME/.codex" "$NO_TOKEN_HOME/.claude"
printf '[mcp_servers.unrelated-server]\nurl = "https://other.example/mcp"\n' > "$NO_TOKEN_HOME/.codex/config.toml"
printf '{"mcpServers":{"unrelated-server":{"url":"https://other.example/mcp"}}}' > "$NO_TOKEN_HOME/.claude/settings.json"
for installer in \
  "$ROOT_DIR/integrations/plugins/kb-writer/install/codex.sh" \
  "$ROOT_DIR/integrations/plugins/kb-writer/install/claude.sh" \
  "$ROOT_DIR/integrations/install/codex.sh" \
  "$ROOT_DIR/integrations/install/claude.sh"; do
  HOME="$NO_TOKEN_HOME" KB_WRITER_INSTALL_SKIP_PLUGIN=1 bash "$installer" >/dev/null
done
python3 - "$NO_TOKEN_HOME/.codex/config.toml" "$NO_TOKEN_HOME/.claude/settings.json" <<'PYEOF'
import json, sys
assert '[mcp_servers.kb-writer]' not in open(sys.argv[1]).read()
assert 'kb-writer' not in json.load(open(sys.argv[2])).get('mcpServers', {})
PYEOF

echo 'remote MCP installer configuration verified'
