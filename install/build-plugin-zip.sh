#!/usr/bin/env bash
# Builds install/kb-writer-plugin.zip, the uploadable copy of this plugin for
# Claude Desktop's Plugins -> Add -> Upload plugin, for users who cannot or do
# not want to add the GitHub marketplace.
#
# The upload dialog only accepts a .zip extension; a .plugin file is rejected
# even though the file picker offers it.
#
# Contents come from the source tree, including newly added non-ignored plugin
# files. The archive excludes itself: a zip that contained the previous build
# of itself would never reproduce.
set -euo pipefail

plugin_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
repo_root="$(git -C "$plugin_dir" rev-parse --show-toplevel)"
prefix="$(python3 -c '
import os, sys
print(os.path.relpath(sys.argv[1], sys.argv[2]))
' "$plugin_dir" "$repo_root")"
out="${plugin_dir}/install/kb-writer-plugin.zip"
self="install/kb-writer-plugin.zip"
# Mirrored into the backend for the same reason as the .mcpb: the image
# build cannot see this directory, so CI writes the served copy before build.
backend_copy="${repo_root}/backend/src/main/resources/plugin-downloads/kb-writer-plugin.zip"

# macOS ships bash 3.2, which has no mapfile.
tracked=()
while IFS= read -r entry; do
  tracked+=("$entry")
done < <(git -C "$repo_root" ls-files --cached --others --exclude-standard -- "$prefix" \
  | sed "s|^${prefix}/||" \
  | grep -v "^${self}$" \
  | sort)

python3 - "$plugin_dir" "$out" "${tracked[@]}" <<'PY'
import sys, zipfile
from pathlib import Path

plugin_dir, out, *names = sys.argv[1:]
plugin_dir, out = Path(plugin_dir), Path(out)

with zipfile.ZipFile(out, "w", zipfile.ZIP_DEFLATED) as bundle:
    for name in names:
        source = plugin_dir / name
        if not source.is_file():
            # Tracked but absent: the vendor/ submodule is never checked out
            # here and git archive ships it empty to the mirror too.
            continue
        info = zipfile.ZipInfo(name, date_time=(1980, 1, 1, 0, 0, 0))
        info.external_attr = (0o755 if source.stat().st_mode & 0o100 else 0o644) << 16
        info.compress_type = zipfile.ZIP_DEFLATED
        bundle.writestr(info, source.read_bytes())

print(f"built {out} ({out.stat().st_size / 1024:.0f} KB, {len(names)} entries)")
PY

mkdir -p "$(dirname "$backend_copy")"
cp "$out" "$backend_copy"
