# KB Writer 插件 MCP 配置向导

> **推荐**：直接在新线程里说「setup」或「帮我配置 KB Writer」，触发 `kb-writer:setup` skill 交互式完成全部配置（检查环境 → 登录拿 token → 可选配 Atlassian MCP 上下文 → 验证）。本文档是它背后手动/参考用的完整说明。

KB Writer 插件可使用两类 MCP server：

| MCP server | 用途 | 必需性 |
|---|---|---|
| `kb-writer`（remote MCP） | 结构化调用 KB Writer 后端并记录 skill 使用量 | 推荐；installer 会自动注册 |
| `mcp-atlassian-service` | Jira/Confluence 上下文 | 可选；缺失时 Jira/Confluence 上下文需手动粘贴 |

Skill 使用量通过 KB Writer MCP 的 `track_skill_usage` 记录，不再依赖 Atlassian MCP。统计调用失败只会使该次使用量缺失，不阻塞 skill 主流程。

## 1. kb-writer MCP server

`kb-writer` remote MCP 由插件根目录的 `.mcp.json` 提供，装上插件就有，**不需要**手工 `claude mcp add`，也不要把 `mcpServers` JSON 粘到 `~/.claude/settings.json`（会让同一批工具重复出现两次）。它只需要两项配置：

| 配置 | 存放位置 | 说明 |
|---|---|---|
| `KB_WRITER_ACCESS_TOKEN` | `~/.claude/settings.json` 的 `pluginConfigs["kb-writer@kb-writer"].options` | `.mcp.json` 以 `${user_config.KB_WRITER_ACCESS_TOKEN}` 读回，Claude 从这里解析。走 `/plugin configure` 手填会存进 OS keychain；installer 走 settings 文件（明文），因为 CLI 的 `--config` 实测不落盘 |
| `KB_WRITER_API_BASE_URL` | `~/.claude/settings.json` 的 `env` | 非敏感；`.mcp.json` 内置生产地址兜底，只在指向 stage/本地时才需要设置 |

### 支持范围：Claude Code、Codex 和 Claude Cowork

Claude Code 和 Codex 使用本地插件与 PAT 配置，`.mcp.json` 里的 remote MCP 条目直接生效。**Cowork 不走这条路**，需要分两次安装，见下。

### Claude Cowork：插件装 skills，桌面扩展装工具

Cowork 从账号级（服务端）marketplace 解析插件，不读 `~/.claude` 下的任何配置，**也不会启动插件 `.mcp.json` 里声明的 server**。只装插件的结果是 skills 可以触发但一个 MCP 工具都没有，而所有写操作 skill 都带 MCP 守卫，会在第一步就停下。所以两样都要装：

**1. Skills —— 装插件**

Customize → Plugins → **+** → Add marketplace，填 `https://github.com/Kaifeng-Dennis/kb-writer-plugin`，然后安装 kb-writer。这里如果要求填 token，填什么都行：插件的 `.mcp.json` 在 Cowork 里是死的，这个 token 不会被用到。

> **不想加 marketplace？** 也可以从 KB Writer 网页版头像菜单 → **Claude Plugin Setup** → Claude Cowork 页签下载插件文件，走 Plugins → **Add → Upload plugin** 上传。内容和 marketplace 版本同源（都出自 git 跟踪的文件），区别只是不会自动更新。注意上传对话框只认 `.zip` 扩展名。

**2. 工具 —— 装桌面扩展**

从 KB Writer 网页版头像菜单 → **Claude Plugin Setup** → Claude Cowork 页签下载 `kb-writer-mcp.mcpb`（后端直接提供，不经 GitHub），在桌面 App 里 Settings → Extensions → Advanced settings → **Extension Developer** 安装。安装时填两项：

| 字段 | 填什么 |
|---|---|
| KB Writer access token | 头像菜单 → Claude Plugin Setup 生成的 `kbw_pat_...` |
| KB Writer backend URL | **保持默认，不要清空**。server 用的是 `process.env.X ?? default`，空字符串不是 nullish，会被当成请求地址，结果是所有调用都失败 |

