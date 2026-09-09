#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../../.." && pwd)"
TEMP_HOME="$(mktemp -d)"
NO_TOKEN_HOME="$(mktemp -d)"
trap 'rm -rf "$TEMP_HOME" "$NO_TOKEN_HOME"' EXIT

CLAUDE_INSTALLERS=(
  "$ROOT_DIR/integrations/plugins/kb-writer/install/claude.sh"
  "$ROOT_DIR/integrations/install/claude.sh"
)
CODEX_INSTALLERS=(
  "$ROOT_DIR/integrations/plugins/kb-writer/install/codex.sh"
  "$ROOT_DIR/integrations/install/codex.sh"
)

assert_codex_configured() {
  python3 - "$1/.codex/config.toml" <<'PYEOF'
import sys
codex = open(sys.argv[1]).read()
assert '[mcp_servers.kb-writer]' in codex
assert 'url = "https://example.test/base/mcp"' in codex
assert 'Authorization = "Bearer kbw_pat_test"' in codex
assert 'unrelated-server' in codex
PYEOF
}

# Both Claude clients must end up configured: Claude Code from settings.json and
# Cowork from cowork_settings.json. Neither may hold the token in plaintext, and
# unrelated entries already in the file must survive the rewrite.
assert_claude_configured() {
  python3 - "$1/.claude/settings.json" "$1/.claude/cowork_settings.json" <<'PYEOF'
import json, sys
for path in sys.argv[1:3]:
    settings = json.load(open(path))
    assert settings['env']['KB_WRITER_API_BASE_URL'] == 'https://example.test/base', path
    assert 'KB_WRITER_ACCESS_TOKEN' not in settings['env'], path
    assert settings['enabledPlugins']['kb-writer@kb-writer'] is True, path
    assert settings['extraKnownMarketplaces']['kb-writer']['autoUpdate'] is True, path

preexisting = json.load(open(sys.argv[1]))['mcpServers']['unrelated-server']
assert preexisting['url'] == 'https://other.example/mcp'
PYEOF
}

# The token reaches the keychain only through `claude plugin install --config`,
# once per client, and no installer may go back to registering its own copy of
# the remote MCP with `claude mcp add`.
assert_token_handoff() {
  python3 - "$1" <<'PYEOF'
import sys
commands = [part.decode() for part in open(sys.argv[1], 'rb').read().split(b'\0')[:-1]]
config_arg = 'KB_WRITER_ACCESS_TOKEN=kbw_pat_test'

calls = []
for index, token in enumerate(commands):
    if token == 'install':
        calls.append(commands[index:index + 8])

expected = [
    ['install', 'kb-writer@kb-writer', '--scope', 'user', '--yes',
     '--config', config_arg],
    ['install', 'kb-writer@kb-writer', '--scope', 'user', '--yes', '--cowork',
     '--config', config_arg],
]
assert [call[:len(want)] for call, want in zip(calls, expected)] == expected, calls
assert 'mcp' not in commands, commands
PYEOF
}

# Unrelated pre-existing configuration the installers must not disturb. They are
# fresh-install paths, so nothing here stands in for an older KB Writer install.
seed_home() {
  local home="$1"
  mkdir -p "$home/.codex" "$home/.claude"
  cat > "$home/.codex/config.toml" <<'EOF'
[mcp_servers.unrelated-server]
url = "https://other.example/mcp"
EOF
  cat > "$home/.claude/settings.json" <<'EOF'
{"mcpServers":{"unrelated-server":{"url":"https://other.example/mcp"}}}
EOF
}

mkdir -p "$TEMP_HOME/bin"
cat > "$TEMP_HOME/bin/claude" <<'EOF'
#!/usr/bin/env bash
printf '%s\0' "$@" >> "$CLAUDE_COMMAND_LOG"
EOF
chmod +x "$TEMP_HOME/bin/claude"
seed_home "$TEMP_HOME"

for installer in "${CODEX_INSTALLERS[@]}"; do
  HOME="$TEMP_HOME" KB_WRITER_INSTALL_SKIP_PLUGIN=1 \
    PATH="$TEMP_HOME/bin:$PATH" \
    KB_WRITER_API_BASE_URL='https://example.test/base/' \
    KB_WRITER_ACCESS_TOKEN='kbw_pat_test' bash "$installer" >/dev/null
done
assert_codex_configured "$TEMP_HOME"

# Re-seed before each installer so the second one is not just inheriting the
# state the first one left behind.
for installer in "${CLAUDE_INSTALLERS[@]}"; do
  seed_home "$TEMP_HOME"
  : > "$TEMP_HOME/claude-commands"
  installer_output=$(PATH="$TEMP_HOME/bin:$PATH" \
    CLAUDE_COMMAND_LOG="$TEMP_HOME/claude-commands" HOME="$TEMP_HOME" \
    KB_WRITER_INSTALL_SKIP_PLUGIN=1 \
    KB_WRITER_API_BASE_URL='https://example.test/base/' \
    KB_WRITER_ACCESS_TOKEN='kbw_pat_test' bash "$installer")
  [[ "$installer_output" != *'kbw_pat_test'* ]] || { echo "installer leaked token: $installer"; exit 1; }
  assert_claude_configured "$TEMP_HOME"
  assert_token_handoff "$TEMP_HOME/claude-commands"
