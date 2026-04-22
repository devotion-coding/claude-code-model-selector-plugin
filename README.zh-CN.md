# Claude Code 模型切换器

```
  ╔══════════════════════════════════════════════════════════╗
  ║   一行命令，三步选择，自由切换你的 AI 提供商和模型      ║
  ║   告别手动改 .env 的日子                                 ║
  ╚══════════════════════════════════════════════════════════╝
```

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Shell Script](https://img.shields.io/badge/language-shell-4EAA25.svg?logo=gnu-bash&logoColor=white)](https://www.gnu.org/software/bash/)
[![jq](https://img.shields.io/badge/depends-jq-blue.svg)](https://stedolan.github.io/jq/)

> **别再用 `ANTHROPIC_MODEL=xxx ANTHROPIC_BASE_URL=yyy` 手动切了。**
> 一个斜杠命令，三次选择，搞定收工。

[English](README.md) | [中文](#)

---

##TL;DR: 为什么要这个

你是不是每次都：

- 百度 "怎么改 Claude 模型" 第 N+1 次
- 改完 `.env` 忘记提交，怀疑人生
- 手里 3 个 API key 不知道该用哪个
- 意识到自己手动设环境变量的样子像在修电脑

**巧了，我们也是。所以做了这个。**

`/model_switch` 就是配置地狱的解药。一个斜杠命令，三次选择，直接切到另一个模型。不用 `.env` 蹦迪，不用翻文件，不用"我到底用的是哪个 profile"。

### 能干嘛

- **多提供商注册表** — Bailian、OpenAI、Anthropic，来一套
- **每个提供商多个模型** — 一个模型哪够啊，成年人全都要
- **项目级 or 全局作用域** — 项目级默认（git 忽略，安全），全局级摸鱼
- **安全第一** — Auth token 待在配置文件里不出来，我们想看都看不到
- **一个 `/reset` 搞定** — 重启完事就这么简单

---

## 演示一下

```bash
$ /model_switch

  选择提供商
  > bailian
    openai
    anthropic

  选择模型
  > qwen3.6-plus
    qwen3.5-plus

  选择作用域
  > 项目级 (.claude/settings.local.json)
    全局级 (~/.claude/settings.json)

  ✅ 已切换到 bailian/qwen3.6-plus (项目级)
  运行 /reset 使新配置生效
```

**就这？** 你以前手动改文件就是为了这？

---

## 安装

### 系统要求

- [Claude Code CLI](https://claude.ai/code) — ，不然呢
- [jq](https://stedolan.github.io/jq/) >= 1.6 — 唯一的依赖，就一个
- macOS 或 Linux（Windows 用户：WSL 是摆设吗，别头铁）

### 安装步骤

1. **安装插件：**

   ```bash
   # 方式一：symlink（开发调试用）
   ln -s /path/to/this/repo ~/.claude/plugins/claude-code-model-selector-plugin

   # 方式二：直接克隆
   git clone https://github.com/yourusername/claude-code-model-selector-plugin.git ~/.claude/plugins/claude-code-model-selector-plugin
   ```

2. **验证 jq：**

   ```bash
   jq --version  # 应该输出 jq-1.6 或更高
   ```

3. **创建提供商注册表** — 看下面的[配置说明](#配置)。

---

## 快速开始

1. 在 Claude Code 里敲 `/model_switch`
2. 选提供商、选模型、选作用域
3. 跑 `/reset`

**完事。去卷。**

---

## 配置

### 提供商注册表

创建 `~/.claude/model-profiles.json`：

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

就这些。`providers` 数组。没有魔法。没有隐藏字段。所見即所得。

### 作用域优先级

| 作用域 | 目标文件 | 优先级 |
|--------|----------|--------|
| 项目级（默认） | `<project>/.claude/settings.local.json` | 最高 |
| 全局 | `~/.claude/settings.json` | 兜底 |

项目级覆盖全局。CSS 层叠规则 — 项目级赢。别想复杂了。

---

## 安全：真的得说

> ⚠️ 你的 auth token 是明文存的。把这些文件当密码对待。因为它们本质上就是。

### 你应该做的

- **项目级作用域**：把 `.claude/settings.local.json` 加到 `.gitignore`。现在就加，我等你。
- **全局作用域**：`chmod 600 ~/.claude/settings.json`。你未来的自己会寄感谢卡。

### .gitignore（复制粘贴）

```gitignore
# Claude Code 本地配置——包含 auth token，别提交！
.claude/settings.local.json
```

### 权限设置

```bash
chmod 600 ~/.claude/settings.json
chmod 600 .claude/settings.local.json
```

脚本创建新文件会自动设 `600`，而且会**疯狂警告你**如果项目 settings 被 git 追踪了（那是安全事故，不只是代码味道问题）。

---

## 故障排除

| 问题 | 解决方法 |
|------|----------|
| `jq: command not found` | `brew install jq` (macOS) 或 `apt-get install jq` (Linux) |
| `profiles file not found` | 创建 `~/.claude/model-profiles.json` 或运行 `init-profiles.sh` 初始化 |
| 没有现有 profiles | 运行 `bash skills/model-switch/scripts/init-profiles.sh` 从当前 settings 初始化 |
| 切换后没生效 | 跑一下 `/reset`，Claude Code 需要重启才能读取新的环境变量 |
| 提示文件被 git 追踪 | 立刻把 `.claude/settings.local.json` 加到 `.gitignore` |

### 脚本说明

| 脚本 | 用途 |
|------|------|
| `scripts/switch-model.sh` | 主角：读取 profiles，写入 settings 文件 |
| `scripts/list-providers.sh` | 安全列出提供商和模型（密钥不出门） |
| `scripts/show-scope-status.sh` | 显示项目级和全局级配置状态 |
| `scripts/init-profiles.sh` | 从现有 settings 初始化 model-profiles.json（首次使用前运行） |

---

## 贡献

1. Fork 本仓库
2. 创建功能分支 (`git checkout -b feature/amazing-feature`)
3. 提交更改 (`git commit -m 'Add amazing feature'`)
4. 推送 (`git push origin feature/amazing-feature`)
5. 提交 Pull Request

### 开发规范

- 代码注释和变量名用英文
- 提交信息用英文
- 脚本要通过 `shellcheck` 检查

---

## License

[MIT](LICENSE) — 拿去做你想做的事。我不是你妈。

---

**用咖啡因、shell 脚本和对手动配置深深的厌恶做成。**
