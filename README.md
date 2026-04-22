# Claude Code Model Switcher

```
  __  ___  __ _  ___  __  ____  ____    ____  ____    ________    ___
 /  \/  \/  \ \/ / / / / / / / / / /   / / / / / /   / ____/ /   /   |
/ /_/ / / /| |\ \/ /_/ /_/ /_/ /_/ / / /_/ / /_/ /   / /   / /   / /| |
\__  / /_/ /_/_/\_\__,__,__,__,__/_/  /__, /__, /   / /___/ /___/ ___ |
/___/\____/(_)                        /____/____/    \____/_____/_/  |_|
```

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Shell Script](https://img.shields.io/badge/language-shell-4EAA25.svg?logo=gnu-bash&logoColor=white)](https://www.gnu.org/software/bash/)
[![jq](https://img.shields.io/badge/depends-jq-blue.svg)](https://stedolan.github.io/jq/)

> **Stop typing `ANTHROPIC_MODEL=foo ANTHROPIC_BASE_URL=bar` by hand.**
> A Claude Code skill. One slash command. Three prompts. Done.

[English](#) | [中文](README.zh-CN.md)

---

##TL;DR: Why This Exists

You know that feeling when you:

- Google "how to change Claude model" for the 47th time
- Edit `.env`, forget to commit, wonder why it's not working
- Have 3 different API keys for 3 different providers and can't remember which is which
- Realize you've been manually setting env vars like it's 1995

**Yeah, we built this so you never have to feel that pain again.**

`/model_switch` is the antidote to configuration spaghetti. One slash command, three prompts, you're on a different model. No `.env` dancing, no file hunting, no "wait which profile was I using?"

### What You Get

- **Multi-provider registry** — Bailian, OpenAI, Anthropic, whatever — all in one place
- **Multiple models per provider** — Because one model per provider is so 2023
- **Project or global scope** — Project-level by default (git-ignored, safe), global when you're lazy
- **Security-first** — Your auth tokens stay in config files, never leak into the chat. We literally cannot see them even if we wanted to.
- **One `/reset` to rule them all** — Changes take effect after restart. That's it.

---

## Demo (Watch Me Do Your Job)

```bash
$ /model_switch

  Select provider
  > bailian
    openai
    anthropic

  Select model
  > qwen3.6-plus
    qwen3.5-plus

  Select scope
  > Project (.claude/settings.local.json)
    Global (~/.claude/settings.json)

  ✅ Switched to bailian/qwen3.6-plus (project)
  Run /reset to apply changes
```

**That's it.** No restart, no re-auth, no prayer. You were manually editing files for THIS?

---

## Installation

### Prerequisites

- [Claude Code CLI](https://claude.ai/code) — obviously
- [jq](https://stedolan.github.io/jq/) >= 1.6 — the only dependency, we promise
- macOS or Linux (Windows users: WSL exists for a reason, don't be a hero)

### Install

This is a **Claude Code skill** — a `SKILL.md` + shell scripts combo that exposes `/model_switch`. Install it like any other local skill, not a plugin.

**The easiest way** — send this in your Claude Code conversation:

```
Install this skill https://github.com/devotion-coding/claude-code-model-selector-plugin
```

Claude Code will handle everything: download the repo, copy the skill to `~/.claude/skills/`, and make `/model_switch` available immediately.

For manual installation (git clone + copy), see [MANUAL_INSTALL.md](MANUAL_INSTALL.md).

---

## Quick Start

1. Type `/model_switch` in Claude Code
2. Pick your provider, model, and scope
3. Run `/reset`

**Go forth and switch with the power of a single slash command.**

---

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
    },
    {
      "name": "openai",
      "base_url": "https://api.openai.com/v1",
      "auth_token": "sk-your-openai-token",
      "models": ["gpt-4", "gpt-3.5-turbo"]
    }
  ]
}
```

That's it. `providers` array. No magic. No hidden fields. What you see is what you get.

### Scope Priority

| Scope | Target File | Priority |
|-------|-------------|----------|
| Project (default) | `<project>/.claude/settings.local.json` | Highest |
| Global | `~/.claude/settings.json` | Fallback |

Project-level `env` overrides global. CSS cascade — project wins. Don't overthink it.

---

## Security: Yes, We Have to Talk About This

> ⚠️ Your auth tokens are stored in plaintext. Treat these files like passwords. Because they basically are.

### What You Should Do

- **Project scope**: Add `.claude/settings.local.json` to `.gitignore`. Like, right now. I'll wait.
- **Global scope**: `chmod 600 ~/.claude/settings.json`. Your future self will send thank-you cards.

### .gitignore (Just Copy This)

```gitignore
# Claude Code local settings — contains auth tokens, DO NOT COMMIT
.claude/settings.local.json
```

### Permissions

```bash
chmod 600 ~/.claude/settings.json
chmod 600 .claude/settings.local.json
```

The scripts auto-set `600` on newly created files and will **warn you loudly** if project settings are tracked by git (which would be a security incident, not just a code smell).

---

## Troubleshooting

| Problem | Fix |
|---------|-----|
| `jq: command not found` | `brew install jq` (macOS) or `apt-get install jq` (Linux) |
| `profiles file not found` | Create `~/.claude/model-profiles.json` or run `init-profiles.sh` to bootstrap |
| `No existing profiles` | Run `bash skills/model-switch/scripts/init-profiles.sh` to initialize from current settings |
| Switch didn't take effect | Run `/reset` — Claude Code needs a restart to pick up new env vars |
| Warning about git-tracked file | Add `.claude/settings.local.json` to `.gitignore` immediately |

### Scripts Reference

| Script | What It Does |
|--------|-------------|
| `scripts/switch-model.sh` | Main event: reads profiles, writes settings |
| `scripts/list-providers.sh` | Lists providers/models (secrets never leave the building) |
| `scripts/show-scope-status.sh` | Shows current project + global config status |
| `scripts/init-profiles.sh` | Bootstraps model-profiles.json from existing settings (run once before first use) |

---

## Contributing

1. Fork the repo
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push (`git push origin feature/amazing-feature`)
5. Open a PR

### Dev Conventions

- Comments and variable names in English
- Commit messages in English
- Scripts must pass `shellcheck`

---

## License

[MIT](LICENSE) — do whatever you want with it. We're not your mom.

---

**Made with caffeine, shell scripts, and a deep hatred for manual configuration.**
