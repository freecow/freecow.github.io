---
aliases: 
tags: 
date_modified: 
date: 2025-10-24
---

# Podman 容器化部署指南 (Ubuntu)

本文档介绍如何在 Ubuntu 服务器上使用 Podman 和 podman-compose 部署完整的应用栈（PostgreSQL + 后端 + 前端）。

## 架构概览

```
┌─────────────────────────────────────────────────────────┐
│                      Podman Host                        │
│                                                          │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐  │
│  │   Frontend   │  │   Backend    │  │  PostgreSQL  │  │
│  │   (Nginx)    │  │   (Flask)    │  │              │  │
│  │   Port 3000  │  │   Port 15001 │  │   Port 5432  │  │
│  └──────────────┘  └──────────────┘  └──────────────┘  │
│         │                  │                  │         │
│    podman network     host network       host network   │
└─────────────────────────────────────────────────────────┘
```

## 网络模式说明

本部署方案采用混合网络模式以解决 Podman CNI firewall 插件在 Ubuntu 上的兼容性问题：

- **PostgreSQL**: 使用 `host` 网络，直接监听在宿主机 `localhost:5432`
- **Backend**: 使用 `host` 网络，直接监听在宿主机 `localhost:15001`
- **Frontend**: 使用 `podman` 桥接网络，通过端口映射暴露 `3000:80`

## 部署步骤

### 1. 安装 Podman

在 Ubuntu 20.04+ 上安装 Podman：

```bash
# 更新软件包列表
sudo apt update

# 安装 Podman
sudo apt install -y podman

# 验证安装
podman --version
# 输出示例: podman version 3.4.4
```

### 2. 安装 podman-compose

podman-compose 是 docker-compose 的 Podman 兼容实现：

```bash
# 安装 Python3 和 pip（如果未安装）
sudo apt install -y python3-pip

# 安装 podman-compose
pip3 install podman-compose

# 验证安装
podman-compose --version
# 输出示例: podman-compose version 1.0.3
```

### 3. 配置 Podman CNI 网络

由于 Podman 3.4.4 在 Ubuntu 上存在 firewall 插件兼容性问题（不支持 CNI 1.0.0），需要创建一个不包含 firewall 插件的网络配置。

创建网络配置文件：

```bash
# 创建 CNI 配置目录（如果不存在）
sudo mkdir -p /etc/cni/net.d

# 创建 podman 网络配置文件
sudo tee /etc/cni/net.d/87-podman-bridge.conflist > /dev/null <<'EOF'
{
  "cniVersion": "0.3.1",
  "name": "podman",
  "plugins": [
    {
      "type": "bridge",
      "bridge": "cni0",
      "isGateway": true,
      "ipMasq": true,
      "ipam": {
        "type": "host-local",
        "subnet": "10.88.0.0/16",
        "routes": [
          {
            "dst": "0.0.0.0/0"
          }
        ]
      }
    },
    {
      "type": "portmap",
      "capabilities": {
        "portMappings": true
      }
    }
  ]
}
EOF

# 验证网络配置
podman network ls
# 应该看到: podman  0.3.1  bridge,portmap
```

配置说明：
- `cniVersion`: 使用 0.3.1 版本（而非 1.0.0）以兼容旧版 firewall 插件限制
- `plugins`: 仅包含 `bridge` 和 `portmap` 插件，移除了有问题的 `firewall` 插件
- `subnet`: 使用 `10.88.0.0/16` 地址池

### 4. 上传项目文件

```bash
# 在本地打包项目（排除不必要的文件）
tar -czf sea-sync-deploy.tar.gz \
  --exclude='node_modules' \
  --exclude='.git' \
  --exclude='*.pyc' \
  --exclude='__pycache__' \
  --exclude='configs/config.db*' \
  --exclude='logs/*' \
  .

# 上传到服务器
scp sea-sync-deploy.tar.gz user@server:/opt/

# SSH 到服务器并解压
ssh user@server
cd /opt/
tar -xzf sea-sync-deploy.tar.gz
mv mysql-sea-syncweb /opt/mysql-sea-syncweb
cd /opt/mysql-sea-syncweb
```

