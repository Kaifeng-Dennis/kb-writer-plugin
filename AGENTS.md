# KB Writer Plugin Guidelines

## Plugin Releases

When changing content that either client consumes from this plugin, update the
corresponding version in the same commit:

- Claude: increment the semantic version in `.claude-plugin/plugin.json`.
- Codex: preserve the semantic prefix and replace the `+codex.<cachebuster>`
  suffix in `.codex-plugin/plugin.json` with a new cachebuster.

Shared content, including `.mcp.json`, `mcp-server/`, and `skills/`, requires
both updates. Claude- or Codex-only content requires only that client's
version update. Do not bump either version for changes outside this directory
or for metadata intended exclusively for the other client.
