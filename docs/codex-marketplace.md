# Codex 自动更新

`install/codex.sh` 使用 Codex 的原生 Git marketplace 命令安装或即时刷新 KB Writer；它不再直接写插件 cache。

要让整个工作区自动更新，Workspace admin 需要在 **Workspace settings → Plugins → Add → Import marketplace** 中导入：

- **Source**：`https://github.com/Kaifeng-Dennis/kb-writer-plugin.git`
- **Path**：留空（仓库根目录包含 `.agents/plugins/marketplace.json`）
- **Branch**：`main`（不要固定 commit SHA）

新导入的 Codex marketplace 会每日同步 GitHub。需要立即刷新时，在 **Workspace settings → Plugins → Marketplaces → kb-writer → Sync now** 触发同步。管理员还必须在工作区中为目标成员配置插件 installation policy；该策略不从 marketplace 文件同步。导入 marketplace 也不会自动授予后端访问权限或配置 `KB_WRITER_ACCESS_TOKEN`。

本地开发或首次安装可运行：

```bash
curl -fsSL https://raw.githubusercontent.com/Kaifeng-Dennis/kb-writer-plugin/main/install/codex.sh | bash
```

脚本会注册/刷新本机的 Git marketplace 并从中安装 KB Writer。它不能替代工作区管理员的 marketplace import，也不能自行启用工作区的每日同步。
