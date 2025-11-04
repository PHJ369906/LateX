# WeKnora Java 后端复刻迁移计划

本文档给出将现有 WeKnora Go 后端完整复刻为 Java 后端的实施计划，覆盖 64 条 API（含 `/health`），保证路径、方法、入参/出参、SSE 行为与错误封装完全一致，实现前端与使用脚本零改动迁移。计划分阶段推进，以“先功能闭环、再全面对齐、最后生产化”为原则，稳步上线。

---

## 1. 目标与范围

- 目标
  - 100% 复刻现有 64 条 API（含 `/health`），兼容 JWT 与 `X-API-Key` 两种鉴权方式。
  - 保持 JSON 字段命名、错误包装、SSE 事件格式与行为完全一致。
  - 与现有 DocReader（Python gRPC）、ParadeDB/PostgreSQL、MinIO/COS、Ollama/OpenAI 兼容 API、Jaeger 等生态无缝对接。

- 范围
  - 模块：Auth、Tenants、Knowledge Bases、Knowledge、Chunks、Sessions、Chat/knowledge-search、Messages、Models、Evaluation、Initialization、System。
  - 检索：ParadeDB 关键词检索（paradedb.match/score）+ pgvector 向量检索（halfvec 余弦）。

> 完整 API 列表见：`docs/API_对照清单.md`（“API 全量清单（仅路由与方法）”章节）。

---

## 2. 技术选型

- 框架：Spring Boot 3.x + WebFlux（SSE 友好）+ Spring Security
- 数据访问：MyBatis-Plus + 原生 SQL（paradedb.match/score、pgvector halfvec）
- 数据库：PostgreSQL/ParadeDB（向量：pgvector）
- gRPC：grpc-java（对接 DocReader；maxInboundMessageSize ≥ 50MB）
- HTTP 客户端：WebClient（OpenAI 兼容、Ollama、Rerank）
- 存储：MinIO Java SDK（S3 兼容）/ 腾讯 COS SDK；Local 实现
- 观测：OpenTelemetry(OTLP) → Jaeger；Logback MDC 透传 Request-ID
- 配置：application.yaml / profile 分环境；Jackson snake_case 命名策略

---

## 3. 兼容性与契约要求

- 鉴权：JWT（推荐）+ `X-API-Key`（兼容）；与现有中间件语义一致
- 错误格式：`{success:false,error:{code,message,details}}`；成功 `{success:true,data|message}`
- JSON 命名：snake_case；必要处加 `@JsonProperty`
- SSE：事件 `references` + `answer`，answer 流式增量与 done 标记一致；支持 `/sessions/continue-stream`
- GET+Body：`/knowledge-bases/:id/hybrid-search` 保持 GET+JSON；如网关不支持，服务端放开 GET 读 body
- 路由细节：尾斜杠匹配（evaluation），路径参数命名与顺序一致
- Header：支持 `X-Request-ID`；CORS 与现有一致；健康检查 `/health`

---

## 4. 数据与检索

- ParadeDB 关键词检索：`paradedb.match(field => 'content', value => ?, distance => 1)` + `paradedb.score(id)` 排序
- pgvector 向量检索：`embedding::halfvec(dim) <=> ?::halfvec < (1 - threshold)` 排序并换算得分
- 结构化实体：User、AuthToken、Tenant、KnowledgeBase、Knowledge、Chunk、Session、Message、Model、检索结果等
- 迁移：Flyway/Liquibase 并行支持 ParadeDB 初始化脚本与 pgvector 拓展

---

## 5. 外部依赖与客户端

- DocReader（Python gRPC）：文件/URL 解析、分块；多模态 OCR/Caption；健康探针；50MB 消息上限
- 存储：MinIO/COS/Local；初始化模块需验证配置并可选创建桶/路径
- 模型：OpenAI 兼容（非流/流）、Ollama、Rerank；Qwen“enable_thinking”非流置 false（对齐现有逻辑）
- 流管理：内存/Redis（可配置）；支持流恢复查询与更新
- 观测：OTLP gRPC 至 Jaeger；请求链路覆盖 SSE

---

## 6. 项目结构（建议）

```
weknora-java/
├─ api/                 # Controller + DTO（与返回包裹保持一致）
├─ app/                 # 业务用例与流水线（RAG pipeline）
├─ domain/              # 聚合根、领域服务接口
├─ infra/               # MyBatis-Plus 实体/Mapper/XML、外部客户端（gRPC/HTTP/存储）、SQL
├─ config/              # Security、CORS、异常、OTEL、Jackson
├─ proto/               # docreader.proto 与生成的 stubs
└─ docs/                # 契约与开发文档
```

---

## 7. 模块拆解与任务

- Auth（7 路由）
  - 任务：密码哈希、JWT 签发/刷新/吊销；`/me` 获取租户；`X-API-Key` 兼容
  - 验收：登录/刷新/注销/换密/校验通过，错误包装一致

- Tenants（5 路由）
  - 任务：API Key 生成与保存；检索引擎配置字段保留
  - 验收：CRUD 正常；List 返回 `{items:[]}` 包裹

