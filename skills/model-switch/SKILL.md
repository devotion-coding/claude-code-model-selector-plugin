---
name: model-switch
description: 当用户想要切换 AI 提供商或模型时使用。支持多个提供商，每个提供商有多个模型。切换作用域：项目级（默认）或全局。修改后需要 /reset 生效。
---

# 模型切换

在 Claude Code CLI 中切换 AI 提供商和模型。

## 配置

- **脚本目录**: `scripts/`（相对于 SKILL.md 所在目录，执行时展开完整路径）
- **提供商注册表**: `~/.claude/model-profiles.json` — 包含所有提供商的 base_url、auth_token 和模型列表（**禁止直接读取此文件**）
- **全局设置**: `~/.claude/settings.json` — `env` 字段控制当前提供商/模型
- **项目设置**: `<project>/.claude/settings.local.json` — `env` 字段覆盖全局配置

## 安全红线

**任何时候都不得直接读取 `~/.claude/model-profiles.json`。** 该文件包含 `auth_token` 和 `base_url`，读取会将敏感信息暴露到对话上下文中。所有数据获取必须通过 `scripts/list-providers.sh` 脚本进行，该脚本仅返回提供商名称和模型列表，不包含任何密钥。

**例外**: `scripts/show-scope-status.sh` 内部会读取 `model-profiles.json` 的 `name` 字段用于解析 provider 名称，但该脚本输出仅包含脱敏的 provider 名称和模型名，**不会输出 `base_url` 或 `auth_token`**。此例外是安全的。

## 使用方式

用户通过输入 `/model_switch` 来调用此 skill。

## 执行流程

以下步骤中所有脚本路径使用 `SCRIPT_DIR`，值为 SKILL.md 所在目录下的 `scripts/` 子目录。实际执行时需根据 SKILL.md 的实际安装位置展开为完整路径。

1. **获取提供商列表（安全方式）:** 运行 `bash "${SCRIPT_DIR}list-providers.sh --list"`，输出格式为 `提供商名称<TAB>模型数量`。
2. **选择提供商:** 运行 `bash "${SCRIPT_DIR}list-providers.sh --list"` 获取提供商列表。将提供商以编号列表形式直接打印给用户（例如 `1. bailian (3 models)\n2. anthropic (5 models)`）。**不使用 AskUserQuestion 工具**，而是让用户通过普通文本输入选择。等待用户输入后按以下规则处理：
   - 如果输入是纯数字，映射为编号列表中对应位置的提供商名称（例如输入 `1` → `bailian`）
   - 如果输入是字符串，与提供商名称精确匹配
   - 匹配失败则报错提示用户重新输入
3. **选择模型:** 运行 `bash "${SCRIPT_DIR}list-providers.sh --models <provider_name>"` 获取模型列表。将模型以编号列表形式直接打印给用户（例如 `1. qwen3.6-plus\n2. qwen4-plus`）。**不使用 AskUserQuestion 工具**，而是让用户通过普通文本输入选择。等待用户输入后按以下规则处理：
   - 如果输入是纯数字，映射为编号列表中对应位置的模型名（例如输入 `1` → `qwen3.6-plus`）
   - 如果输入是字符串，与模型名精确匹配
   - 匹配失败则报错提示用户重新输入
   - **映射必须在 skill 逻辑中完成**，传给 `switch-model.sh` 的参数始终是模型名称，不是编号
4. **确定作用域推荐并显示当前状态:**
   - 运行 `bash "${SCRIPT_DIR}show-scope-status.sh <project_path>"` 显示各作用域级别的当前提供商/模型。
   - 根据当前状态确定推荐:
     - 如果项目级设置存在且有 `env` 块 → 推荐 **项目级**（已有覆盖配置）
     - 如果全局级有 `env` 但项目级没有 → 推荐 **项目级**（与全局隔离）
     - 如果用户明确想修改全局配置 → 可以选择全局
   - 使用 `AskUserQuestion` 询问作用域，将推荐作为第一个选项（标记为 "(推荐)"）。选项:
     - `project` — 写入 `<project>/.claude/settings.local.json`
     - `global` — 写入 `~/.claude/settings.json`
