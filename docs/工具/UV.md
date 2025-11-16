---
aliases: 
tags: 
date_modified: 
date: 2025-10-12
---

# uv-macOS部署

本文档介绍如何在安装和使用 uv，uv是Astral发布的高性能Python工具，Rust编写，用途是安装python包，以及解析包版本之间的依赖，最大特点是速度快，类似Rust的cargo

开源地址，https://github.com/astral-sh/uv

## 安装uv

```Bash
curl -LsSf https://astral.sh/uv/install.sh | sh
```

## 升级uv

```Bash
uv self update
```

## 创建uv虚拟环境

```Bash
# 创建uv环境到指定的目录内
uv venv --python 3.11 ~/.local/share/uv/envs/[ENV_NAME]

# 激活虚拟环境
source ~/.local/share/uv/envs/[ENV_NAME]/bin/activate

# 安装依赖
uv pip install -r requirements.txt

# 同步依赖环境（强制环境一致，自动卸载多余包）
uv pip sync requirements.txt

# 验收虚拟环境
which python3 && python3 -c "import flask, apscheduler; print('虚拟环境配置成功！')"

# 退出虚拟环境
deactivate
```

## 迁移conda环境至uv

导出现有环境

```bash
~/miniconda3/envs/[ENV_NAME]/bin/pip list --format=freeze > requirements.txt
```

安装依赖包

```bash
# 注释掉~/.zshrc中的conda初始化代码
# 重新启动终端
# 避免uv环境指向conda自动激活的运行程序

# 设置国内源
export UV_DEFAULT_INDEX="https://pypi.tuna.tsinghua.edu.cn/simple"

# 激活uv环境
source ~/.local/share/uv/envs/[ENV_NAME]/bin/activate

# 安装依赖包
uv pip install -r requirements.txt
```

## 创建全局激活与关闭脚本

```bash
# 创建本地bin目录，确保bin目录在PATH中
mkdir -p ~/.local/bin


# 创建脚本，虚拟环境名称为sea
cat > ~/.local/bin/sea << 'EOF'
#!/bin/zsh

# Quick activate uv sea environment
if [ $# -gt 0 ]; then
    # Run command in the environment
    export UV_DEFAULT_INDEX="https://pypi.tuna.tsinghua.edu.cn/simple"
    source ~/.local/share/uv/envs/sea/bin/activate
    exec "$@"
fi

# This part only runs when sourced (not executed)
if [[ "${BASH_SOURCE[0]}" != "${0}" ]] || [[ "${(%):-%N}" != "${0}" ]]; then
    # Store original prompt for restoration
    export UV_ORIGINAL_PROMPT="$PROMPT"
    export UV_ORIGINAL_PS1="$PS1" 
    export UV_ENV_NAME="sea"
    export UV_DEFAULT_INDEX="https://pypi.tuna.tsinghua.edu.cn/simple"
    
    # Activate environment
    source ~/.local/share/uv/envs/sea/bin/activate
    
    # Modify prompt to show environment name
    if [[ -n "$ZSH_VERSION" ]]; then
        export PROMPT="(sea) $UV_ORIGINAL_PROMPT"
    fi
    export PS1="(sea) $UV_ORIGINAL_PS1"
    
    # Define deactivate function
    function deactivate() {
        # Restore original prompt
        if [[ -n "$ZSH_VERSION" ]]; then
            export PROMPT="$UV_ORIGINAL_PROMPT"
        fi
        export PS1="$UV_ORIGINAL_PS1"
        
        # Deactivate virtual environment if function exists
        if command -v deactivate > /dev/null 2>&1; then
            command deactivate 2>/dev/null || true
        fi
        
        # Clean up environment variables
        unset UV_ORIGINAL_PROMPT
        unset UV_ORIGINAL_PS1
        unset UV_ENV_NAME
        unset UV_DEFAULT_INDEX
        
        # Remove this function
        unset -f deactivate
        
        echo "🌊 Deactivated uv 'sea' environment"
    }
    
    echo "🌊 Activated uv 'sea' environment"
    echo "Python: $(which python)"
    echo "Type 'deactivate' to exit this environment"
fi
EOF
```

激活uv环境

```bash
# 使用脚本
source [ENV_NAME]

# 检查包安装情况
uv pip list
# 注意与pip list不一样，两者可能指向不同的site-packages 目录
```

关闭环境

```bash
deactivate
```

## 如何复制环境

```bash
# 导出包列表
uv pip freeze > requirements.txt

# 创建uv环境
uv venv --python 3.11 ~/.local/share/uv/envs/[ENV_NAME]

# 激活uv环境
source ~/.local/share/uv/envs/[ENV_NAME]/bin/activate

# 安装
uv pip install -r requirements.txt
```

## 如何更换uv环境的python版本

```bash
# uv无法删除虚拟环境中的版本，只能用新版本的python创建原环境
# 先停用原环境
deactivate

# 删除原环境
rm -rf ~/.local/share/uv/envs/llms

# 创建新环境
uv venv --python 3.11 ~/.local/share/uv/envs/llms
```

## uv-pip国内源

编辑~/.zshrc

```Bash
# 定义国内源
export UV_DEFAULT_INDEX="https://pypi.tuna.tsinghua.edu.cn/simple"

# 或者
export UV_DEFAULT_INDEX="https://mirrors.aliyun.com/pypi/simple/"

# 测试是否起作用
uv pip install -v requests
```

## uv-python国内源

编辑~/.zshrc

```Bash
# 定义国内源
export UV_PYTHON_INSTALL_MIRROR="https://gh-proxy.com/https://github.com/astral-sh/python-build-standalone/releases/download"

# 或者
export UV_PYTHON_INSTALL_MIRROR="https://ghfast.top/https://github.com/astral-sh/python-build-standalone/releases/download"

# 测试是否起作用
uv python install 3.12
```