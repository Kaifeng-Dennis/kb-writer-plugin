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

# Claude Code is the only Claude target. The token belongs in pluginConfigs,
# which is where Claude resolves ${user_config.KB_WRITER_ACCESS_TOKEN} from --
# not in `env`, which would export it to every process Claude spawns. Unrelated
# entries already in the file must survive the rewrite.
assert_claude_configured() {
  python3 - "$1/.claude/settings.json" <<'PYEOF'
import json, sys
settings = json.load(open(sys.argv[1]))
assert settings['env']['KB_WRITER_API_BASE_URL'] == 'https://example.test/base'
assert 'KB_WRITER_ACCESS_TOKEN' not in settings['env']
options = settings['pluginConfigs']['kb-writer@kb-writer']['options']
assert options['KB_WRITER_ACCESS_TOKEN'] == 'kbw_pat_test'
assert settings['enabledPlugins']['kb-writer@kb-writer'] is True
assert settings['extraKnownMarketplaces']['kb-writer']['autoUpdate'] is True
assert settings['mcpServers']['unrelated-server']['url'] == 'https://other.example/mcp'
PYEOF
}

# Cowork support was dropped: its desktop app resolves plugins from the
# account-level marketplace, so writing cowork_settings.json / cowork_plugins/
# configured nothing while still printing a success line. No installer may
# recreate those paths, and none may pass --cowork to the CLI.
assert_no_cowork() {
  local home="$1" command_log="$2"
  [ ! -e "$home/.claude/cowork_settings.json" ] || { echo 'installer wrote cowork_settings.json'; exit 1; }
  [ ! -e "$home/.claude/cowork_plugins" ] || { echo 'installer created cowork_plugins/'; exit 1; }
  ! grep -qa -- '--cowork' "$command_log" || { echo 'installer passed --cowork to the CLI'; exit 1; }
}

# A piped installer cannot prompt for confirmation, but older Claude Code CLIs
# reject --yes. The capability check must fail before marketplace, plugin, or
# settings mutations, so a user is never left with a half-installed plugin.
assert_unsupported_claude_stops_before_mutation() {
  local home="$1" command_log="$2"
  local output status=0
  seed_home "$home"
  cp "$home/.claude/settings.json" "$home/settings.before.json"
  : > "$command_log"
  output=$(PATH="$TEMP_HOME/unsupported-bin:$PATH" CLAUDE_COMMAND_LOG="$command_log" HOME="$home" \
    KB_WRITER_ACCESS_TOKEN='kbw_pat_test' bash "$ROOT_DIR/integrations/plugins/kb-writer/install/claude.sh" 2>&1) || status=$?
  [ "$status" -ne 0 ] || { echo 'unsupported Claude CLI installer unexpectedly succeeded'; exit 1; }
  [[ "$output" == *'--yes'* ]] || { echo 'unsupported Claude CLI error did not mention --yes'; exit 1; }
  cmp -s "$home/settings.before.json" "$home/.claude/settings.json" || { echo 'unsupported Claude CLI changed settings'; exit 1; }
  ! grep -qa -- 'marketplace' "$command_log" || { echo 'unsupported Claude CLI mutated marketplace'; exit 1; }
  ! grep -qa -- 'plugin install kb-writer@kb-writer' "$command_log" || { echo 'unsupported Claude CLI installed plugin'; exit 1; }
}