5. **执行切换（脚本内部处理所有密钥）:**
   ```
   bash "${SCRIPT_DIR}switch-model.sh <provider_name> <model_name> <scope> [project_path]"
   ```
   脚本内部从 `model-profiles.json` 读取 `base_url` 和 `auth_token`，写入目标 settings 文件。**整个过程中密钥不会出现在任何输出中。** `project_path` 仅在 scope 为 `project` 时需要，可省略（默认当前工作目录）。
6. 将脚本输出展示给用户（仅包含脱敏信息：提供商名称、模型名称、写入路径）。
7. 告知用户: "切换完成。运行 `/reset` 使新配置生效。"

## 脚本契约

`scripts/switch-model.sh` 接受四个参数:
- `$1` 提供商名称（与注册表中精确匹配）
- `$2` 模型名称（与提供商模型数组中精确匹配）
- `$3` 作用域: `project` 或 `global`
- `$4` 项目路径（当前工作目录的绝对路径，**可选**，默认当前工作目录；scope 为 `global` 时可忽略）

脚本功能:
- 内部读取 `model-profiles.json` 获取 `base_url`、`auth_token`（**不对外暴露**）
- 将 `env` 块写入目标 settings 文件
- 保留 settings 文件中的其他字段
- 提供商/模型不存在时返回错误
- 输出仅包含: 提供商/模型名称、写入路径、`/reset` 提示

`scripts/list-providers.sh` 用于安全获取非敏感数据:
- `--list` — 输出所有提供商名称和模型数量，格式 `name<TAB>count`
- `--models <provider_name>` — 输出指定提供商的所有模型名称，每行一个
- **绝不输出 `base_url`、`auth_token` 或任何其他密钥**

`scripts/show-scope-status.sh` 接受一个参数:
- `$1` 项目路径（当前工作目录的绝对路径）

脚本功能:
- 从项目和全局 settings 文件读取当前 `env.ANTHROPIC_MODEL` 和 `env.ANTHROPIC_BASE_URL`
- 通过 `base_url` 匹配 `model-profiles.json` 解析 provider 名称
- 打印人类可读的状态摘要，格式 `provider / model`（如未设置则显示提示文本）

`scripts/init-profiles.sh` 接受一个可选参数:
- `$1` 项目路径（当前工作目录的绝对路径，默认当前工作目录）

脚本功能:
- 从全局和项目 settings 文件中提取 `env` 配置（`ANTHROPIC_BASE_URL`、`ANTHROPIC_MODEL`、`ANTHROPIC_AUTH_TOKEN`）
- 根据 `base_url` 的 hostname 推导 provider 名称
- 合并同一 provider 下的多个模型（去重）
- 创建 `~/.claude/model-profiles.json`，仅包含 `providers` 数组
- 如果 profiles 文件已存在或 settings 中无任何配置，则报错退出

## 错误处理

- 如果 `model-profiles.json` 不存在: 脚本自动调用 `init-profiles.sh` 从当前 settings 文件初始化。初始化会从全局和项目 settings 中提取 `env` 配置（`ANTHROPIC_BASE_URL`、`ANTHROPIC_MODEL`、`ANTHROPIC_AUTH_TOKEN`），推导 provider 名称并创建 profiles 文件。如果 settings 中也无配置，则报错提示用户手动创建
- 如果选中的提供商没有模型: 显示错误
- 如果脚本失败: 显示错误输出并建议检查注册表文件

## 安全注意事项

- **项目作用域**: 切换前提醒用户将 `.claude/settings.local.json` 添加到 `.gitignore`（如尚未添加）
- **Auth Token 泄露**: 如果目标文件被 git 追踪，脚本会发出警告
- **Key 不暴露**: `base_url`、`auth_token` 和模型 key 全部由脚本内部处理，不进入对话上下文。Skill 流程只通过 `list-providers.sh` 获取脱敏的提供商名称和模型列表