### 5. 配置环境变量

创建 `.env` 文件（从模板复制）：

```bash
cp .env.example .env
```

编辑 `.env` 文件，设置敏感信息：

```bash
# PostgreSQL 数据库配置
POSTGRES_HOST=localhost
POSTGRES_PORT=5432
POSTGRES_DB=sea_sync
POSTGRES_USER=postgres
POSTGRES_PASSWORD=your_strong_password_here  # 修改为强密码

# 应用配置
APP_PORT=15001
FLASK_ENV=production

# SeaTable 服务器
SEATABLE_SERVER_URL=https://cloud.seatable.cn
```

### 6. 拉取容器镜像

在启动服务前，先拉取所需的镜像：

```bash
# 拉取 PostgreSQL 镜像
podman pull postgres:14-alpine

# 拉取后端镜像
podman pull uhub.service.ucloud.cn/igalaxycn/mysql-sea-syncweb-backend:amd64-20251024

# 拉取前端镜像
podman pull uhub.service.ucloud.cn/igalaxycn/mysql-sea-syncweb-frontend:amd64-20251024

# 验证镜像
podman images
```

为什么要先拉取：
- 避免 podman-compose up 时下载超时导致启动失败
- 可以看到下载进度，确保镜像完整
- 检查网络连接和镜像源是否可用

### 7. 启动服务

方式一：分步启动（推荐用于首次部署）

```bash
# 1. 先单独启动数据库
podman-compose up -d postgres

# 2. 等待数据库完全启动并初始化（约 10-15 秒）
podman-compose logs -f postgres
# 看到以下信息后按 Ctrl+C:
#   - "database system is ready to accept connections"
#   - "PostgreSQL init process complete; ready for start up"

# 3. 验证数据库已就绪
podman exec sea-sync-postgres pg_isready -U postgres
# 应该输出: /var/run/postgresql:5432 - accepting connections

# 4. 检查表是否创建成功
podman exec sea-sync-postgres psql -U postgres sea_sync -c "\dt"
# 应该看到 10 个表：devices, sync_tasks, schedules 等

# 5. 启动后端
podman-compose up -d backend

# 6. 检查后端日志（确认已连接数据库）
podman-compose logs -f backend
# 看到 "PostgreSQL 连接池已创建: localhost:5432/sea_sync" 后按 Ctrl+C

# 7. 启动前端
podman-compose up -d frontend

# 8. 检查所有服务状态
podman-compose ps
```

方式二：一键启动（适用于已验证过的环境）

```bash
podman-compose up -d
```

### 8. 验证部署

```bash
# 检查所有容器状态
podman ps -a

# 应该看到 3 个容器都是 Up 状态
# CONTAINER ID  IMAGE                                    COMMAND     CREATED    STATUS    PORTS                   NAMES
# xxxxxxxxxxxx  postgres:14-alpine                       postgres    X min ago  Up        -                       sea-sync-postgres
# xxxxxxxxxxxx  ...mysql-sea-syncweb-backend:amd64-...   python3     X min ago  Up        -                       mysql-sea-sync-backend
# xxxxxxxxxxxx  ...mysql-sea-syncweb-frontend:amd64-...  nginx       X min ago  Up        0.0.0.0:3000->80/tcp    mysql-sea-sync-frontend

# 测试后端 API
curl http://localhost:15001/api/system/config

# 测试前端
curl http://localhost:3000

# 验证网络配置（不应该有 firewall 警告）
podman network ls

# 验证 frontend 使用的网络
podman inspect mysql-sea-sync-frontend --format '{{range $k, $v := .NetworkSettings.Networks}}{{$k}}{{end}}'
# 应该输出: podman
```

### 9. 访问应用

- 前端界面: `http://服务器IP:3000`
- 后端 API: `http://服务器IP:15001`
- 默认账号: `admin` / `admin123`

## 数据管理

### 数据持久化

PostgreSQL 数据存储在 Podman Volume 中，即使容器重启数据也不会丢失：

