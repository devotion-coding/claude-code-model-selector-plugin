# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 项目概述

Claude Code 模型切换 skill，通过 `/model_switch` 斜杠命令在 AI 提供商和模型之间切换。支持多提供商（每个提供商含多个模型），作用于项目级或全局级别。

## 目录结构

```
├── skills/model-switch/
│   ├── SKILL.md              # Skill 定义（触发条件、流程、错误处理、安全红线）
│   └── scripts/
│       ├── switch-model.sh   # 核心脚本：读取 profiles，写入 settings 文件的 env 块
│       ├── list-providers.sh # 安全列出提供商/模型（不暴露密钥）
│       ├── show-scope-status.sh  # 显示当前项目/全局作用域的模型配置状态
│       └── init-profiles.sh  # 从现有 settings 初始化 model-profiles.json
├── docs/superpowers/specs/
│   └── 2026-04-21-model-switch-design.md  # 架构设计规格文档
├── README.md                 # 用户文档（英文）
├── README.zh-CN.md           # 用户文档（中文）
└── .gitignore                # 排除 settings.local.json 等敏感文件
```

## 安全红线

**禁止在 skill 流程中直接读取 `~/.claude/model-profiles.json`**。该文件包含 `auth_token` 和 `base_url`，读取会将敏感信息暴露到对话上下文中。所有数据获取必须通过脚本代理：

- `list-providers.sh` — 仅返回脱敏的提供商名称和模型列表
- `switch-model.sh` — 内部读取密钥并写入 settings，密钥不出现在输出中
- `show-scope-status.sh` — 内部匹配 base_url 解析 provider 名称，输出不含密钥

唯一例外：`init-profiles.sh` 需要从 settings 文件读取现有 env 配置来初始化 profiles，这是安全的，因为 settings 文件是 Claude Code 自身管理的配置。

## 关键文件与接口契约

### `skills/model-switch/SKILL.md`
Skill 定义文件，包含触发条件、执行流程（6 步交互式）、脚本契约、错误处理和安全注意事项。

### `skills/model-switch/scripts/switch-model.sh`
执行实际切换的 Shell 脚本：
- 接收 4 个参数：`provider_name`、`model_name`、`scope`（project|global）、`project_path`（可选）
- 通过 `jq` 从 `~/.claude/model-profiles.json` 读取提供商配置
- 将 `env` 块（`ANTHROPIC_MODEL`、`ANTHROPIC_BASE_URL`、`ANTHROPIC_AUTH_TOKEN`）写入目标 settings 文件
- 保留目标文件中的其他字段不变
- 自动设置文件权限为 `600`
- 若项目 settings 被 git 追踪则发出警告
- 若 profiles 文件不存在则自动调用 `init-profiles.sh` 初始化

### `skills/model-switch/scripts/list-providers.sh`
安全获取非敏感数据：
- `--list` — 输出所有提供商名称和模型数量，格式 `name<TAB>count`
- `--models <provider_name>` — 输出指定提供商的所有模型名称，每行一个
- 绝不输出 `base_url`、`auth_token` 或任何其他密钥

### `skills/model-switch/scripts/show-scope-status.sh`
显示当前作用域状态：
- 接收 1 个参数：`project_path`
- 读取项目级和全局级 settings 文件的 `env.ANTHROPIC_MODEL` 和 `env.ANTHROPIC_BASE_URL`
- 通过 `base_url` 匹配 `model-profiles.json` 解析 provider 名称
- 输出人类可读的状态摘要，格式 `provider / model`

### `skills/model-switch/scripts/init-profiles.sh`
从现有 settings 初始化 profiles：
- 从全局和项目 settings 文件中提取 `env` 配置
- 根据 `base_url` 的 hostname 推导 provider 名称
- 合并同一 provider 下的多个模型（去重）
- 创建 `~/.claude/model-profiles.json`，仅包含 `providers` 数组
- 若 profiles 文件已存在或 settings 中无任何配置，则报错退出

### Provider 注册表（`~/.claude/model-profiles.json`）
外部 JSON 文件（不在本仓库中），存储所有提供商配置。示例：
```json
{
  "providers": [{ "name": "bailian", "base_url": "...", "auth_token": "...", "models": ["qwen3.6-plus"] }]
}
```

### Settings 文件层级
| 作用域 | 目标文件 | 优先级 |
|--------|----------|--------|
| 项目级 | `<project>/.claude/settings.local.json` | 最高 |
| 全局级 | `~/.claude/settings.json` | 兜底 |

## 开发命令

本项目无需编译/测试命令，纯 Shell 脚本 + Markdown 组成的配置型插件项目。

### 常用命令

```bash
# 验证脚本语法
shellcheck skills/model-switch/scripts/*.sh

# 手动测试切换流程
# 1. 修改 SKILL.md 或 switch-model.sh
# 2. 在 Claude Code CLI 中执行 /model_switch
# 3. 验证目标 settings 文件写入了正确的 env 块

# 列出当前注册的提供商
bash skills/model-switch/scripts/list-providers.sh --list

# 查看某个提供商的模型
bash skills/model-switch/scripts/list-providers.sh --models bailian

# 查看当前作用域状态
bash skills/model-switch/scripts/show-scope-status.sh .
```

## 开发约定

- 代码注释和变量名使用英文
- Git 提交信息使用英文
- 脚本应通过 `shellcheck` 检查
- Shell 脚本统一使用 `set -euo pipefail`

## 架构说明

- **无编译代码**：插件纯由声明式文件（SKILL.md）+ Shell 脚本组成
- **依赖 `jq`**：所有脚本要求系统安装 `jq` >= 1.6
- **切换后需重启**：用户需重启 Claude Code 客户端使新配置生效（可使用 `/resume` 恢复会话）
- **作用域优先级**：项目级配置通过 Claude Code 内置 settings 层级覆盖全局配置
- **自动初始化**：profiles 文件缺失时脚本自动从 settings 初始化，首次使用无需手动创建
- **安全设计**：密钥始终在脚本内部处理，skill 流程只通过 `list-providers.sh` 获取脱敏数据
