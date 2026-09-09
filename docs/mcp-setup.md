# KB Writer 插件 MCP 配置向导

> **推荐**：直接在新线程里说「setup」或「帮我配置 KB Writer」，触发 `kb-writer:setup` skill 交互式完成全部配置（检查环境 → 登录拿 token → 可选配 Atlassian MCP → 验证）。本文档是它背后手动/参考用的完整说明。

KB Writer 插件的 skill 运行时依赖两类 MCP server：

| MCP server | 用途 | 必需性 |
|---|---|---|
| `kb-writer`（remote MCP） | 结构化调用 KB Writer 后端（skill 内优先于 raw HTTP） | 推荐；installer 会自动注册 |
| `mcp-atlassian-service` | Jira/Confluence 上下文 + 使用量 tracking（`pm_toolkit_track`） | 可选，缺失时 tracking 静默跳过、Jira/Confluence 上下文需手动粘贴 |

两者的缺失都不会阻塞 skill 主流程，但配置后体验完整。

## 1. kb-writer MCP server

`kb-writer` remote MCP 由插件根目录的 `.mcp.json` 提供，装上插件就有，**不需要**手工 `claude mcp add`，也不要把 `mcpServers` JSON 粘到 `~/.claude/settings.json`（会让同一批工具重复出现两次）。它只需要两项配置：

| 配置 | 存放位置 | 说明 |
|---|---|---|
| `KB_WRITER_ACCESS_TOKEN` | `~/.claude/settings.json` 的 `pluginConfigs["kb-writer@kb-writer"].options` | `.mcp.json` 以 `${user_config.KB_WRITER_ACCESS_TOKEN}` 读回，Claude 从这里解析。走 `/plugin configure` 手填会存进 OS keychain；installer 走 settings 文件（明文），因为 CLI 的 `--config` 实测不落盘 |
| `KB_WRITER_API_BASE_URL` | `~/.claude/settings.json` 的 `env` | 非敏感；`.mcp.json` 内置生产地址兜底，只在指向 stage/本地时才需要设置 |

### 支持范围：Claude Code 和 Codex

**Claude Cowork 不支持。** Cowork 桌面端的插件来自账号级（服务端）marketplace，不读 `~/.claude` 下的任何东西，所以 installer 写什么都到不了它；而且本地→远端的 marketplace 迁移是一次性的、sentinel 已打上，本地新加的 marketplace 也不会再同步上去。Cowork 用户只能在 app 里走 Customize → Plugins → **+** → Add marketplace，然后把 token 粘进 Cowork 自己的配置弹窗。另外 Cowork 没有任何入口设 `KB_WRITER_API_BASE_URL`，所以它只能连生产。

### 一键安装（推荐）

在 KB Writer 页面点头像 → **Claude Plugin Setup** → *Generate token & copy install command*，粘贴执行即可：

```bash
KB_WRITER_ACCESS_TOKEN="kbw_pat_..." \
  curl -fsSL https://raw.githubusercontent.com/Kaifeng-Dennis/kb-writer-plugin/main/install/claude.sh | bash
```

它跑 `claude plugin install kb-writer@kb-writer --scope user --yes`，装完把 token 写进 `~/.claude/settings.json` 的 `pluginConfigs`，再读回文件确认写进去了。重复执行同一条命令即可轮换 token。

installer **不**用 `claude plugin install --config` 传 token：那条命令无论有没有存下来都 exit 0 并打印成功，CLI 2.1.263 上实测什么都不写（既没有 `pluginConfigs`，也没有 keychain 条目），插件因此拿不到 token，`${user_config.KB_WRITER_ACCESS_TOKEN}` 展不开，一个 kb-writer 工具都不会出现。

### 从旧版本升级需要手动清理一次

installer 只负责全新安装，**不做迁移**。装过旧版的人在跑新 installer 之前，请自行清掉下面几处，否则轮换 token 不生效：

```bash
# 1. 旧版 `claude mcp add --scope user` 注册的 server（连着明文 token），
#    位于 ~/.claude.json；user scope 同名 server 优先级高于插件自带的
#    .mcp.json，不删掉就会一直走旧 token。
claude mcp remove kb-writer --scope user
```

2. `~/.claude/settings.json` 里 `env.KB_WRITER_ACCESS_TOKEN` 一行 —— 删掉，token 现在只从 `pluginConfigs` 读。
3. 同一文件里按旧文档粘进去的 `mcpServers.kb-writer` —— 删掉，否则同一批工具会出现两遍。
4. 旧 installer 写下的 `~/.claude/cowork_settings.json` 和 `~/.claude/cowork_plugins/` —— 已不再使用，可以整个删掉。

未提供 PAT 时 installer 只安装插件并把 token 步骤留给下面的手动路径。

> installer 写进 settings 文件的 token 是明文。介意的话走下面的手动路径：在 Claude 里填 `/plugin configure`，Claude 会存进 OS keychain，之后可以把 settings 里的 `pluginConfigs` 条目删掉。

### 手动填 token（不想用 installer 时）

1. Claude → **+** → Add marketplace → 填 `https://github.com/Kaifeng-Dennis/kb-writer-plugin`
2. Browse plugins → 找到 **kb-writer** → Install
3. 启用时 Claude 会弹出掩码输入框要 `KB_WRITER_ACCESS_TOKEN`，把 PAT 粘进去；之后想改用 `/plugin configure kb-writer@kb-writer`

指向 stage/本地后端时，额外把 base URL 合并进 `~/.claude/settings.json`：

```json
{
  "env": {
    "KB_WRITER_API_BASE_URL": "https://kb-companion-stage.int.rclabenv.com"
  }
}
```

macOS GUI 应用不会继承 `~/.zshrc` 的 `export`，所以 GUI 用户必须走 settings 的 `env`；Claude Code CLI 用户也可以直接写 shell profile。

Codex 侧没有 `userConfig` 这套机制，仍由 `install/codex.sh` 把 `[env]` 和 `[mcp_servers.kb-writer]` 写进 `~/.codex/config.toml`，token 在那里是明文。

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
| 报 `KB_WRITER_ACCESS_TOKEN isn't set` | `userConfig` 没填 | `/plugin configure kb-writer@kb-writer`，或带 PAT 重跑 installer |
| Cowork 里没有 KB Writer | Cowork 不支持，见上面「支持范围」 | 在 Cowork app 里手动 Add marketplace + 粘 token，且只能连生产 |
| 同一批工具出现两遍 | 除插件自带的 `.mcp.json` 外还手工注册过 `kb-writer` | 删掉 settings 里的 `mcpServers.kb-writer` |
| token 轮换后仍是旧的 | `pluginConfigs` 已更新，但 `~/.claude.json` 里还留着旧版 user-scope 注册，优先级更高 | `claude mcp remove kb-writer --scope user`（见上面「从旧版本升级」） |
| 明明配了 stage 却打到生产 | 只填了 token，没配 `KB_WRITER_API_BASE_URL` | 按上面「手动填 token」把 base URL 写进 `~/.claude/settings.json` |