```bash
# 查看 Volume
podman volume ls | grep postgres

# 查看 Volume 详情
podman volume inspect mysql-sea-syncweb_postgres_data
```

### 数据库备份与恢复

项目提供了完整的数据库备份恢复工具，支持交互式和非交互式操作。

快速示例:

```bash
# 备份所有重要业务表
echo "0" | DOCKER_BIN=podman ./scripts/backup_postgres.sh

# 交互式恢复
DOCKER_BIN=podman ./scripts/restore_postgres.sh

# 非交互式恢复
DOCKER_BIN=podman ./scripts/restore_postgres_direct.sh backups/schedules_backup_20251024.sql.gz schedules Y

# 同步到远程服务器
./scripts/sync_schedules_to_remote.sh root@192.168.200.101
```

定时备份配置:

```bash
# 每天凌晨 2 点自动备份
crontab -e
# 添加以下行
0 2 * * * cd /opt/mysql-sea-syncweb && DOCKER_BIN=podman bash -c 'echo "0" | ./scripts/backup_postgres.sh' >> /var/log/sea-sync-backup.log 2>&1
```

## 日志管理

### 查看日志

```bash
# 实时查看所有服务日志
podman-compose logs -f

# 查看特定服务日志
podman-compose logs -f backend
podman-compose logs -f postgres
podman-compose logs -f frontend

# 查看最近 100 行日志
podman-compose logs --tail=100 backend
```

### 日志持久化

后端日志已挂载到宿主机 `./logs` 目录：

```bash
# 查看后端日志
tail -f logs/app.log

# 日志轮转（防止日志文件过大）
# 安装 logrotate
sudo apt install logrotate

# 创建 /etc/logrotate.d/sea-sync
sudo tee /etc/logrotate.d/sea-sync > /dev/null <<'EOF'
/opt/mysql-sea-syncweb/logs/*.log {
    daily
    rotate 30
    compress
    delaycompress
    missingok
    notifempty
    create 0644 root root
}
EOF
```

## 容器管理

### 启动/停止服务

```bash
# 启动所有服务
podman-compose start

# 停止所有服务（不删除容器）
podman-compose stop

# 重启服务
podman-compose restart

# 重启单个服务
podman-compose restart backend
```

### 更新应用

```bash
# 1. 拉取最新镜像
podman-compose pull backend frontend

# 2. 重新创建容器（保留数据）
podman-compose up -d --force-recreate backend frontend

# 或分步更新
podman-compose up -d --force-recreate backend
podman-compose up -d --force-recreate frontend
```

### 清理和重置

```bash
# 停止并删除所有容器（保留数据）
podman-compose down

# 删除所有容器和数据卷（谨慎使用）
podman-compose down -v

# 清理未使用的镜像
podman image prune -a

# 清理未使用的卷
podman volume prune
```

## 系统服务配置（开机自启动）

### 方式一：使用 systemd 管理 podman-compose

创建 systemd 服务文件：

```bash
sudo tee /etc/systemd/system/sea-sync.service > /dev/null <<'EOF'
[Unit]
Description=MySQL SeaTable Sync Web Services
After=network.target

[Service]
Type=oneshot
RemainAfterExit=yes
WorkingDirectory=/opt/mysql-sea-syncweb
ExecStart=/usr/local/bin/podman-compose up -d
ExecStop=/usr/local/bin/podman-compose down
User=root

[Install]
WantedBy=multi-user.target
EOF

# 重载 systemd
sudo systemctl daemon-reload

# 启用开机自启动
sudo systemctl enable sea-sync.service

# 启动服务
sudo systemctl start sea-sync.service

# 查看状态
sudo systemctl status sea-sync.service
```

### 方式二：使用 Podman 自身的重启策略

容器已配置 `restart: unless-stopped`，Podman 守护进程会自动重启容器：

```bash
# 启用 Podman 系统服务
sudo systemctl enable podman.service
sudo systemctl start podman.service

# 查看服务状态
sudo systemctl status podman.service
```

## 安全建议

### 1. 修改默认密码

```bash
# 修改 .env 中的数据库密码
POSTGRES_PASSWORD=your_very_strong_password

# 修改应用管理员密码（首次登录后在界面修改）
```

