# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 项目概述

WeKnora是一个基于大语言模型的文档理解和语义检索框架，采用RAG（检索增强生成）范式，提供高质量的上下文感知问答能力。

该项目包含多语言实现：
- **Go版本**（主要实现）：完整的后端服务，位于根目录
- **Java版本**（开发中）：Spring Boot实现，位于 `weknora-java/` 目录

## 构建和运行命令

### 使用Makefile（推荐）

```bash
# 启动所有服务（包括Ollama和Docker容器）
make start-all

# 仅启动Ollama服务
make start-ollama

# 停止所有服务
make stop-all

# 构建应用
make build

# 运行测试
make test

# 清理数据库（谨慎使用）
make clean-db

# 数据库迁移
make migrate-up
make migrate-down

# 代码格式化和检查
make fmt
make lint

# 构建Docker镜像
make docker-build-all     # 构建所有镜像
make docker-build-app     # 仅构建应用镜像
make docker-build-frontend # 仅构建前端镜像
```

### 使用脚本

```bash
# 启动所有服务
./scripts/start_all.sh

# 停止服务
./scripts/start_all.sh --stop

# 仅启动Docker服务
./scripts/start_all.sh --docker

# 检查环境
./scripts/start_all.sh --check
```

### Java版本

```bash
cd weknora-java
mvn spring-boot:run        # 运行应用
mvn clean compile         # 编译
mvn test                  # 运行测试
```

### 前端开发

```bash
cd frontend
npm run dev              # 开发模式
npm run build           # 构建生产版本
npm run type-check      # 类型检查
```

## 核心架构

### Go版本架构（主要实现）

项目采用清洁架构和依赖注入模式：

#### 目录结构
- `cmd/server/` - 应用入口点，依赖注入容器初始化
- `internal/application/` - 业务逻辑层
  - `service/` - 业务服务（聊天管道、文件处理、检索等）
  - `repository/` - 数据访问层，支持多种检索后端
- `internal/handler/` - HTTP处理器层（租户、认证、知识库管理等）
- `internal/models/` - 模型层（聊天、嵌入、重排序等）
- `internal/config/` - 配置管理
- `internal/middleware/` - HTTP中间件
- `internal/container/` - 依赖注入容器
- `frontend/` - Vue 3 前端应用

#### 关键设计模式

1. **依赖注入**: 使用 `go.uber.org/dig` 进行依赖管理
2. **接口抽象**: `internal/types/interfaces/` 定义核心接口
3. **分层架构**: Handler → Service → Repository 分层
4. **多后端支持**:
   - 检索：PostgreSQL (pgvector) / Elasticsearch v7/v8
   - 存储：本地文件 / MinIO / 腾讯云COS
   - 模型：支持Ollama本地部署和远程API

#### 微服务组件
- **app**: 主应用服务 (Go)
- **docreader**: 文档解析服务 (Python gRPC)
- **frontend**: Web界面 (Vue 3)
- **postgres**: 数据库 (ParadeDB with pgvector)
- **redis**: 缓存和会话存储
- **minio**: 对象存储
- **jaeger**: 分布式追踪

### Java版本架构（开发中）

基于Spring Boot 3 + WebFlux的响应式架构：
- Spring WebFlux (异步非阻塞)
- Spring Security (认证授权)
- MyBatis-Plus (数据访问)
- PostgreSQL (数据库)
- Flyway (数据库迁移)
- OpenTelemetry (链路追踪)

## 开发工作流

### 环境配置

1. 复制环境变量模板：`cp .env.example .env`
2. 编辑 `.env` 文件配置必要参数
3. 启动服务：`make start-all`

### 首次配置

访问 `http://localhost` 会自动跳转到初始化配置页面，按提示配置：
- LLM模型设置
- 嵌入模型配置
- 重排序模型配置
- 向量数据库设置

### 服务访问

- Web UI: `http://localhost`
- 后端API: `http://localhost:8080`
- Jaeger追踪: `http://localhost:16686`
- MinIO控制台: `http://localhost:9001`

### 代码规范

- Go: 遵循 `gofmt` 和 `golangci-lint` 标准
- TypeScript: Vue 3 Composition API + TypeScript
- 提交信息遵循 Conventional Commits 规范

### 测试策略

```bash
# Go测试
make test
go test -v ./...

# Java测试
cd weknora-java && mvn test

# 前端测试
cd frontend && npm run type-check
```

### 数据库操作

- 迁移：`make migrate-up` / `make migrate-down`
- 清理：`make clean-db`（会删除所有数据，谨慎使用）

## 关键集成点

### 模型集成
- **LLM**: 支持Ollama本地部署和OpenAI兼容API
- **嵌入模型**: BGE、GTE等，支持本地和云端API
- **重排序**: 可配置重排序模型提升检索精度

### 存储集成
- **向量数据库**: PostgreSQL + pgvector / Elasticsearch
- **对象存储**: 本地文件系统 / MinIO / 腾讯云COS
- **缓存**: Redis用于会话管理和缓存

### 外部服务
- **文档解析**: gRPC服务处理PDF、Word、图像等
- **链路追踪**: Jaeger集成，支持OTLP协议
- **身份认证**: JWT token认证机制

## MCP服务器集成

项目提供MCP (Model Context Protocol) 服务器支持：

```bash
# 安装MCP服务器
pip install weknora-mcp-server

# 运行MCP服务器
python -m weknora-mcp-server
```

需要配置环境变量：
- `WEKNORA_API_KEY`: 从开发者工具中获取的API密钥
- `WEKNORA_BASE_URL`: WeKnora实例的API地址

## 故障排除

- 查看服务状态：`make list-containers`
- 检查环境配置：`make check-env`
- 查看日志：`docker-compose logs -f [service-name]`
- 重启服务：`make stop-all && make start-all`

详细的故障排除指南请参考：[docs/QA.md](docs/QA.md)