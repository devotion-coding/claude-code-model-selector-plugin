# 手动安装指南

适用于 Claude Code CLI 自然语言安装不可用的情况。

## 系统要求

- [Claude Code CLI](https://claude.ai/code)
- [jq](https://stedolan.github.io/jq/) >= 1.6
- macOS 或 Linux（Windows 用户请使用 WSL）

## 安装步骤

### 1. 将 skill 复制到本地 skills 目录

```bash
# 克隆仓库
git clone https://github.com/devotion-coding/claude-code-model-selector-plugin.git ~/claude-code-model-selector-plugin

# 安装 skill
mkdir -p ~/.claude/skills
cp -r ~/claude-code-model-selector-plugin/skills/model-switch ~/.claude/skills/
```

开发模式下推荐使用 symlink（编辑仓库文件后 skill 自动生效）：

```bash
mkdir -p ~/.claude/skills
ln -s ~/claude-code-model-selector-plugin/skills/model-switch ~/.claude/skills/model-switch
```

### 2. 验证 jq 已安装

```bash
jq --version  # 应输出 jq-1.6 或更高版本
```

### 3. 验证 skill 已安装

```bash
ls ~/.claude/skills/model-switch/SKILL.md
```

文件存在即表示安装成功。

### 4. 创建提供商注册表

参见主文档中的 [配置说明](README.zh-CN.md#配置)。
