# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with this repository.

## 项目概述

Claude Code 模型切换插件，通过 `/model_switch` 斜杠命令在 AI 提供商和模型之间切换。支持多提供商（每个提供商含多个模型），作用于项目级或全局级别。

## 目录结构

```
├── skills/model-switch/
│   ├── SKILL.md              # Skill 定义（触发条件、流程、错误处理）
│   └── scripts/
│       ├── switch-model.sh   # 将 env 配置写入 settings 文件的 Shell 脚本
│       └── show-scope-status.sh  # 显示当前项目/全局作用域的模型配置状态
├── docs/superpowers/specs/   # 设计规格文档
└── README.md                 # 用户文档
```

## 关键文件与接口契约

### `skills/model-switch/SKILL.md`
Skill 定义文件，包含：
- 触发条件：Claude Code CLI 中的 `/model_switch` 命令
- 流程：读取 profiles → 选择提供商 → 选择模型 → 选择作用域 → 执行切换
- 与 `scripts/switch-model.sh` 的脚本契约

### `skills/model-switch/scripts/switch-model.sh`
执行实际切换的 Shell 脚本：
- 接收 4 个参数：`provider_name`、`model_name`、`scope`（project|global）、`project_path`
- 通过 `jq` 从 `~/.claude/model-profiles.json` 读取提供商配置
- 将 `env` 块（`ANTHROPIC_MODEL`、`ANTHROPIC_BASE_URL`、`ANTHROPIC_AUTH_TOKEN`）写入目标 settings 文件
- 保留目标文件中的其他字段不变
- 若提供商/模型不存在或 profiles 文件缺失，则报错退出

### `skills/model-switch/scripts/show-scope-status.sh`
显示当前作用域状态的辅助脚本：
- 接收 1 个参数：`project_path`
- 读取项目级和全局级 settings 文件的 `env.ANTHROPIC_MODEL`
- 输出人类可读的状态摘要（用于 SKILL.md 第 4 步）

### Provider 注册表（`~/.claude/model-profiles.json`）
外部 JSON 文件（不在本仓库中），存储所有提供商配置。示例：
```json
{
  "providers": [{ "name": "bailian", "base_url": "...", "auth_token": "...", "models": ["qwen3.6-plus"] }],
  "active_provider": "bailian",
  "active_model": "qwen3.6-plus"
}
```

### Settings 文件层级
| 作用域 | 目标文件 | 优先级 |
|--------|----------|--------|
| 项目级 | `<project>/.claude/settings.local.json` | 最高 |
| 全局级 | `~/.claude/settings.json` | 兜底 |

## 开发命令

本项目无需编译/测试命令，纯 Shell 脚本 + Markdown 组成的配置型插件项目。

手动测试方式：
1. 修改 `SKILL.md` 或 `switch-model.sh`
2. 在 Claude Code CLI 中执行 `/model_switch`
3. 验证目标 settings 文件写入了正确的 `env` 块

## 架构说明

- **无编译代码**：插件纯由声明式文件（SKILL.md）+ Shell 脚本组成
- **依赖 `jq`**：切换脚本要求系统安装 `jq`
- **切换后需重启**：用户需运行 `/reset` 使新配置生效
- **作用域优先级**：项目级配置通过 Claude Code 内置 settings 层级覆盖全局配置
