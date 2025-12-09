# 本地构建部署指南

本指南适用于从源码构建并部署 AI Podcast Workshop 项目的完整流程。

---

## 📋 目录

- [系统要求](#系统要求)
- [前置准备](#前置准备)
- [快速开始](#快速开始)
- [详细构建流程](#详细构建流程)
- [常见问题](#常见问题)
- [镜像管理](#镜像管理)

---

## 📦 系统要求

### 硬件要求
- **CPU**: 4核以上
- **内存**: 16GB 以上（推荐 32GB）
- **磁盘空间**: 至少 20GB 可用空间
  - Docker 镜像: ~3.6GB
  - 构建缓存: ~5GB
  - 数据库数据: ~2GB
  - 日志和临时文件: ~1GB

### 软件要求
- **操作系统**: macOS / Linux / Windows (WSL2)
- **Docker**: 20.10+ 
- **Docker Compose**: 2.0+
- **Git**: 2.0+

### 网络要求
- 稳定的互联网连接（用于下载依赖）
- 如果在中国大陆，建议配置镜像加速（Maven、npm、Docker Hub）

---

## 🚀 前置准备

### 1. 安装 Docker 和 Docker Compose

**macOS**:
```bash
# 安装 Docker Desktop
# 下载地址: https://www.docker.com/products/docker-desktop

# 验证安装
docker --version
docker compose version
```

**Linux (Ubuntu/Debian)**:
```bash
# 安装 Docker
curl -fsSL https://get.docker.com | sh

# 安装 Docker Compose
sudo apt-get update
sudo apt-get install docker-compose-plugin

# 添加当前用户到 docker 组
sudo usermod -aG docker $USER
newgrp docker

# 验证安装
docker --version
docker compose version
```

**Windows**:
```powershell
# 安装 Docker Desktop for Windows
# 下载地址: https://www.docker.com/products/docker-desktop

# 启用 WSL2
wsl --install

# 验证安装
docker --version
docker compose version
```

### 2. 配置 Docker 资源限制

**Docker Desktop 设置**:
- Memory: 至少 8GB（推荐 12GB）
- CPU: 至少 4核
- Disk image size: 至少 60GB

**修改位置**:
- macOS/Windows: Docker Desktop → Settings → Resources
- Linux: 修改 `/etc/docker/daemon.json`

### 3. 克隆项目代码

```bash
# 克隆仓库
git clone https://github.com/<你的用户名>/PaiFlow.git
cd PaiFlow
```

---

## ⚡ 快速开始

### 一键部署（推荐新手）

```bash
# 1. 进入 Docker 部署目录
cd docker/astronAgent

# 2. 复制环境变量配置文件
cp .env.example .env

# 3. 修改 .env 文件，配置平台凭证
# 必须修改以下字段:
#   PLATFORM_APP_ID=你的APP_ID
#   PLATFORM_API_KEY=你的API_KEY
#   PLATFORM_API_SECRET=你的API_SECRET
vim .env

# 4. 一键构建并启动（包含认证服务）
docker compose -f docker-compose-with-auth.yaml up -d --build

# 5. 查看服务状态
docker compose -f docker-compose-with-auth.yaml ps

# 6. 查看启动日志
docker compose -f docker-compose-with-auth.yaml logs -f
```

**⏱️ 预计耗时**: 首次构建 **30-50 分钟**（取决于网络速度）

### 分步部署（推荐开发者）

```bash
cd docker/astronAgent

# 1. 只构建镜像（不启动）
docker compose -f docker-compose-with-auth.yaml build

# 2. 查看构建详细日志
docker compose -f docker-compose-with-auth.yaml build --progress=plain

# 3. 启动服务
docker compose -f docker-compose-with-auth.yaml up -d

# 4. 验证服务健康状态
docker compose -f docker-compose-with-auth.yaml ps
```

---

## 🔧 详细构建流程

### 构建阶段时间预估

| 服务 | 语言 | 构建时间 | 镜像大小 | 主要耗时操作 |
|------|------|----------|----------|--------------|
| console-hub | Java 21 | 5-10分钟 | 467MB | Maven 下载依赖 |
| console-frontend | React | 3-5分钟 | 118MB | npm install + build |
| core-tenant | Go 1.23 | 2-3分钟 | 110MB | go mod download |
| core-workflow | Python 3.11 | 2-3分钟 | 413MB | pip install |
| core-agent | Python 3.11 | 2-3分钟 | 482MB | pip install |
| core-link | Python 3.11 | 2-3分钟 | 366MB | pip install |
| core-aitools | Python 3.11 | 2-3分钟 | 448MB | pip install + SDK |
| core-rpa | Python 3.11 | 2-3分钟 | 346MB | pip install |
| core-database | Python 3.11 | 2-3分钟 | 497MB | pip install |
| core-knowledge | Python 3.11 | 2-3分钟 | 437MB | pip install |

**总计**: ~30-50分钟，镜像总大小 ~3.6GB

### 构建优化配置

项目已内置以下优化（针对中国大陆网络环境）:

#### 1. Maven 阿里云镜像（console-hub）
```dockerfile
# console/backend/hub/Dockerfile 已配置
RUN mkdir -p /root/.m2 && \
    echo '<?xml version="1.0" encoding="UTF-8"?>
<settings xmlns="http://maven.apache.org/SETTINGS/1.2.0">
  <mirrors>
    <mirror>
      <id>aliyun-central</id>
      <mirrorOf>central</mirrorOf>
      <url>https://maven.aliyun.com/repository/central</url>
    </mirror>
  </mirrors>
</settings>' > /root/.m2/settings.xml
```

#### 2. Node.js 内存限制（console-frontend）
```dockerfile
# console/frontend/Dockerfile 已配置
RUN NODE_OPTIONS="--max-old-space-size=4096" npm run build-prod
```

#### 3. Python pip 镜像（可选配置）
如果 Python 依赖下载慢，可以修改 Dockerfile 添加：
```dockerfile
RUN pip config set global.index-url https://mirrors.aliyun.com/pypi/simple/
```

---

## 🌐 服务访问

### 启动完成后访问地址

| 服务 | 地址 | 说明 |
|------|------|------|
| **前端界面** | http://localhost | Nginx 反向代理 |
| **API 服务** | http://localhost/api | console-hub 后端API |
| **认证服务** | http://localhost:8000 | Casdoor OAuth2 |
| **MinIO 控制台** | http://localhost:18998 | 对象存储管理 |

### 默认账号密码

- **前端登录**: `admin` / `123`
- **MinIO**: `minioadmin` / `minioadmin`
- **MySQL Root**: `root` / `root123`
- **PostgreSQL**: `spark` / `spark123`

---

## 🐛 常见问题

### 问题1: 构建时 Maven 下载依赖超时

**现象**:
```
Could not transfer artifact from/to central (https://repo.maven.apache.org)
```

**解决方案**:
```bash
# 检查 console/backend/hub/Dockerfile 中是否配置了阿里云镜像
grep "aliyun" console/backend/hub/Dockerfile

# 如果没有，手动添加 Maven 镜像配置（项目已配置，跳过此步）
```

### 问题2: frontend 构建时内存溢出

**现象**:
```
FATAL ERROR: Ineffective mark-compacts near heap limit
JavaScript heap out of memory
```

**解决方案**:
```bash
# 检查 console/frontend/Dockerfile 是否配置了 NODE_OPTIONS
grep "NODE_OPTIONS" console/frontend/Dockerfile

# 如果没有，手动添加（项目已配置，跳过此步）
# RUN NODE_OPTIONS="--max-old-space-size=4096" npm run build-prod
```

### 问题3: Docker 磁盘空间不足

**现象**:
```
no space left on device
```

**解决方案**:
```bash
# 清理未使用的镜像
docker image prune -a

# 清理构建缓存
docker builder prune -a

# 查看磁盘使用情况
docker system df
```

### 问题4: Python 依赖下载慢

**现象**:
```
Read timed out while downloading packages
```

**解决方案**:
```bash
# 方案1: 使用国内 pip 镜像（需要修改各个 Python 服务的 Dockerfile）
# 在 pip install 前添加:
# RUN pip config set global.index-url https://mirrors.aliyun.com/pypi/simple/

# 方案2: 重试构建
docker compose -f docker-compose-with-auth.yaml build --no-cache <服务名>
```

### 问题5: Go 依赖下载失败

**现象**:
```
go: downloading github.com/xxx timeout
```

**解决方案**:
```bash
# 方案1: 配置 GOPROXY（需要修改 core/tenant/Dockerfile）
# ENV GOPROXY=https://goproxy.cn,direct

# 方案2: 使用 VPN 或代理
export HTTP_PROXY=http://127.0.0.1:7890
export HTTPS_PROXY=http://127.0.0.1:7890
docker compose build
```

### 问题6: 容器启动后立即退出

**现象**:
```bash
docker compose ps
# 显示某些服务状态为 Exited
```

**解决方案**:
```bash
# 1. 查看容器日志
docker compose -f docker-compose-with-auth.yaml logs <服务名>

# 2. 常见原因排查:

# 数据库连接失败
docker compose -f docker-compose-with-auth.yaml logs mysql postgres

# 环境变量未配置
cat .env | grep PLATFORM

# 端口冲突
lsof -i :8080  # 检查端口占用
```

### 问题7: 工作流执行失败

参考 [DOCKER-LOGS-GUIDE.md](./DOCKER-LOGS-GUIDE.md) 中的问题排查步骤。

---

## 📊 镜像管理

### 查看本地镜像

```bash
# 查看所有本地构建的镜像
docker images | grep "local"

# 查看镜像详细信息
docker image inspect console-hub:local

# 查看镜像构建历史
docker history console-hub:local
```

### 导出镜像（用于离线部署）

```bash
# 导出单个镜像
docker save console-hub:local -o console-hub-local.tar

# 导出所有本地镜像
docker save \
  console-hub:local \
  console-frontend:local \
  core-workflow:local \
  core-agent:local \
  core-tenant:local \
  core-aitools:local \
  core-link:local \
  core-rpa:local \
  core-database:local \
  core-knowledge:local \
  -o all-local-images.tar

# 压缩导出文件
gzip all-local-images.tar
```

### 导入镜像

```bash
# 在目标机器上导入镜像
docker load -i all-local-images.tar.gz

# 验证导入成功
docker images | grep "local"
```

### 清理旧镜像

```bash
# 清理悬空镜像（<none> 标签）
docker image prune -f

# 清理所有未使用的镜像
docker image prune -a

# 清理构建缓存
docker builder prune -a

# 查看清理后的磁盘空间
docker system df
```

---

## 🔄 重新构建

### 完全重新构建（清理所有缓存）

```bash
# 1. 停止所有服务
docker compose -f docker-compose-with-auth.yaml down

# 2. 删除所有本地镜像
docker rmi -f $(docker images | grep "local" | awk '{print $3}')

# 3. 清理构建缓存
docker builder prune -a -f

# 4. 重新构建（不使用缓存）
docker compose -f docker-compose-with-auth.yaml build --no-cache

# 5. 启动服务
docker compose -f docker-compose-with-auth.yaml up -d
```

### 只重新构建单个服务

```bash
# 重新构建 console-hub
docker compose -f docker-compose-with-auth.yaml build --no-cache console-hub

# 重启服务使其生效
docker compose -f docker-compose-with-auth.yaml up -d console-hub
```

---

## 🚀 生产环境部署建议

### 1. 使用预构建镜像

**不推荐**在生产环境每次都从源码构建，建议使用 CI/CD 预构建好的镜像。

#### 方案A: GitHub Actions 自动构建

参考 [CI-CD-GUIDE.md](./CI-CD-GUIDE.md)（待创建）

#### 方案B: 手动构建并推送到镜像仓库

```bash
# 1. 登录镜像仓库
docker login ghcr.io

# 2. 给镜像打标签
docker tag console-hub:local ghcr.io/<你的用户名>/console-hub:v1.0.0

# 3. 推送镜像
docker push ghcr.io/<你的用户名>/console-hub:v1.0.0

# 4. 修改 docker-compose.yaml 使用远程镜像
# services:
#   console-hub:
#     image: ghcr.io/<你的用户名>/console-hub:v1.0.0
```

### 2. 数据持久化

确保以下数据目录已正确挂载:

```yaml
volumes:
  - postgres_data:/var/lib/postgresql/data  # PostgreSQL 数据
  - mysql_data:/var/lib/mysql               # MySQL 数据
  - redis_data:/data                        # Redis 数据
  - minio_data:/data                        # MinIO 对象存储
```

### 3. 日志管理

```bash
# 配置日志轮转（避免日志占满磁盘）
# 在 docker-compose.yaml 中添加:
# services:
#   console-hub:
#     logging:
#       driver: "json-file"
#       options:
#         max-size: "10m"
#         max-file: "3"
```

### 4. 监控和告警

建议配置:
- **健康检查**: 已配置 healthcheck
- **资源限制**: 配置 CPU/Memory limits
- **日志监控**: 使用 ELK/Loki 收集日志
- **性能监控**: 使用 Prometheus + Grafana

---

## 📚 相关文档

- [Docker 日志查看指南](./DOCKER-LOGS-GUIDE.md) - 故障排查必读
- [AGENTS.md](../../AGENTS.md) - 项目架构和开发规范
- [README.md](../../README.md) - 项目介绍

---

## 💡 最佳实践

### 开发环境

```bash
# 1. 使用本地构建镜像
docker compose -f docker-compose-with-auth.yaml up -d --build

# 2. 开发时只重新构建修改的服务
docker compose build <服务名>
docker compose up -d <服务名>

# 3. 查看实时日志
docker compose logs -f <服务名>
```

### 测试环境

```bash
# 1. 使用固定版本的镜像（不要用 latest）
# image: ghcr.io/xxx/console-hub:v1.0.0

# 2. 定期清理未使用的镜像
docker image prune -a --filter "until=24h"

# 3. 数据定期备份
docker compose exec mysql mysqldump -uroot -proot123 --all-databases > backup.sql
```

### 生产环境

```bash
# 1. 使用预构建的镜像（不要用 build）
# image: ghcr.io/xxx/console-hub:v1.0.0

# 2. 配置资源限制
# services:
#   console-hub:
#     deploy:
#       resources:
#         limits:
#           cpus: '2'
#           memory: 2G

# 3. 配置重启策略
# restart: always

# 4. 使用外部数据库（不要用容器化数据库）
```

---

## ❓ 获取帮助

如果遇到问题:

1. **查看日志**: `docker compose logs -f <服务名>`
2. **参考文档**: [DOCKER-LOGS-GUIDE.md](./DOCKER-LOGS-GUIDE.md)
3. **提交 Issue**: https://github.com/<你的仓库>/issues
4. **联系作者**: contact@qoder.com

---

**最后更新**: 2025-11-14
**维护者**: 沉默王二
