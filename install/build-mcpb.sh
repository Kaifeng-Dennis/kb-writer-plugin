#!/usr/bin/env bash
# Builds install/kb-writer-mcp.mcpb, the Claude Desktop extension that carries
# the local stdio MCP server into Cowork sessions. Cowork never starts the
# server declared in the plugin's own .mcp.json, so the plugin ships skills and
# this bundle ships the tools they call.
#
# The bundle wraps mcp-server/dist verbatim; run mcp-server's build first if the
# TypeScript sources changed. The archive is byte-reproducible so CI can assert
# the committed .mcpb still matches dist with `git diff --exit-code`.
set -euo pipefail

plugin_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
repo_root="$(git -C "$plugin_dir" rev-parse --show-toplevel)"
out="${plugin_dir}/install/kb-writer-mcp.mcpb"
# The backend serves this file to Cowork users, but its Docker build
# context is backend/ alone, so it cannot read the plugin directory at
# image build time. The copy has to be committed, and it is written here
# rather than by hand so the two can never drift apart.
backend_copy="${repo_root}/backend/src/main/resources/plugin-downloads/kb-writer-mcp.mcpb"

version="$(python3 -c '
import json, sys
print(json.load(open(sys.argv[1]))["version"])
' "${plugin_dir}/.claude-plugin/plugin.json")"

python3 - "$plugin_dir" "$out" "$version" <<'PY'
import json, sys, zipfile
from pathlib import Path

plugin_dir, out, version = Path(sys.argv[1]), Path(sys.argv[2]), sys.argv[3]
dist = plugin_dir / "mcp-server" / "dist"

manifest = {
    "manifest_version": "0.3",
    "name": "kb-writer-mcp",
    "display_name": "KB Writer MCP",
    "version": version,
    "description": "KB Writer capability tools: tickets, intent workspaces, manifests, drafts, review and publication.",
    "long_description": (
        "Local stdio MCP server for KB Writer. Pairs with the kb-writer plugin's skills, which "
        "look tools up by capability name and so do not depend on the namespace prefix Claude "
        "Desktop derives from this extension. Requires network access to the KB Writer backend "
        "(VPN or corporate network)."
    ),
    "author": {"name": "Smart KB team"},
    "server": {
        "type": "node",
        "entry_point": "server/start.js",
        "mcp_config": {
            "command": "node",
            "args": ["${__dirname}/server/start.js"],
            "env": {
                "KB_WRITER_ACCESS_TOKEN": "${user_config.KB_WRITER_ACCESS_TOKEN}",
                "KB_WRITER_API_BASE_URL": "${user_config.KB_WRITER_API_BASE_URL}",
            },
        },
    },
    "user_config": {
        "KB_WRITER_ACCESS_TOKEN": {
            "type": "string",
            "title": "KB Writer access token",
            "description": (
                "Personal access token (kbw_pat_...) from KB Writer -> avatar menu -> "
                "Claude Plugin Setup. Cowork can only reach production, so a token issued "
                "by stage or a local backend will not authenticate."
            ),
            "required": True,
            "sensitive": True,
        },
        "KB_WRITER_API_BASE_URL": {
            "type": "string",
            "title": "KB Writer backend URL",
            # The server reads `process.env.X ?? default`, and an empty string is
            # not nullish, so a cleared field becomes the request base URL and
            # every call fails. Required plus a default keeps it populated.
            "description": "Leave this at the production URL. An empty value is used verbatim and breaks every request.",
            "required": True,
            "default": "https://kb-companion.int.rclabenv.com",
            "sensitive": False,
        },
    },
    "compatibility": {"runtimes": {"node": ">=18.0.0"}},
}

# Every compiled file, not a hand-kept list: index.js imports its siblings, so
# a module left out of the bundle only shows up as an extension that installs
# and then fails to start.
compiled = sorted(dist.glob("*.js"))
assert compiled, f"no compiled server found in {dist}; run mcp-server's build first"

entries = [
    ("manifest.json", json.dumps(manifest, indent=2).encode() + b"\n"),
    ("server/package.json", b'{ "type": "module" }\n'),
    ("server/start.js", (plugin_dir / "install" / "mcpb" / "start.js").read_bytes()),
    *((f"server/{path.name}", path.read_bytes()) for path in compiled),
]

# Fixed timestamps and sorted names: the archive must be identical across
# machines or the CI drift check fires on every unrelated build.
with zipfile.ZipFile(out, "w", zipfile.ZIP_DEFLATED) as bundle:
    for name, payload in sorted(entries):
        info = zipfile.ZipInfo(name, date_time=(1980, 1, 1, 0, 0, 0))
        info.external_attr = 0o644 << 16
        info.compress_type = zipfile.ZIP_DEFLATED
        bundle.writestr(info, payload)

print(f"built {out} (version {version})")
PY

mkdir -p "$(dirname "$backend_copy")"
cp "$out" "$backend_copy"

# The backend reports this to the setup dialog and compares it against the
# version each MCP client announces, so it has to come from the same
# manifest the bundle was built from rather than a second hand-kept copy.
printf '%s\n' "$version" > "$(dirname "$backend_copy")/version.txt"
