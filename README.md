# claude-cdoe-model-seletor-plugin

Claude Code model selector plugin. Switch between AI providers and models via `/model_switch` slash command.

## Features

- Multiple providers, each with multiple models
- Provider registry in `~/.claude/model-profiles.json`
- Switch scope: project-level (default) or global
- Changes written to `settings.local.json` (project) or `settings.json` (global)
- Run `/reset` after switching for changes to take effect

## Usage

1. Install this plugin into your Claude Code plugins directory
2. Type `/model_switch` in Claude Code CLI
3. Select a provider → select a model → choose scope → done

## Configuration

### Provider Registry

Create `~/.claude/model-profiles.json`:

```json
{
  "providers": [
    {
      "name": "bailian",
      "base_url": "https://coding.dashscope.aliyuncs.com/apps/anthropic",
      "auth_token": "sk-your-token",
      "models": ["qwen3.6-plus", "qwen3.5-plus"]
    }
  ],
  "active_provider": "bailian",
  "active_model": "qwen3.6-plus"
}
```

### Scope Resolution

| Scope | Target File | Priority |
|-------|-------------|----------|
| Project (default) | `<project>/.claude/settings.local.json` | Highest |
| Global | `~/.claude/settings.json` | Fallback |
