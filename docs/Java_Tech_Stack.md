# WeKnora Java 复刻版技术栈

本文档列出将 WeKnora 后端由 Go 复刻为 Java 时的推荐技术栈，覆盖 Web、数据、检索、gRPC、对象存储、模型接入、观测、测试与交付等方面，确保与现有 64 条 API 行为完全一致（含 SSE 流式）。

## 语言与运行时
- Java 21（LTS，推荐）/ Java 17（最低）

## 核心框架
- Spring Boot 3.x（应用框架）
- Spring WebFlux（响应式 Web 与 SSE：Server-Sent Events）
- Spring Security（鉴权：JWT + `X-API-Key` 兼容）
- Jackson（JSON 序列化，snake_case 策略）

## 数据访问与迁移
- MyBatis-Plus（ORM 与通用 CRUD）
- PostgreSQL / ParadeDB（主存储 + 向量检索）
- 原生 SQL 支持（MyBatis-Plus XML/注解方式编写 `paradedb.match/score` 与 `halfvec` 表达）
- pgvector 驱动/类型支持（可用 JDBC + 数组/文本向量映射，或直接绑定原生 SQL 参数）
- Flyway（数据库迁移，等效复刻 migrations/paradedb/*.sql）

## 缓存与异步（可选）
- Redis（流管理/会话流恢复可选后端）
- Reactor（响应式并发与背压处理）

## gRPC 与文档解析
- grpc-java（与 Python DocReader 对接）
- protobuf + 编译插件（生成 Java stubs）
- gRPC 客户端配置：`maxInboundMessageSize >= 50MB`，健康探针

## HTTP 客户端
- Spring WebClient（OpenAI 兼容、Ollama、Rerank、远程校验）

## 对象存储
- MinIO Java SDK（`io.minio:minio`，S3 兼容）
- 腾讯云 COS SDK（`com.qcloud:cos_api`）
- Local 文件系统（与现有 `local` 行为一致）

## 检索与搜索
- ParadeDB 关键词检索：`paradedb.match/score` 原生 SQL
- pgvector 向量检索：`embedding::halfvec(dim) <=> ?::halfvec` + 阈值/TopK
-（后续可选）Elasticsearch v7/v8 官方 Java 客户端对齐现有实现

## 模型接入（LLM/Embedding/Rerank/VLM）
- OpenAI 兼容 API（Chat/Embedding，含流式）
- Ollama REST API（本地/远程）
- Reranker HTTP 接口（对齐当前行为）
- Qwen（DashScope 兼容）：非流式 `enable_thinking=false`（与现有逻辑一致）

## 安全与鉴权
- Spring Security 过滤器链
- JWT：`spring-security-oauth2-jose`（JWT 编解码）
- 密码哈希：BCryptPasswordEncoder
- API Key 解析：`X-API-Key` → 租户校验
- CORS：与现有前端允许源、方法、Header 对齐

## 观测与日志
- Micrometer + OpenTelemetry（OTLP → Jaeger）
- Logback（结构化日志，MDC 透传 `X-Request-ID`）

## 配置与环境
- application.yaml（分环境 profile）
- `@ConfigurationProperties`（类型安全配置）
- 环境变量映射（与 `.env` 语义对齐）

## 测试
- JUnit 5（单元/集成）
- Rest Assured（HTTP 契约/回归）
- Mockito/MockK（依赖替身）
- Testcontainers（PostgreSQL/Redis/MinIO 集成测试）

## 构建与交付
- Maven（或 Gradle）
- Dockerfile（可与现有 Compose 并存：Postgres/ParadeDB、Redis、MinIO、Jaeger、DocReader）
- Docker Compose（本地一键拉起）
-（可选）GitHub Actions CI/CD

## 代码规范与工具（可选）
- Lombok（减少样板代码）
- MapStruct（对象映射）
- Spotless/Checkstyle（格式与静态检查）
- MyBatis-Plus Generator（实体/Mapper/XML 代码生成）

## 关键契约约束（与现有保持一致）
- 错误包装：`{success:false,error:{code,message,details}}`
- 成功包装：`{success:true,data|message}`
- SSE：事件类型 `references` / `answer`，`answer` 流式增量，末尾 `done=true`
- GET + Body：`/knowledge-bases/:id/hybrid-search` 保持 GET 语义
- 尾斜杠：`/api/v1/evaluation/` 路由匹配
- 免鉴权：`/health`、`/api/v1/auth/register|login|refresh`；其余需鉴权（JWT 或 API Key）
