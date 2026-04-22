# Model Switch Plugin — Design Spec

## Problem

Users of Claude Code with third-party providers need to quickly switch between providers and models without manually editing configuration files.

## Configuration Architecture

| File | Purpose |
|------|---------|
| `~/.claude/model-profiles.json` | Registry of all providers and models (base_url, auth_token, model list) |
| `~/.claude/settings.json` | Global settings — `env` field controls active provider/model |
| `project/.claude/settings.local.json` | Project-level override — `env` field takes precedence over global |

## Security Architecture

**红线**: 禁止在 skill 流程中直接读取 `model-profiles.json`。该文件含 `auth_token` 和 `base_url`，读取会将敏感信息暴露到对话上下文。

所有数据获取必须通过脚本代理：
- `list-providers.sh` — 仅返回脱敏的提供商名称和模型数量/列表
- `switch-model.sh` — 内部读取密钥并写入 settings，密钥不出现在输出中

## User Flow

1. User types `/model_switch`
2. Skill runs `list-providers.sh --list` to get sanitized provider list (no secrets)
3. User selects provider via AskUserQuestion
4. Skill runs `list-providers.sh --models <provider>` to get model list
5. Models displayed as numbered list; user inputs name or number (skill maps number → name)
6. Skill runs `show-scope-status.sh` to display current state and recommend scope
7. User selects scope: project-level (default) or global
8. Skill calls `switch-model.sh <provider> <model> <scope> <project_path>`
9. Script reads provider config internally, writes `env` block to target settings file
10. Informs user to restart Claude Code for changes to take effect

## Plugin Structure

```
skills/
└── model-switch/
    ├── SKILL.md          # Skill definition with interaction instructions
    └── scripts/
        ├── switch-model.sh       # Core script: reads profiles, writes settings
        ├── list-providers.sh     # Safe listing: returns names/counts only
        └── show-scope-status.sh  # Displays current provider/model per scope
```

## Script Contract

### `switch-model.sh`
Accepts: `<provider_name> <model_name> <scope:project|global> [project_path]`
- Looks up provider config from `~/.claude/model-profiles.json` internally
- Writes `env` block to target settings file (preserving other fields)
- Sets file permissions to `600` after writing
- Validates provider/model exist before writing
- Warns if project settings file is tracked by git

### `list-providers.sh`
- `--list` — outputs `provider_name<TAB>model_count` per line
- `--models <provider_name>` — outputs one model name per line
- **Never** outputs `base_url`, `auth_token`, or any secrets

### `show-scope-status.sh`
Accepts: `<project_path>`
- Reads project and global settings files
- Resolves provider name from `ANTHROPIC_BASE_URL` by matching against profiles
- Outputs human-readable status: `provider / model` per scope level

## Scope Resolution

- **Project-level (default)**: writes to `$CWD/.claude/settings.local.json`
- **Global**: writes to `~/.claude/settings.json`
- Project-level `env` overrides global via Claude Code settings layering

## Constraints

- Changes require restarting Claude Code to take effect (Claude Code reads env at session start)
- Must preserve existing non-env fields in settings files
- Must validate provider/model exist in profiles before writing
- File permissions: settings files created with `chmod 600`
