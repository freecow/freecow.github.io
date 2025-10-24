---
aliases: 
tags: 
date_modified: 
date: 2025-10-22
---

## macOS环境

安装podman

```bash
brew install podman
```

### 进入虚机
```bash
podman machine ssh
```

### 新增镜像配置
```bash
sudo mkdir -p /etc/containers/registries.conf.d

sudo tee /etc/containers/registries.conf.d/01-mirrors.conf >/dev/null <<'EOF'
unqualified-search-registries = ["docker.io"]

[[registry]]
prefix = "docker.io"
location = "registry-1.docker.io"

[[registry.mirror]]
location = "docker.m.daocloud.io"
EOF
```

### 退出后重启虚拟机以生效
```bash
exit
podman machine stop
podman machine start
```

### 宿主机拉取验证
```bash
# podman与docker的镜像一致
podman pull node:18-alpine
```





## Linux环境

### 新增镜像配置

```bash
sudo tee /etc/containers/registries.conf.d/01-mirrors.conf >/dev/null <<'EOF'
unqualified-search-registries = ["docker.io"]

[[registry]]
prefix = "docker.io"
location = "registry-1.docker.io"

[[registry.mirror]]
location = "docker.m.daocloud.io"
EOF
```

### 拉取验证

```bash
podman pull node:18-alpine
```