# The token is written to settings.json directly, so no installer may hand it to
# `claude plugin install --config`: that command exits 0 and prints a success
# line whether or not it stored anything, which is what used to leave clients
# with an unusable plugin. Nor may an installer go back to registering its own
# copy of the remote MCP with `claude mcp add`.
assert_token_handoff() {
  python3 - "$1" <<'PYEOF'
import sys
commands = [part.decode() for part in open(sys.argv[1], 'rb').read().split(b'\0')[:-1]]
assert '--config' not in commands, commands
assert not any('kbw_pat_test' in command for command in commands), 'token handed to the CLI'
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
mkdir -p "$TEMP_HOME/unsupported-bin"
cat > "$TEMP_HOME/unsupported-bin/claude" <<'EOF'
#!/usr/bin/env bash
printf '%s\0' "$@" >> "$CLAUDE_COMMAND_LOG"
if [ "$1 $2 $3" = 'plugin install --help' ]; then
  printf '%s\n' 'Usage: claude plugin install <plugin> [--scope <scope>]'
fi
EOF
chmod +x "$TEMP_HOME/unsupported-bin/claude"
seed_home "$TEMP_HOME"

UNSUPPORTED_HOME="$(mktemp -d)"
trap 'rm -rf "$TEMP_HOME" "$NO_TOKEN_HOME" "$UNSUPPORTED_HOME"' EXIT
assert_unsupported_claude_stops_before_mutation "$UNSUPPORTED_HOME" "$UNSUPPORTED_HOME/claude-commands"

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
  assert_no_cowork "$TEMP_HOME" "$TEMP_HOME/claude-commands"
done

# The desktop installer clones the marketplace itself, and now writes the token
# itself too, so it must configure Claude Code completely with no claude CLI on
# PATH at all.
seed_home "$NO_TOKEN_HOME"
no_cli_output=$(env -i PATH=/usr/bin:/bin HOME="$NO_TOKEN_HOME" \
  KB_WRITER_INSTALL_SKIP_PLUGIN=1 \
  KB_WRITER_API_BASE_URL='https://example.test/base/' \
  KB_WRITER_ACCESS_TOKEN='kbw_pat_test' \
  bash "$ROOT_DIR/integrations/install/claude.sh")
[[ "$no_cli_output" != *'kbw_pat_test'* ]] || { echo 'no-CLI installer leaked token'; exit 1; }
[[ "$no_cli_output" != *'Could not store the access token'* ]] || { echo 'no-CLI installer failed to store the token'; exit 1; }
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
    "$NO_TOKEN_HOME/.claude/settings.json" <<'PYEOF'
import json, sys
assert '[mcp_servers.kb-writer]' not in open(sys.argv[1]).read()
settings = json.load(open(sys.argv[2]))
assert 'kb-writer' not in settings.get('mcpServers', {})
# Without a token the plugin is still registered and pointed at production, and
# nothing half-written is left in pluginConfigs; supplying the token is deferred
# to a re-run or /plugin configure.
assert settings['env'] == {'KB_WRITER_API_BASE_URL': 'https://kb-companion.int.rclabenv.com'}
assert 'kb-writer@kb-writer' not in settings.get('pluginConfigs', {})
assert settings['enabledPlugins']['kb-writer@kb-writer'] is True
PYEOF
done

# A re-run with a new token has to rotate the stored one rather than leave the
# stale value in place.
ROTATE_HOME="$(mktemp -d)"
trap 'rm -rf "$TEMP_HOME" "$NO_TOKEN_HOME" "$ROTATE_HOME"' EXIT
for installer in "${CLAUDE_INSTALLERS[@]}"; do
  seed_home "$ROTATE_HOME"
  cat > "$ROTATE_HOME/.claude/settings.json" <<'EOF'
{"pluginConfigs":{"kb-writer@kb-writer":{"options":{"KB_WRITER_ACCESS_TOKEN":"kbw_pat_stale"}}}}
EOF
  PATH="$TEMP_HOME/bin:$PATH" CLAUDE_COMMAND_LOG="$ROTATE_HOME/claude-commands" \
    HOME="$ROTATE_HOME" KB_WRITER_INSTALL_SKIP_PLUGIN=1 \
    KB_WRITER_API_BASE_URL='https://example.test/base/' \
    KB_WRITER_ACCESS_TOKEN='kbw_pat_test' bash "$installer" >/dev/null
  python3 - "$ROTATE_HOME/.claude/settings.json" <<'PYEOF'
import json, sys
options = json.load(open(sys.argv[1]))['pluginConfigs']['kb-writer@kb-writer']['options']
assert options['KB_WRITER_ACCESS_TOKEN'] == 'kbw_pat_test'
PYEOF
done

# When the token cannot be written, the installer must fail loudly instead of
# printing a success line for a client that will come up with zero kb-writer
# tools -- the regression this whole verification path exists for. An unwritable
# settings file stands in for any reason the write does not land.
for installer in "${CLAUDE_INSTALLERS[@]}"; do
  seed_home "$ROTATE_HOME"
  rm -f "$ROTATE_HOME/.claude/settings.json"
  mkdir -p "$ROTATE_HOME/.claude/settings.json"
  blocked_status=0
  blocked_output=$(PATH="$TEMP_HOME/bin:$PATH" \
    CLAUDE_COMMAND_LOG="$ROTATE_HOME/claude-commands" HOME="$ROTATE_HOME" \
    KB_WRITER_INSTALL_SKIP_PLUGIN=1 \
    KB_WRITER_API_BASE_URL='https://example.test/base/' \
    KB_WRITER_ACCESS_TOKEN='kbw_pat_test' bash "$installer" 2>&1) || blocked_status=$?
  rmdir "$ROTATE_HOME/.claude/settings.json"
  [ "$blocked_status" -ne 0 ] || { echo "installer reported success despite an unwritable settings file: $installer"; exit 1; }
  [[ "$blocked_output" != *'Stored the access token'* ]] || { echo "installer falsely claimed a token write: $installer"; exit 1; }
  [[ "$blocked_output" != *'kbw_pat_test'* ]] || { echo "installer leaked token on failure: $installer"; exit 1; }
done

echo 'remote MCP installer configuration verified'