两个文件同样发布在插件镜像的 `install/` 目录下，脚本化场景可以直接取；界面上的按钮走后端 `/v1/plugin-downloads/`，因为同源才能直接触发下载而不是打开新标签页。

装完**必须新开一个 Cowork 会话**，MCP 工具目录只在会话启动时刷新。

> 别试图把 stdio server 直接写进插件的 `.mcp.json` 来省掉这一步：Cowork 会以 `not_started (user_config_unsupported)` 跳过任何引用 `${user_config.<key>}` 的条目，而 token 只能从那里来。独立的 `.mcpb` 扩展不受这个限制，这正是要分两步装的原因。

扩展里的服务跑在 PM 自己的机器上，所以需要 VPN / 公司网络才能访问后端。base URL 是扩展自己的配置项，所以指向 stage 是可以的——但必须和签发 token 的后端一致，否则认证不过。

这也划定了适用范围：**这套装法针对桌面 App 里的 Cowork**（已实测可用）。扩展是装在设备上的，进程也起在设备上，因此后端只要在该设备可达就行。换成在云端运行的 Cowork 会话则不适用——那里既没有这个设备扩展，直连 `kb-companion.int.rclabenv.com` 也会被出网策略挡掉。云端场景要等公开 Ingress，见下一节。

> 扩展的工具带的是它自己的命名空间前缀（`mcp__KB_Writer_MCP__*`），和插件那套 `kb-writer` 不同。skills 按能力名做子串匹配而不是硬编码全名，所以不受影响——改动 skills 时别把这个特性写没了。

### 更新：skills 自动，扩展要手动

三条通道的更新方式不同，这是分两步安装的代价：

| 通道 | 怎么更新 |
|---|---|
| 插件（marketplace） | `plugin.json` 的 `version` 一变，客户端自动重新同步 |
| 插件（上传 zip） | 重新下载、重新上传 |
| `.mcpb` 扩展 | 重新下载、重新安装 |

风险在于 **skills 会自己往前走，扩展不会**。新 skill 调用老扩展没有的工具时，skills 按自己的规则会判定「MCP 不可用」并让 PM 去重连——这个提示是错的，照做也没用。

为此加了两层提示：

0. **下载下来的文件名带版本号**（`kb-writer-mcp-<版本>.mcpb`）。服务端路径保持不带版本，否则每次发版都要改文档和界面里的链接；版本只出现在保存到本地的文件名里，这样 Downloads 里堆了几份也分得清，被要求重装时也能看出手上这份是不是。
1. **对话框显示版本号**。Claude Plugin Setup → Claude Cowork 页签的标题旁标着后端当前发布的版本，桌面 App 的扩展列表里能看到已装版本，对一下就知道要不要重装。
2. **后端主动告知过期**。MCP server 每次调用都带 `X-KB-Writer-Client-Version`；后端发现比自己发布的版本旧，就回一个 `X-KB-Writer-Client-Outdated`，server 把它变成工具结果里的一条提示，模型会直接告诉 PM 去重装扩展。

版本号只有一个来源：`.claude-plugin/plugin.json`。构建时分别生成 `mcp-server/version.ts`（编译进 server）和 `backend/.../plugin-downloads/version.txt`（后端读），CI 校验三者一致。

非纯数字的版本号（本地构建、RC）不会被判过期，避免拿自己构建的开发版的人被反复催着去装发布版。

### 远程 OAuth connector（暂不可用）

长期方向仍是让 Cowork 直接连远程 MCP，省掉本地扩展：为 KB Writer 配置公开 HTTPS Ingress，由 Enterprise Owner 在 Custom Web connector 里填 canonical `https://<kb-writer-host>/mcp`，通过 OAuth metadata 宣告 DCR 和 PKCE，Client ID/Secret 留空。