- Models（5 路由）
  - 任务：参数存储（BaseURL、APIKey、EmbeddingParameters.Dimension）；默认/状态字段
  - 验收：CRUD 正常；参数序列化一致

- Knowledge Bases（7 路由）
  - 任务：ChunkingConfig、ImageProcessingConfig、VLMConfig、StorageConfig 映射；GET+Body 兼容
- 验收：CRUD 正常；hybrid-search 结果结构与排序一致

- Knowledge（9 路由）
  - 任务：multipart 上传、解析（DocReader gRPC）、对象存储（MinIO/COS/Local）、Chunk 入库、索引写入
- 验收：上传/URL 均可；下载流；图片信息更新成功

- Chunks（4 路由）
  - 任务：分页查询、更新、删除（单/全）
- 验收：内容清理（Sanitize）；返回结构一致

- Sessions（7 路由）
  - 任务：策略字段映射；SSE 流恢复；消息写入与状态
  - 验收：CRUD、标题生成、流恢复正常

- Chat/Search（2 路由）
  - 任务：流水线（先最小闭环：search→generate→SSE；后加 rewrite/rerank/merge/filter）；流事件规范
  - 验收：`references` 先发；`answer` 持续、最终 done；Search 仅检索不总结

- Messages（2 路由）
  - 任务：before_time 解析；limit 默认值；删除幂等
  - 验收：与前端滚动加载行为一致

- Evaluation（2 路由）
  - 任务：任务触发与结果查询；指标先占位（对齐结构），后续补实现
  - 验收：契约一致

- Initialization（12 路由）
  - 任务：综合校验与模型入库；异步下载任务与进度；multipart 表单解析；DocReader 回路验证
  - 验收：与初始化页面联调通过

- System（1 路由）
  - 任务：版本/提交/构建时间字段映射（Java 版可替换为自身信息）
  - 验收：响应结构 `{code,msg,data}`

---

## 8. 里程碑与时间规划（单人估算）

- M1：骨架 + 基础能力（Auth/JWT、/health、System、错误/观测/安全）2–3 天
- M2：Tenants/Models/KnowledgeBase（含 hybrid-search 接口契约）7–10 天
- M3：Knowledge/Chunks + DocReader + 存储 + 索引写入（最小闭环）7–10 天
- M4：检索引擎（ParadeDB+pgvector）5–8 天
- M5：Sessions/Chat（SSE 闭环）、Messages 8–12 天
- M6：Initialization（含 Ollama 下载/进度、测试接口）、Evaluation 11–17 天
- M7：对照测试与验收 3–5 天；部署/容器化 2–3 天

合计：MVP（最小闭环）约 3–4 周；全量对齐 + 初始化/评估等增强约再 4–6 周；生产化加固再 2–4 周。

---

## 9. 验收与测试

- 契约测试：RestAssured/HTTP 工具对照 `docs/API_对照清单.md` 逐条断言
- SSE 测试：集成测试验证 `references`→`answer`→done 流顺序与事件体
- 端到端：前端登录→初始化→上传→检索→问答→流恢复
- 观测验证：Jaeger Trace 全链路覆盖，错误包装一致
- 性能：SSE 并发（WebFlux 资源占用）、DocReader 大文件、并发向量嵌入与检索压测

---

## 10. 风险与应对

- ParadeDB/pgvector 兼容性：优先原生 SQL；增加集成测试；如需，退回 float4[] + cast
- SSE 稳定性：WebFlux + backpressure；代理超时与心跳（注释事件/空白心跳）
- GET+Body：服务端允许 GET 读 body，必要时后台兼容 POST（不暴露前端）
- DocReader gRPC：超时与重试；maxInboundMessageSize；健康探针
- 命名/尾斜杠/路径参数：统一测试覆盖，确保前端契约零改动
- 多模态与对象存储：严格参数校验；必要时提供存储可用性预检查

---

## 11. 交付物

- Java 后端服务（与 Go 版同规格 64 条 API）
- 配置模板（application.yaml）与部署清单（Dockerfile/Compose）
- 契约与对照测试用例（含 SSE）
- 运行与运维文档（与初始化页面联动步骤）

---

## 12. 推进方式与后续工作

- 任务拆分：按“模块 × Endpoint”粒度建立看板，给出 DoD（完成定义）与用例
- 先打通 MVP 闭环（上传→解析→索引→检索→SSE），再补全 Initialization/Evaluation
- 与前端联调后，灰度替换 Go 服务，观测链路与错误率稳定后切换流量

---

## 附录：实现约束摘要

- JSON 命名：snake_case；必要时用 @JsonProperty 明确字段名
- 错误包装：统一中间件封装；成功与失败结构固定
- SSE：`references` 先发；`answer` 流式增量；最后 `done: true`
- 検索：ParadeDB 关键词 + pgvector 向量，支持 TopK/阈值、KB 过滤、结果去重
- GET+Body：`/knowledge-bases/:id/hybrid-search` 保持 GET 语义
- 尾斜杠：`/api/v1/evaluation/` 路由保持匹配
- 免鉴权：`/health`、`/api/v1/auth/register|login|refresh`，其余需鉴权（JWT/X-API-Key）