### 2. 防火墙配置

```bash
# 安装 ufw（如果未安装）
sudo apt install ufw

# 启用防火墙
sudo ufw enable

# 允许 SSH
sudo ufw allow 22/tcp

# 允许前端访问
sudo ufw allow 3000/tcp

# 允许后端 API（如果需要外部访问）
sudo ufw allow 15001/tcp

# 不要暴露 PostgreSQL 端口到公网（已使用 host 网络，默认只监听 localhost）

# 查看防火墙状态
sudo ufw status
```

### 3. 使用反向代理（推荐）

使用 Nginx 作为反向代理，配置 HTTPS：

```bash
# 安装 Nginx
sudo apt install nginx certbot python3-certbot-nginx

# 创建 Nginx 配置
sudo tee /etc/nginx/sites-available/sea-sync > /dev/null <<'EOF'
server {
    listen 80;
    server_name your-domain.com;

    # 前端
    location / {
        proxy_pass http://localhost:3000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    # 后端 API
    location /api {
        proxy_pass http://localhost:15001;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
EOF

# 启用配置
sudo ln -s /etc/nginx/sites-available/sea-sync /etc/nginx/sites-enabled/

# 测试配置
sudo nginx -t

# 重载 Nginx
sudo systemctl reload nginx

# 配置 HTTPS（使用 Let's Encrypt）
sudo certbot --nginx -d your-domain.com
```

## 故障排查

### 问题1: firewall 插件警告

症状：
```
WARN[0000] Error validating CNI config file /etc/cni/net.d/mysql-sea-syncweb_default.conflist: [plugin firewall does not support config version "1.0.0"]
```

原因：
- podman-compose 自动创建的默认网络包含 firewall 插件
- Ubuntu Podman 3.4.4 的 firewall 插件不支持 CNI 1.0.0

解决方案：
```bash
# 确认 podman-compose.yml 中已配置使用外部 podman 网络
# 删除自动生成的网络配置
sudo rm /etc/cni/net.d/mysql-sea-syncweb_default.conflist
podman network rm mysql-sea-syncweb_default

# 重启服务
podman-compose down
podman-compose up -d
```

### 问题2: PostgreSQL 无法启动

```bash
# 查看详细日志
podman logs sea-sync-postgres

# 检查数据卷权限
podman volume inspect mysql-sea-syncweb_postgres_data

# 如果损坏，删除 Volume 重建（数据会丢失）
podman-compose down -v
podman-compose up -d postgres
```

### 问题3: 后端无法连接数据库

```bash
# 检查数据库是否就绪
podman exec sea-sync-postgres pg_isready -U postgres

# 检查环境变量
podman exec mysql-sea-sync-backend env | grep POSTGRES

# 由于使用 host 网络，直接检查端口
ss -tlnp | grep 5432
```

### 问题4: 前端 502 错误

```bash
# 检查后端服务状态
podman ps | grep backend

# 检查后端日志
podman logs mysql-sea-sync-backend

# 测试后端 API
curl http://localhost:15001/api/system/config

# 检查 extra_hosts 配置
podman inspect mysql-sea-sync-frontend | grep -A 5 ExtraHosts
```

### 问题5: 容器内存不足

```bash
# 检查容器资源使用
podman stats

# 增加系统资源限制
# 编辑 /etc/security/limits.conf
sudo tee -a /etc/security/limits.conf > /dev/null <<'EOF'
* soft nofile 65536
* hard nofile 65536
* soft nproc 65536
* hard nproc 65536
EOF

# 重启服务器使配置生效
sudo reboot
```

### 问题6: 镜像拉取困难

```bash
# 编辑 /etc/containers/registries.conf.d/01-mirrors.conf
sudo tee /etc/containers/registries.conf.d/01-mirrors.conf >/dev/null <<'EOF'
unqualified-search-registries = ["docker.io"]

[[registry]]
prefix = "docker.io"
location = "registry-1.docker.io"

[[registry.mirror]]
location = "docker.m.daocloud.io"
EOF

# 拉取验证
podman pull node:18-alpine
```

