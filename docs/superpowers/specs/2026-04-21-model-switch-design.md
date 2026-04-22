# Model Switch Plugin — Design Spec

## Problem
Users of Claude Code with third-party providers need to quickly switch between providers and models without manually editing configuration files.

## Configuration Architecture

| File | Purpose |
|------|---------|
| `~/.claude/model-profiles.json` | Registry of all providers and models (base_url, auth_token, model list) |
| `~/.claude/settings.json` | Global settings — `env` field controls active provider/model |
| `project/.claude/settings.local.json` | Project-level override — `env` field takes precedence over global |

## User Flow

1. User types `/model_switch`
2. Skill loads, reads `~/.claude/model-profiles.json`
3. Displays list of providers for user to select
4. Displays models under selected provider
5. Asks for scope: project-level (default) or global
6. Writes the selected provider's `base_url`, `auth_token`, and selected `model` to the target settings file's `env` field
7. Informs user to run `/reset` for changes to take effect

## Plugin Structure

```
skills/
└── model-switch/
    ├── SKILL.md          # Skill definition with interaction instructions
    └── scripts/
        └── switch-model.sh  # Core script: reads profiles, writes settings
```

## Script Contract

`switch-model.sh` accepts: `<provider_name> <model_name> <scope> [project_path]`
- scope: `project` or `global`
- Looks up provider config from `~/.claude/model-profiles.json`
- Writes `env` block to target settings file (preserving other fields)

## Scope Resolution

- **Project-level (default)**: writes to `$CWD/.claude/settings.local.json`
- **Global**: writes to `~/.claude/settings.json`

## Constraints

- Changes require `/reset` to take effect (Claude Code reads env at session start)
- Must preserve existing non-env fields in settings files
- Must validate provider/model exist in profiles before writing
