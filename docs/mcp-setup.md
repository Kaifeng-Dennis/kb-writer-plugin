# KB Writer 插件 MCP 配置向导

> **推荐**：直接在新线程里说「setup」或「帮我配置 KB Writer」，触发 `kb-writer:setup` skill 交互式完成全部配置（检查环境 → 登录拿 token → 可选配 Atlassian MCP → 验证）。本文档是它背后手动/参考用的完整说明。

KB Writer 插件的 skill 运行时依赖两类 MCP server：

| MCP server | 用途 | 必需性 |
|---|---|---|
| `kb-writer`（remote MCP） | 结构化调用 KB Writer 后端（skill 内优先于 raw HTTP） | 推荐；installer 会自动注册 |
| `mcp-atlassian-service` | Jira/Confluence 上下文 + 使用量 tracking（`pm_toolkit_track`） | 可选，缺失时 tracking 静默跳过、Jira/Confluence 上下文需手动粘贴 |

两者的缺失都不会阻塞 skill 主流程，但配置后体验完整。

## 1. kb-writer MCP server

用 PAT 运行 installer 时，会自动在 Codex 或 Claude 的用户配置中注册名为 `kb-writer` 的 remote MCP。Claude installer 使用 `claude mcp add --transport http`，由 Claude CLI 写入正确的用户配置和 transport 类型，而不是手写 JSON。installer 同时保留两个环境变量，供未支持 MCP 的 skill HTTP fallback 使用：

```bash
export KB_WRITER_API_BASE_URL="https://kb-companion.int.rclabenv.com"   # 可选；不设置时默认就是这个生产地址
export KB_WRITER_ACCESS_TOKEN="<KB Writer 页面 Claude Plugin Setup 生成的 PAT（kbw_pat_...，长期有效）>"
```

例如：

```bash
KB_WRITER_ACCESS_TOKEN="kbw_pat_..." \
  curl -fsSL https://raw.githubusercontent.com/Kaifeng-Dennis/kb-writer-plugin/main/install/codex.sh | bash
```

`KB_WRITER_API_BASE_URL` 未设置时默认生产地址；若设置为本地或 stage 地址，installer 会把其尾部 `/` 去除后注册 `${KB_WRITER_API_BASE_URL}/mcp`。安装后打开新线程（Codex）或重启 Claude 后打开新线程，客户端会发现 remote MCP 工具。

未提供 PAT 时 installer 只安装插件，不会写入半配置 MCP；获取 PAT 后使用同一命令重新运行即可。

### Claude desktop app 的手动 marketplace 安装

通过 Claude desktop app 添加 marketplace 并安装插件后，插件根目录的 `.mcp.json` 会自动提供 `kb-writer` remote MCP，**不要**再把 `mcpServers` JSON 粘贴到 `~/.claude/settings.json`。只需把环境变量合并到该文件的 `env` 对象：

```json
{
  "env": {
    "KB_WRITER_API_BASE_URL": "https://kb-companion.int.rclabenv.com",
    "KB_WRITER_ACCESS_TOKEN": "kbw_pat_..."
  }
}
```

重启 Claude desktop app 并打开新线程。macOS GUI 应用不会继承 `~/.zshrc` 的 `export`；Claude Code CLI 用户则可把同样的两个变量写进 shell profile。

### Remote MCP（Streamable HTTP）

remote MCP 是默认连接路径；支持 Streamable HTTP 的客户端也可手工添加同一配置：

```text
https://kb-companion.int.rclabenv.com/mcp
```

请求使用与本地 adapter 相同的个人访问令牌：

```text
Authorization: Bearer kbw_pat_...
```

该 endpoint 使用 MCP Streamable HTTP。客户端必须在每个 `POST` 的 `Accept` header 中同时声明 `application/json` 和 `text/event-stream`；当前服务返回单个 JSON-RPC JSON 响应，不建立 MCP session 或 SSE stream。

### Local stdio compatibility fallback

仅当客户端不支持 HTTP MCP 或无法直连后端时，才手工使用插件内的 local stdio adapter。不要同时注册 local 与 remote `kb-writer`，否则同一批 35 个工具会重复出现。

## 2. Atlassian MCP server（tracking + Jira/Confluence 上下文）

### 2.1 获取 token

按 [How to get jira/confluence token](https://wiki.ringcentral.com/pages/viewpage.action?pageId=1072663398&spaceKey=COLFR&title=How%2Bto%2Bset%2Bup%2BAI%2BCode%2BReview#HowtosetupAICodeReview?-2.1MCP(UsingCodexasanexample)) 申请 `jira-read-token` 和 `confluence-read-token`。

**不要把 token 提交进任何仓库。**

### 2.2 配置方式（二选一）

**方式 A：`~/.codex/config.toml`**

```toml
[mcp_servers.mcp-atlassian-service]
url = "https://mcp-atlassian.int.rclabenv.com/mcp/"
http_headers = { "confluence-read-token" = "<你的 confluence token>", "jira-read-token" = "<你的 jira token>" }
```

**方式 B：Codex App**

Settings → MCP servers，添加同样的 URL 与 headers（参考 pm-toolkit README 的截图 `docs/codex_app_mcp.png`）。

### 2.3 生效与验证

- 改完配置后**开新线程**，MCP 工具目录才会刷新
- 验证：新线程里问「列出可用的 MCP 工具」，应能看到 `pm_toolkit_track`
- tracking 失败（未配置、token 失效、服务不可达）不会报错也不会影响 skill，只是 dashboard 上少一条记录

## 3. Tracking 说明

- 每个 skill 启动时会用 `skill_name` + 插件版本 + `source_app: "codex"` 调一次 `pm_toolkit_track`
- 身份由 MCP server 通过 `jira-read-token` 调 Jira `/myself` 解析，token 不会离开你的环境到插件代码里
- Dashboard：https://agent-cli-platform.int.rclabenv.com/pm_toolkit_tracking
- 该 dashboard 与 pm-toolkit 共用；kb-writer 的 skill 以 `kb-ticket`、`create-kb-intent` 等名字记录，可在看板上按 skill_name 区分

## 4. 故障排查

| 现象 | 原因 | 处理 |
|---|---|---|
| 新线程里没有 `pm_toolkit_track` 工具 | MCP 未配置或未刷新 | 检查 config.toml，重开线程 |
| tracking 有数据但 username=unknown | `jira-read-token` 失效或 `/myself` 不可达 | 重新申请 token |
| 未发现 `kb-writer` MCP 工具 | 安装后客户端未刷新，或安装时没有 PAT | 用 PAT 重新运行 installer，并打开新线程/重启客户端 |
