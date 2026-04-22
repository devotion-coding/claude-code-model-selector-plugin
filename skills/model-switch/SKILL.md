---
name: model-switch
description: Use when the user wants to switch AI provider or model. Supports multiple providers, each with multiple models. Switch scope: project-level (default) or global. Changes require /reset to take effect.
---

# Model Switch

Switch between AI providers and models in Claude Code CLI.

## Configuration

- **Provider registry**: `~/.claude/model-profiles.json` — all providers, base_urls, auth_tokens, and models
- **Global settings**: `~/.claude/settings.json` — `env` field controls active provider/model
- **Project settings**: `<project>/.claude/settings.local.json` — `env` field overrides global

## Usage

The user invokes this skill by typing `/model_switch`.

## Flow

1. Read `~/.claude/model-profiles.json` to get the list of providers and their models.
2. Present the provider list to the user as a numbered choice. Wait for selection.
3. Present the model list under the selected provider. Wait for selection.
4. Ask for scope: **project-level** (default, writes to current working directory's `.claude/settings.local.json`) or **global** (writes to `~/.claude/settings.json`).
5. Execute the switch script:
   ```
   bash <skill-directory>/scripts/switch-model.sh <provider_name> <model_name> <scope> <project_path>
   ```
6. Show the script output to the user.
7. Inform the user: "切换完成。运行 `/reset` 使新配置生效。"

## Script Contract

`scripts/switch-model.sh` accepts four arguments:
- `$1` provider name (exact match from profiles)
- `$2` model name (exact match from provider's models array)
- `$3` scope: `project` or `global`
- `$4` project path (absolute path to current working directory)

The script:
- Reads provider config from `~/.claude/model-profiles.json`
- Writes `env` block (`ANTHROPIC_MODEL`, `ANTHROPIC_BASE_URL`, `ANTHROPIC_AUTH_TOKEN`) to the target settings file
- Preserves all other fields in the settings file
- Returns error if provider/model not found

## Error Handling

- If `model-profiles.json` doesn't exist: tell the user to create it first
- If the selected provider has no models: show an error
- If the script fails: show the error output and suggest checking the profiles file