**当前不具备条件**：后端只有内网地址（`kb-companion.int.rclabenv.com` 解析到 `100.64.1.13`），公开 Ingress 尚未落地，`/mcp` 与 `/.well-known/` 也还没路由到 KB Writer。在那之前，Cowork 用户一律走上面的桌面扩展路径。

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

仅当客户端不支持 HTTP MCP 或无法直连后端时，才手工使用插件内的 local stdio adapter。不要同时注册 local 与 remote `kb-writer`，否则同一批 36 个工具会重复出现。

## 2. Atlassian MCP server（仅用于 Jira/Confluence 上下文）

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
- 验证：新线程里问「列出可用的 MCP 工具」，确认 Jira/Confluence 能力可用；此 server 与 skill 使用量统计无关

## 3. Skill 使用量统计

- 每个 skill 启动时向 KB Writer MCP 调用一次 `track_skill_usage`，传入 skill 名称、对应客户端的插件版本与 `source_app`（`codex`、`claude_code` 或 `claude_cowork`）。
- 后端根据 KB Writer PAT 认证结果记录使用者，事件时间由后端赋值；skill 不传用户名或 token 作为统计参数。
- 在 KB Writer 的 Dev Dashboard 的独立 **Skill Usage** 区域查看；它不与 **Usage Activity Details** 混合。
- 统计是非阻塞的。如果工具不可用或调用失败，skill 正常继续，不经 shell/HTTP 补报，也不再回退到外部 tracker。

## 4. 故障排查

| 现象 | 原因 | 处理 |
|---|---|---|
| 新线程里没有 `track_skill_usage` 工具 | KB Writer MCP 未连接、客户端目录未刷新，或 Cowork 扩展未更新 | 检查 KB Writer MCP 连接；Cowork 重新安装当前 `.mcpb`，并开新会话。统计缺失不阻塞 skill |
| 未发现 `kb-writer` MCP 工具 | 安装后客户端未刷新，或安装时没有 PAT | 用 PAT 重新运行 installer，并打开新线程/重启客户端 |
| 报 `KB_WRITER_ACCESS_TOKEN isn't set` | `userConfig` 没填 | `/plugin configure kb-writer@kb-writer`，或带 PAT 重跑 installer |
| Cowork 里 skills 能触发但一个 MCP 工具都没有 | 只装了插件，没装桌面扩展；插件的 `.mcp.json` 在 Cowork 里不生效 | 按「Claude Cowork」一节装 `kb-writer-mcp.mcpb`，然后新开会话 |
| Cowork 装了扩展仍然没有工具 | 会话未刷新，或扩展启动失败 | 先新开会话；仍然没有就看扩展的错误信息，重点确认桌面 App 能否找到 `node` |
| 扩展状态是 `not_started (user_config_unsupported)` | 该条目引用了 `${user_config.*}` 而当前环境不提供 | 确认装的是独立 `.mcpb` 扩展，不是插件 `.mcp.json` 里的 local 条目；重装一次扩展 |
| 工具结果里出现「extension … is available」提示 | 已装扩展落后于后端发布版本 | 按「Claude Cowork」一节重新下载并安装 `.mcpb`，然后新开会话 |
| Cowork 里工具能看到但调用全失败 | 扩展跑在本机，连不到内网后端，或 backend URL 被清空 | 确认 VPN / 公司网络；检查扩展配置里的 backend URL 不是空值 |
| 同一批工具出现两遍 | 除插件自带的 `.mcp.json` 外还手工注册过 `kb-writer`，或在 Claude Code 里同时装了桌面扩展 | 删掉 settings 里的 `mcpServers.kb-writer`；桌面扩展只在 Cowork 需要，Claude Code 用户不要装 |
| token 轮换后仍是旧的 | `pluginConfigs` 已更新，但 `~/.claude.json` 里还留着旧版 user-scope 注册，优先级更高 | `claude mcp remove kb-writer --scope user`（见上面「从旧版本升级」） |
| 明明配了 stage 却打到生产 | 只填了 token，没配 `KB_WRITER_API_BASE_URL` | 按上面「手动填 token」把 base URL 写进 `~/.claude/settings.json` |