done

# The desktop installer must also work with no claude CLI on PATH: everything
# except the keychain write still has to happen, and it has to say why the token
# was not stored.
seed_home "$NO_TOKEN_HOME"
no_cli_output=$(env -i PATH=/usr/bin:/bin HOME="$NO_TOKEN_HOME" \
  KB_WRITER_INSTALL_SKIP_PLUGIN=1 \
  KB_WRITER_API_BASE_URL='https://example.test/base/' \
  KB_WRITER_ACCESS_TOKEN='kbw_pat_test' \
  bash "$ROOT_DIR/integrations/install/claude.sh")
[[ "$no_cli_output" != *'kbw_pat_test'* ]] || { echo 'no-CLI installer leaked token'; exit 1; }
[[ "$no_cli_output" == *'claude CLI is not on PATH'* ]] || { echo 'no-CLI installer did not explain the missing keychain write'; exit 1; }
assert_claude_configured "$NO_TOKEN_HOME"

for installer in "${CLAUDE_INSTALLERS[@]}"; do
  seed_home "$NO_TOKEN_HOME"
  # `env -u` matters: a developer running this with KB_WRITER_ACCESS_TOKEN
  # exported in their shell would otherwise exercise the token path here and
  # hand their real token to the real CLI. The stub stays on PATH for the same
  # reason.
  : > "$NO_TOKEN_HOME/claude-commands"
  env -u KB_WRITER_ACCESS_TOKEN -u KB_WRITER_API_BASE_URL \
    PATH="$TEMP_HOME/bin:$PATH" \
    CLAUDE_COMMAND_LOG="$NO_TOKEN_HOME/claude-commands" \
    HOME="$NO_TOKEN_HOME" KB_WRITER_INSTALL_SKIP_PLUGIN=1 bash "$installer" >/dev/null
  [ ! -s "$NO_TOKEN_HOME/claude-commands" ] || { echo "installer called claude without a token: $installer"; exit 1; }
  python3 - "$NO_TOKEN_HOME/.codex/config.toml" \
    "$NO_TOKEN_HOME/.claude/settings.json" \
    "$NO_TOKEN_HOME/.claude/cowork_settings.json" <<'PYEOF'
import json, sys
assert '[mcp_servers.kb-writer]' not in open(sys.argv[1]).read()
for path in sys.argv[2:4]:
    settings = json.load(open(path))
    assert 'kb-writer' not in settings.get('mcpServers', {}), path
    # Without a token the plugin is still registered and pointed at production;
    # only the keychain write is deferred to /plugin configure.
    assert settings['env'] == {
        'KB_WRITER_API_BASE_URL': 'https://kb-companion.int.rclabenv.com'
    }, path
    assert settings['enabledPlugins']['kb-writer@kb-writer'] is True, path
PYEOF
done

# `claude plugin install --config` prints "Installed, but --config not applied"
# and exits 0 when the installed manifest has no such userConfig option -- which
# is what a marketplace serving an older plugin version looks like. Swallowing
# that made the installer claim a keychain write that never happened and leave
# the client with zero kb-writer tools, so it must now fail loudly instead.
REFUSED_HOME="$(mktemp -d)"
trap 'rm -rf "$TEMP_HOME" "$NO_TOKEN_HOME" "$REFUSED_HOME"' EXIT
seed_home "$REFUSED_HOME"
mkdir -p "$REFUSED_HOME/bin"
cat > "$REFUSED_HOME/bin/claude" <<'EOF'
#!/usr/bin/env bash
echo '⚠ Installed, but --config not applied: --config was given but plugin "kb-writer@kb-writer" declares no userConfig options.'
exit 0
EOF
chmod +x "$REFUSED_HOME/bin/claude"

for installer in "${CLAUDE_INSTALLERS[@]}"; do
  refused_status=0
  refused_output=$(PATH="$REFUSED_HOME/bin:$PATH" HOME="$REFUSED_HOME" \
    KB_WRITER_INSTALL_SKIP_PLUGIN=1 \
    KB_WRITER_API_BASE_URL='https://example.test/base/' \
    KB_WRITER_ACCESS_TOKEN='kbw_pat_test' bash "$installer" 2>&1) || refused_status=$?
  [ "$refused_status" -ne 0 ] || { echo "installer reported success despite a refused --config: $installer"; exit 1; }
  [[ "$refused_output" != *'Stored the access token'* ]] || { echo "installer falsely claimed a keychain write: $installer"; exit 1; }
  [[ "$refused_output" == *'Could not store the access token'* ]] || { echo "installer did not report the failed --config: $installer"; exit 1; }
  [[ "$refused_output" == *'declares no userConfig options'* ]] || { echo "installer dropped the CLI's reason: $installer"; exit 1; }
  [[ "$refused_output" != *'kbw_pat_test'* ]] || { echo "installer leaked token on failure: $installer"; exit 1; }
done

echo 'remote MCP installer configuration verified'
