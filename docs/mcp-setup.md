# KB Writer 插件 MCP 配置向导

> **推荐**：直接在新线程里说「setup」或「帮我配置 KB Writer」，触发 `kb-writer:setup` skill 交互式完成全部配置（检查环境 → 登录拿 token → 可选配 Atlassian MCP → 验证）。本文档是它背后手动/参考用的完整说明。

KB Writer 插件的 skill 运行时依赖两类 MCP server：

| MCP server | 用途 | 必需性 |
|---|---|---|
| `kb-writer`（随插件附带） | 结构化调用 KB Writer 后端（skill 内优先于 raw HTTP） | 可选，未注册时 skill 自动降级为 HTTP |
| `mcp-atlassian-service` | Jira/Confluence 上下文 + 使用量 tracking（`pm_toolkit_track`） | 可选，缺失时 tracking 静默跳过、Jira/Confluence 上下文需手动粘贴 |

两者的缺失都不会阻塞 skill 主流程，但配置后体验完整。

## 1. kb-writer MCP server

插件已通过 `.mcp.json` 自动注册（server 源码随插件打包在 `mcp-server/` 内，无需仓库内其他目录），无需手动配置。它读取两个环境变量：

```bash
export KB_WRITER_API_BASE_URL="http://localhost:8080"   # 可选；不设置时默认就是 http://localhost:8080
export KB_WRITER_BEARER_TOKEN="<POST /v1/auth/login 拿到的 JWT>"
```

未设置时 skill 会在用到时提示配置，不会猜默认值。

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
| skill 提示缺 `KB_WRITER_*` 环境变量 | kb-writer MCP 的环境未设置 | 按第 1 节设置后重开线程 |
