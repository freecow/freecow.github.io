---
aliases: 
tags: 
date_modified: 
date: 2025-10-12
---

## GACCode

### 安装Node

```Bash
# 下载
https://nodejs.org/en/download/

node --version
npm --version
```

### 安装及升级GACCode Claude Code

```Bash
# 安装gaccode的版本
npm install -g https://gaccode.com/claudecode/install --registry=https://registry.npmmirror.com

# 查看版本
claude --version
```

### 环境变量

```Bash
export ANTHROPIC_BASE_URL=https://gaccode.com/claudecode
export ANTHROPIC_API_KEY=<Your-API-Key>
```



## AnyRouter中转站

### 安装Node

```bash
sudo xcode-select --install
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# 用brew安装
brew install node
node --version
npm --version
```

### 安装官方 Claude Code

```bash
npm install -g @anthropic-ai/claude-code
claude --version
```

### 获取Auth Token

中转站地址：https://anyrouter.top/login?expired=true

使用GitHub登录，获取令牌：API令牌▸增加令牌▸获得以sk-开头

- 名称随意
- 额度建议设为无限额度
- 其他保持默认设置即可

### 环境变量

```bash
export ANTHROPIC_AUTH_TOKEN=<Your-API-Key>
export ANTHROPIC_BASE_URL=https://anyrouter.top
```



## Kimi-K2对接

### 环境变量

```Bash
export ANTHROPIC_BASE_URL=https://api.moonshot.cn/anthropic/
export ANTHROPIC_API_KEY=<Your-API-Key>
```