## 监控和维护

### 健康检查

```bash
# 查看容器健康状态
podman ps --format "table {{.Names}}\t{{.Status}}"

# 查看健康检查日志
podman inspect sea-sync-postgres | grep -A 10 Health
```

### 性能监控

```bash
# 查看容器资源使用
podman stats

# 查看特定容器资源使用
podman stats sea-sync-postgres mysql-sea-sync-backend

# 查看系统资源
htop
```

### 进入容器调试

```bash
# 进入 PostgreSQL 容器
podman exec -it sea-sync-postgres bash
# 或直接使用 psql
podman exec -it sea-sync-postgres psql -U postgres sea_sync

# 进入后端容器
podman exec -it mysql-sea-sync-backend bash

# 进入前端容器
podman exec -it mysql-sea-sync-frontend sh
```

## 部署检查清单

### 前置准备
- [ ] 服务器已安装 Podman（3.4.4+）
- [ ] 已安装 podman-compose
- [ ] 已创建 CNI 网络配置（87-podman-bridge.conflist）
- [ ] 项目文件已上传到服务器
- [ ] 已创建并配置 `.env` 文件
- [ ] 已修改默认密码（数据库和应用）

### 镜像准备
- [ ] PostgreSQL 镜像拉取成功
- [ ] 后端镜像拉取成功
- [ ] 前端镜像拉取成功

### 服务启动
- [ ] PostgreSQL 容器启动成功
- [ ] PostgreSQL 数据库已初始化（10 个表创建成功）
- [ ] 后端容器启动成功并连接数据库
- [ ] 前端容器启动成功
- [ ] 没有 firewall 插件警告

### 功能验证
- [ ] 可以通过浏览器访问前端（http://服务器IP:3000）
- [ ] 可以访问后端 API（http://服务器IP:15001/api/system/config）
- [ ] 可以登录系统（admin/admin123）
- [ ] 可以创建设备和同步任务

### 运维配置
- [ ] 已配置自动备份脚本（crontab）
- [ ] 已配置防火墙规则
- [ ] 已配置日志轮转
- [ ] 已配置开机自启动
- [ ] （可选）已配置 HTTPS 反向代理
- [ ] （可选）已配置监控告警

## 参考命令速查

```bash
# 快速启动
podman-compose up -d

# 查看状态
podman-compose ps
podman ps -a

# 查看日志
podman-compose logs -f backend

# 重启服务
podman-compose restart

# 停止服务
podman-compose stop

# 备份数据库（使用项目脚本）
echo "0" | DOCKER_BIN=podman ./scripts/backup_postgres.sh

# 备份数据库（手动）
podman exec sea-sync-postgres pg_dump -U postgres sea_sync > backup.sql

# 进入数据库
podman exec -it sea-sync-postgres psql -U postgres sea_sync

# 更新应用
podman-compose pull && podman-compose up -d --force-recreate

# 清理
podman-compose down

# 查看网络
podman network ls

# 查看资源使用
podman stats
```

## 与 Docker 的差异

如果你熟悉 Docker，以下是 Podman 的主要差异：

1. **无守护进程**: Podman 不需要后台守护进程，直接以普通用户身份运行
2. **命令兼容**: `podman` 命令与 `docker` 命令几乎完全兼容，可以使用别名 `alias docker=podman`
3. **根模式**: 本部署使用 root 用户运行，与 Docker 类似
4. **网络配置**: CNI 插件配置文件位于 `/etc/cni/net.d/`，而非 Docker 的内部网络管理
5. **备份脚本**: 项目脚本通过 `DOCKER_BIN=podman` 环境变量支持 Podman

## 相关资源

- Podman 官方文档: https://docs.podman.io/
- podman-compose GitHub: https://github.com/containers/podman-compose
- CNI 插件文档: https://www.cni.dev/docs/
- 项目文档: `docs/DOCKER_DEPLOY.md`（Docker 部署参考）

## 更新日志

- 2025-10-24: 初始版本，基于 Ubuntu + Podman 3.4.4 部署经验编写
