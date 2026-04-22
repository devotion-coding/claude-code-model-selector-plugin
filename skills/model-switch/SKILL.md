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
2. **Select provider:** Use `AskUserQuestion` with a single-select question. Each option's label is the provider name, description shows the model count. The user navigates with keyboard arrow keys and presses Enter to confirm.
3. **Select model:** Print the full list of models under the selected provider as a numbered list (e.g., `1. qwen3.6-plus`). Do NOT use `AskUserQuestion` here — it caps at 4 options and would truncate the list. Ask the user to type the model name or number. Wait for input, then validate it matches exactly.
4. **Determine scope recommendation and show current state:**
   - Run `bash <skill-directory>/scripts/show-scope-status.sh <project_path>` to display current provider/model at each scope level.
   - Determine recommendation:
     - If `<project>/.claude/settings.local.json` exists and contains an `env` block → recommend **project-level** scope (project already has its own override).
     - Otherwise → default recommendation is **project-level** (new scope, recommended to avoid affecting other projects).
   - Use `AskUserQuestion` to ask for scope, with the recommendation as the first option (marked "(Recommended)"). Options:
     - `project` — writes to `<project>/.claude/settings.local.json`
     - `global` — writes to `~/.claude/settings.json`
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
- Reads provider config from `~/.claude/model-profiles.json` in a single `jq` call (base_url, auth_token, model validation)
- Writes `env` block (`ANTHROPIC_MODEL`, `ANTHROPIC_BASE_URL`, `ANTHROPIC_AUTH_TOKEN`) to the target settings file
- Preserves all other fields in the settings file
- Returns error if provider/model not found

`scripts/show-scope-status.sh` accepts one argument:
- `$1` project path (absolute path to current working directory)

The script:
- Reads current `env.ANTHROPIC_MODEL` from project and global settings files
- Prints a human-readable status summary to stdout

## Error Handling

- If `model-profiles.json` doesn't exist: tell the user to create it first
- If the selected provider has no models: show an error
- If the script fails: show the error output and suggest checking the profiles file
