# Java版WeKnora Docker部署指南

## 📋 概述

Java版WeKnora现在完全支持Docker容器化部署！这个文档将指导你如何使用Docker运行Java版本的WeKnora。

## 🏗️ 文件结构

```
WeKnora-main/
├── docker-compose.yml          # Go版本的docker-compose（原有）
├── docker-compose.java.yml     # Java版本的docker-compose（新增）
├── weknora-java/
│   └── Dockerfile              # Java版本的Dockerfile（新增）
└── scripts/
    ├── start_all.sh           # Go版本启动脚本
    └── start_java.sh          # Java版本启动脚本（新增）
```

## 🚀 快速开始

### 1. 使用脚本启动（推荐）

```bash
# 启动Java版服务
./scripts/start_java.sh start

# 停止服务
./scripts/start_java.sh stop

# 重启服务
./scripts/start_java.sh restart

# 查看日志
./scripts/start_java.sh logs

# 查看服务状态
./scripts/start_java.sh status
```

### 2. 使用docker-compose直接启动

```bash
# 启动所有服务
docker-compose -f docker-compose.java.yml up -d

# 查看日志
docker-compose -f docker-compose.java.yml logs -f

# 停止服务
docker-compose -f docker-compose.java.yml down
```

## 📦 包含的服务

Java版docker-compose包含以下服务：

| 服务 | 容器名 | 端口 | 说明 |
|------|--------|------|------|
| weknora-java | WeKnora-java | 8080 | Java版主服务 |
| postgres | WeKnora-postgres | 5432 | PostgreSQL数据库 |
| docreader | WeKnora-docreader | 50051 | 文档处理服务 |
| redis | WeKnora-redis | 6379 | 缓存服务 |
| minio | WeKnora-minio | 9000/9001 | 对象存储 |
| frontend | WeKnora-frontend | 3000 | 前端界面 |

## 🔧 配置

### 环境变量配置

创建`.env`文件（如果不存在）：

```bash
# 数据库配置
DB_USER=postgres
DB_PASSWORD=postgres123!@#
DB_NAME=WeKnora
DB_PORT=5432

# MinIO配置
MINIO_ACCESS_KEY_ID=minioadmin
MINIO_SECRET_ACCESS_KEY=minioadmin
MINIO_BUCKET_NAME=weknora
MINIO_PORT=9000
MINIO_CONSOLE_PORT=9001

# Redis配置
REDIS_PORT=6379
REDIS_PASSWORD=

# LLM配置
LLM_PROVIDER=ollama
OLLAMA_BASE_URL=http://host.docker.internal:11434
OLLAMA_DEFAULT_MODEL=qwen2.5:7b
OPENAI_API_KEY=your-api-key-here

# 前端配置
FRONTEND_PORT=3000

# DocReader配置
DOCREADER_PORT=50051

# 存储类型
STORAGE_TYPE=minio
```

### Ollama服务（需单独启动）

Java版服务需要Ollama提供LLM支持：

```bash
# 安装Ollama（如未安装）
curl -fsSL https://ollama.ai/install.sh | sh

# 启动Ollama服务
ollama serve

# 拉取模型
ollama pull qwen2.5:7b
ollama pull nomic-embed-text
```

## 🏃 完整启动流程

```bash
# 1. 克隆项目（如果还没有）
git clone https://github.com/your-repo/WeKnora-main.git
cd WeKnora-main

# 2. 创建.env文件
cp .env.example .env  # 或手动创建

# 3. 启动Ollama（单独终端）
ollama serve

# 4. 启动Java版服务
./scripts/start_java.sh start

# 5. 等待服务就绪（约30秒）
# 检查服务状态
./scripts/start_java.sh status

# 6. 访问服务
# - API: http://localhost:8080
# - 前端: http://localhost:3000
# - MinIO: http://localhost:9001 (admin/admin)
```

## 🔍 验证服务

```bash
# 健康检查
curl http://localhost:8080/api/v1/system/health

# 检查配置
curl http://localhost:8080/api/v1/initialization/config

# 测试Ollama连接
curl http://localhost:8080/api/v1/initialization/ollama/status
```

## 🐳 Docker镜像管理

### 构建镜像

```bash
# 构建Java服务镜像
cd weknora-java
docker build -t weknora-java:latest .

# 或使用脚本
./scripts/start_java.sh build
```

### 推送到私有仓库

```bash
# 打标签
docker tag weknora-java:latest your-registry/weknora-java:latest

# 推送
docker push your-registry/weknora-java:latest
```

## 📊 监控和日志

### 查看日志

```bash
# 查看Java服务日志
docker logs -f WeKnora-java

# 查看所有服务日志
docker-compose -f docker-compose.java.yml logs -f

# 查看特定服务日志
docker-compose -f docker-compose.java.yml logs -f postgres
```

### 进入容器调试

```bash
# 进入Java容器
docker exec -it WeKnora-java /bin/bash

# 检查应用状态
docker exec WeKnora-java ps aux
docker exec WeKnora-java netstat -tlnp
```

## ⚠️ 常见问题

### 1. 端口冲突

如果端口被占用，修改`.env`文件中的端口配置：
```bash
APP_PORT=8081  # 改为其他端口
```

### 2. 数据库连接失败

确保PostgreSQL容器正常运行：
```bash
docker-compose -f docker-compose.java.yml ps postgres
docker-compose -f docker-compose.java.yml logs postgres
```

### 3. Ollama连接失败

- 确保Ollama服务在运行
- Docker容器使用`host.docker.internal`访问宿主机服务
- Mac/Windows上自动支持，Linux需要额外配置

### 4. 内存不足

修改Dockerfile中的JVM参数：
```dockerfile
ENV JAVA_OPTS="-Xmx4g -Xms1g -XX:+UseG1GC"
```

## 🔄 Go版和Java版切换

```bash
# 停止Go版服务
docker-compose down

# 启动Java版服务
docker-compose -f docker-compose.java.yml up -d

# 或反向操作切换回Go版
```

## 📝 开发模式

如果需要在开发时使用Docker服务但本地运行Java：

```bash
# 只启动依赖服务
docker-compose -f docker-compose.java.yml up -d postgres redis minio docreader

# 本地运行Java
cd weknora-java
mvn spring-boot:run
```

## 🛠️ 生产部署建议

1. **使用环境变量管理敏感信息**
   - 不要将密码提交到代码仓库
   - 使用Docker secrets或环境变量

2. **资源限制**
   ```yaml
   services:
     weknora-java:
       deploy:
         resources:
           limits:
             cpus: '2'
             memory: 4G
   ```

3. **持久化数据**
   - 确保volumes正确配置
   - 定期备份PostgreSQL数据

4. **监控和告警**
   - 集成Prometheus/Grafana
   - 设置健康检查告警

## 📚 相关文档

- [主项目README](README.md)
- [Java实现总结](JAVA_IMPLEMENTATION_SUMMARY.md)
- [API文档](docs/API.md)
- [Go版Docker指南](README.md#docker-deployment)

## 🤝 贡献

欢迎提交Issue和Pull Request来改进Java版Docker支持！

---

**注意**: Java版本现已完全实现了所有核心功能，包括真实的Parquet数据加载、LLM集成、流式续传等，不再使用模拟数据。
