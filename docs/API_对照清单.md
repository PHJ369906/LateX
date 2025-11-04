# WeKnora 后端 API 对照清单

本文档汇总当前后端对外 API 列表，按功能分组，便于复刻到其他后端语言时对照实现。

## 基础信息
- Base URL: `/api/v1`
- 健康检查（无需鉴权）：`GET /health`
- 鉴权方式：
  - 推荐：`Authorization: Bearer <JWT>`（登录后获取）
  - 兼容：`X-API-Key: <tenant_api_key>`（租户级访问）
- 建议请求头：`X-Request-ID: <唯一请求ID>`（便于链路追踪）

### 通用规范
- Content-Type：除文件上传外均为 `application/json`。
- 成功响应：多数接口返回 `{ "success": true, "data": ... }` 或 `{ "success": true, "message": "..." }`；个别系统信息接口为 `{code,msg,data}`。
- 错误响应（由中间件统一封装）：
  ```json
  {
    "success": false,
    "error": {
      "code": "BadRequest|Unauthorized|Forbidden|NotFound|InternalServer...",
      "message": "错误信息",
      "details": "可选细节"
    }
  }
  ```
- 分页参数（Query）：`page?`（默认1）、`page_size?`（默认20，最大100）。
- SSE：流式接口返回 `text/event-stream`，事件数据为 JSON（见文末“流式（SSE）说明”）。

## API 全量清单（仅路由与方法）
- 健康：
  - GET `/health`
- 认证 Auth：
  - POST `/api/v1/auth/register`
  - POST `/api/v1/auth/login`
  - POST `/api/v1/auth/refresh`
  - GET  `/api/v1/auth/validate`
  - POST `/api/v1/auth/logout`
  - GET  `/api/v1/auth/me`
  - GET  `/api/v1/auth/tenant` (兼容：X-API-Key)
  - POST `/api/v1/auth/change-password`
- 租户 Tenants：
  - POST   `/api/v1/tenants`
  - GET    `/api/v1/tenants`
  - GET    `/api/v1/tenants/:id`
  - PUT    `/api/v1/tenants/:id`
  - DELETE `/api/v1/tenants/:id`
- 知识库 Knowledge Bases：
  - POST   `/api/v1/knowledge-bases`
  - GET    `/api/v1/knowledge-bases`
  - GET    `/api/v1/knowledge-bases/:id`
  - PUT    `/api/v1/knowledge-bases/:id`
  - DELETE `/api/v1/knowledge-bases/:id`
  - GET    `/api/v1/knowledge-bases/:id/hybrid-search`
  - POST   `/api/v1/knowledge-bases/copy`
- 知识 Knowledge：
  - POST `/api/v1/knowledge-bases/:id/knowledge/file`
  - POST `/api/v1/knowledge-bases/:id/knowledge/file/url`  — 路径兼容，等价于 `/knowledge-bases/:id/knowledge/url`
  - POST `/api/v1/knowledge-bases/:id/knowledge/url`
  - GET  `/api/v1/knowledge-bases/:id/knowledge`
  - GET  `/api/v1/knowledge/batch`
  - GET  `/api/v1/knowledge/:id`
  - PUT  `/api/v1/knowledge/:id`
  - DELETE `/api/v1/knowledge/:id`
  - GET  `/api/v1/knowledge/:id/download`
  - PUT  `/api/v1/knowledge/image/:id/:chunk_id`
- 分块 Chunks：
  - GET    `/api/v1/chunks/:knowledge_id`
  - PUT    `/api/v1/chunks/:knowledge_id/:id`
  - DELETE `/api/v1/chunks/:knowledge_id/:id`
  - DELETE `/api/v1/chunks/:knowledge_id`
- 会话 Sessions：
  - POST   `/api/v1/sessions`
  - GET    `/api/v1/sessions`
  - GET    `/api/v1/sessions/:id`
  - PUT    `/api/v1/sessions/:id`
  - DELETE `/api/v1/sessions/:id`
  - POST   `/api/v1/sessions/:session_id/generate_title`
  - GET    `/api/v1/sessions/continue-stream/:session_id`
- 聊天/检索 Chat：
  - POST `/api/v1/knowledge-chat/:session_id`
  - POST `/api/v1/knowledge-search`
- 消息 Messages：
  - GET    `/api/v1/messages/:session_id/load`
  - DELETE `/api/v1/messages/:session_id/:id`
- 模型 Models：
  - POST   `/api/v1/models`
  - GET    `/api/v1/models`
  - GET    `/api/v1/models/:id`
  - PUT    `/api/v1/models/:id`
  - DELETE `/api/v1/models/:id`
- 评估 Evaluation：
  - POST `/api/v1/evaluation/`
  - GET  `/api/v1/evaluation/`
- 初始化 Initialization：
  - GET  `/api/v1/initialization/config/:kbId`
  - POST `/api/v1/initialization/initialize/:kbId`
  - GET  `/api/v1/initialization/ollama/status`
  - GET  `/api/v1/initialization/ollama/models`
  - POST `/api/v1/initialization/ollama/models/check`
  - POST `/api/v1/initialization/ollama/models/download`
  - GET  `/api/v1/initialization/ollama/download/progress/:taskId`
  - GET  `/api/v1/initialization/ollama/download/tasks`
  - POST `/api/v1/initialization/remote/check`
  - POST `/api/v1/initialization/embedding/test`
  - POST `/api/v1/initialization/rerank/check`
  - POST `/api/v1/initialization/multimodal/test`
- 系统 System：
  - GET `/api/v1/system/info`


说明：除健康检查与以下免鉴权接口外，其余均需鉴权：
- `POST /api/v1/auth/register`
- `POST /api/v1/auth/login`
- `POST /api/v1/auth/refresh`

## 认证 Auth
- POST `/api/v1/auth/register` — 用户注册（免鉴权）
  - Body(JSON): `{ "username": string(3-50), "email": email, "password": string(min=6) }`
  - 201 响应: `{ "success": true, "message": "Registration successful", "user": { id, username, email, tenant_id, is_active, created_at, updated_at } }`
  - 示例：
    ```bash
    curl -X POST http://localhost:8080/api/v1/auth/register \
      -H 'Content-Type: application/json' \
      -d '{"username":"demo","email":"demo@example.com","password":"Passw0rd!"}'
    ```

- POST `/api/v1/auth/login` — 登录（免鉴权，发放 JWT）
  - Body(JSON): `{ "email": string, "password": string }`
  - 200 响应(JSON): `{ "success": true, "message": "Login successful", "user": {...}, "tenant": {...}, "token": "<JWT>", "refresh_token": "<refresh>" }`

- POST `/api/v1/auth/refresh` — 刷新 JWT（免鉴权）
  - Body(JSON): `{ "refreshToken": string }`
  - 200 响应(JSON): `{ "success": true, "access_token": "<JWT>", "refresh_token": "<refresh>" }`

- GET `/api/v1/auth/validate` — 校验 Token 是否有效
  - Header: `Authorization: Bearer <JWT>`
  - 200 响应(JSON): `{ "success": true, "message": "Token is valid", "user": {...} }`

- POST `/api/v1/auth/logout` — 登出
  - Header: `Authorization: Bearer <JWT>`
  - 200 响应(JSON): `{ "success": true, "message": "Logout successful" }`

- GET `/api/v1/auth/me` — 获取当前用户信息（Bearer）
  - Header: `Authorization: Bearer <JWT>`
  - 200 响应(JSON): `{ "success": true, "data": { "user": {...}, "tenant": {...} } }`

- GET `/api/v1/auth/tenant` — 获取当前租户信息（兼容 X-API-Key）
  - Header: `X-API-Key: <tenant_api_key>`
  - 200 响应(JSON): `{ "success": true, "data": { "user": null, "tenant": {...} } }`

- POST `/api/v1/auth/change-password` — 修改密码
  - Body(JSON): `{ "old_password": string, "new_password": string(min=6) }`
  - 200 响应(JSON): `{ "success": true, "message": "Password changed successfully" }`
  - 示例：
    ```bash
    curl -X POST http://localhost:8080/api/v1/auth/change-password \
      -H "Authorization: Bearer $TOKEN" \
      -H 'Content-Type: application/json' \
      -d '{"old_password":"old","new_password":"NewPassw0rd!"}'
    ```

## 租户 Tenants
- POST `/api/v1/tenants` — 创建租户（返回租户 API Key）
  - Body(JSON): `types.Tenant` 字段（常用：`name, description, business, retriever_engines` 等）
  - 201 响应(JSON): `{ "success": true, "data": { id, name, api_key, ... } }`

- GET `/api/v1/tenants` — 获取租户列表
  - 200 响应(JSON): `{ "success": true, "data": { "items": [ ... ] } }`

- GET `/api/v1/tenants/:id` — 获取租户详情
  - Path: `id`(uint)
  - 200 响应(JSON): `{ "success": true, "data": { id, name, api_key, ... } }`

- PUT `/api/v1/tenants/:id` — 更新租户（API Key 可能变更）
  - Body(JSON): `types.Tenant` 可更新字段
  - 200 响应(JSON): `{ "success": true, "data": { ... } }`

- DELETE `/api/v1/tenants/:id` — 删除租户
  - 200 响应(JSON): `{ "success": true, "message": "Tenant deleted successfully" }`
  - 示例：
    ```bash
    curl -X DELETE http://localhost:8080/api/v1/tenants/10000 \
      -H "Authorization: Bearer $TOKEN"
    ```

## 知识库 Knowledge Bases
- POST `/api/v1/knowledge-bases` — 创建知识库
  - Body(JSON): `types.KnowledgeBase`（常用：`name, description, chunking_config, ...`）
  - 201 响应(JSON): `{ "success": true, "data": { id, name, ... } }`

- GET `/api/v1/knowledge-bases` — 知识库列表
  - 200 响应(JSON): `{ "success": true, "data": [ { ... }, ... ] }`

- GET `/api/v1/knowledge-bases/:id` — 知识库详情
  - 200 响应(JSON): `{ "success": true, "data": { id, name, chunking_config, ... } }`

- PUT `/api/v1/knowledge-bases/:id` — 更新知识库
  - Body(JSON): `{ "name": string, "description"?: string, "config": { "chunking_config": {...}, "image_processing_config": {...} } }`
  - 200 响应(JSON): `{ "success": true, "data": { ... } }`

- DELETE `/api/v1/knowledge-bases/:id` — 删除知识库
  - 200 响应(JSON): `{ "success": true, "message": "Knowledge base deleted successfully" }`

- GET `/api/v1/knowledge-bases/:id/hybrid-search` — 混合检索（关键词 + 向量）
  - Body(JSON): `types.SearchParams`（常用：`query_text, top_k, threshold ...`）
  - 200 响应(JSON): `{ "success": true, "data": [ { "results": [...], "retriever_engine_type": "postgres|elasticsearch", "retriever_type": "keywords|vector" }, ... ] }`
  - 示例：
    ```bash
    curl -X GET http://localhost:8080/api/v1/knowledge-bases/kb-00000001/hybrid-search \
      -H "Authorization: Bearer $TOKEN" \
      -H 'Content-Type: application/json' \
      -d '{"query_text":"公司报销标准", "match_count":10, "vector_threshold":0.5, "keyword_threshold":0.3}'
    ```

- POST `/api/v1/knowledge-bases/copy` — 拷贝知识库
  - Body(JSON): `{ "source_id": string, "target_id"?: string }`
  - 200 响应(JSON): `{ "success": true, "message": "Knowledge base copy successfully" }`
  - 示例：
    ```bash
    curl -X POST http://localhost:8080/api/v1/knowledge-bases/copy \
      -H "Authorization: Bearer $TOKEN" -H 'Content-Type: application/json' \
      -d '{"source_id":"kb-00000001","target_id":"kb-00000002"}'
    ```

## 知识 Knowledge
- POST `/api/v1/knowledge-bases/:id/knowledge/file` — 通过文件创建知识
  - Content-Type: `multipart/form-data`
  - Form: `file`(必填, 文件), `metadata`(可选, JSON 字符串), `enable_multimodel`(可选, bool)
  - 200 响应(JSON): `{ "success": true, "data": types.Knowledge }`
  - 示例：
    ```bash
    curl -X POST http://localhost:8080/api/v1/knowledge-bases/kb-00000001/knowledge/file \
      -H 'Authorization: Bearer <JWT>' \
      -F file=@/path/to/doc.pdf \
      -F metadata='{"source":"upload"}' \
      -F enable_multimodel=true
    ```

- POST `/api/v1/knowledge-bases/:id/knowledge/url` — 通过 URL 创建知识
  - Body(JSON): `{ "url": string, "enable_multimodel"?: bool }`
  - 201 响应(JSON): `{ "success": true, "data": types.Knowledge }`
  - 示例：
    ```bash
    curl -X POST http://localhost:8080/api/v1/knowledge-bases/kb-00000001/knowledge/url \
      -H "Authorization: Bearer $TOKEN" -H 'Content-Type: application/json' \
      -d '{"url":"https://example.com/page.html","enable_multimodel":true}'
    ```

- GET `/api/v1/knowledge-bases/:id/knowledge` — 获取知识库下的知识列表
  - Query: `page?`, `page_size?`
  - 200 响应(JSON): `{ "success": true, "data": [...], "total": n, "page": n, "page_size": n }`

- GET `/api/v1/knowledge/batch` — 批量获取知识
  - Query: `ids=<id1>&ids=<id2>...`
  - 200 响应(JSON): `{ "success": true, "data": [ types.Knowledge, ... ] }`

- GET `/api/v1/knowledge/:id` — 获取知识详情
  - 200 响应(JSON): `{ "success": true, "data": types.Knowledge }`
  - 示例：
    ```bash
    curl -X GET http://localhost:8080/api/v1/knowledge/$KNOWLEDGE_ID \
      -H "Authorization: Bearer $TOKEN"
    ```

- PUT `/api/v1/knowledge/:id` — 更新知识
  - Body(JSON): `types.Knowledge` 可更新字段（例如 `title/description/metadata` 等）
  - 200 响应(JSON): `{ "success": true, "message": "Knowledge chunk updated successfully" }`
  - 示例：
    ```bash
    curl -X PUT http://localhost:8080/api/v1/knowledge/$KN_ID \
      -H "Authorization: Bearer $TOKEN" -H 'Content-Type: application/json' \
      -d '{"title":"新标题","description":"说明"}'
    ```

- DELETE `/api/v1/knowledge/:id` — 删除知识
  - 200 响应(JSON): `{ "success": true, "message": "Deleted successfully" }`

- GET `/api/v1/knowledge/:id/download` — 下载知识文件
  - 响应：二进制流（headers: `Content-Disposition: attachment; filename=...`）
  - 示例：
    ```bash
    curl -OJ http://localhost:8080/api/v1/knowledge/$KN_ID/download \
      -H "Authorization: Bearer $TOKEN"
    ```

- PUT `/api/v1/knowledge/image/:id/:chunk_id` — 更新图像分块信息
  - Body(JSON): `{ "image_info": string }`
  - 200 响应(JSON): `{ "success": true, "message": "Knowledge chunk image updated successfully" }`
  - 示例：
    ```bash
    curl -X PUT http://localhost:8080/api/v1/knowledge/image/$KN_ID/$CHUNK_ID \
      -H "Authorization: Bearer $TOKEN" -H 'Content-Type: application/json' \
      -d '{"image_info":"{\"images\":[...]}"}'
    ```

## 分块 Chunks
- GET `/api/v1/chunks/:knowledge_id` — 获取知识的分块列表
  - Query: `page?`, `page_size?`
  - 200 响应(JSON): `{ "success": true, "data": [ types.Chunk... ], "total": n, "page": n, "page_size": n }`

- PUT `/api/v1/chunks/:knowledge_id/:id` — 更新分块
  - Body(JSON): `{ "content"?: string, "is_enabled"?: bool, ... }`
  - 200 响应(JSON): `{ "success": true, "data": types.Chunk }`

- DELETE `/api/v1/chunks/:knowledge_id/:id` — 删除单个分块
  - 200 响应(JSON): `{ "success": true, "message": "Chunk deleted" }`

- DELETE `/api/v1/chunks/:knowledge_id` — 删除该知识下所有分块
  - 200 响应(JSON): `{ "success": true, "message": "All chunks under knowledge deleted" }`
  - 示例：
    ```bash
    curl -X DELETE http://localhost:8080/api/v1/chunks/$KNOWLEDGE_ID \
      -H "Authorization: Bearer $TOKEN"
    ```

## 会话 Sessions
- POST `/api/v1/sessions` — 创建会话
  - Body(JSON): `{ "knowledge_base_id": string, "session_strategy"?: { max_rounds?, enable_rewrite?, fallback_strategy?, fallback_response?, embedding_top_k?, keyword_threshold?, vector_threshold?, rerank_top_k?, rerank_threshold?, summary_parameters?{...}, summary_model_id?, rerank_model_id? } }`
  - 200 响应(JSON): `{ "success": true, "data": types.Session }`

- GET `/api/v1/sessions` — 会话列表（当前租户）
  - 200 响应(JSON): `{ "success": true, "data": [ types.Session... ] }`

- GET `/api/v1/sessions/:id` — 会话详情
  - 200 响应(JSON): `{ "success": true, "data": types.Session }`

- PUT `/api/v1/sessions/:id` — 更新会话
  - Body(JSON): `types.Session` 可更新字段
  - 200 响应(JSON): `{ "success": true, "data": types.Session }`

- DELETE `/api/v1/sessions/:id` — 删除会话
  - 200 响应(JSON): `{ "success": true, "message": "Deleted successfully" }`

- POST `/api/v1/sessions/:session_id/generate_title` — 生成会话标题
  - 200 响应(JSON): `{ "success": true, "data": "标题文本" }`
  - 示例：
    ```bash
    curl -X POST http://localhost:8080/api/v1/sessions/$SESSION_ID/generate_title \
      -H "Authorization: Bearer $TOKEN"
    ```

- GET `/api/v1/sessions/continue-stream/:session_id` — 继续接收活跃流（SSE）
  - Query: `message_id`
  - 响应：`text/event-stream`，事件体为 `types.StreamResponse`
  - 示例：
    ```bash
    curl -N -H "Authorization: Bearer $TOKEN" \
      "http://localhost:8080/api/v1/sessions/continue-stream/$SESSION_ID?message_id=$MSG_ID"
    ```

## 聊天 Chat / 检索
- POST `/api/v1/knowledge-chat/:session_id` — 基于知识问答（SSE 流式）
  - Body(JSON): `{ "query": string }`
  - 响应：`text/event-stream`
    - 参考事件：
      ```json
      { "id": "<req-id>", "response_type": "references", "knowledge_references": [ {"results":[...],"retriever_engine_type":"postgres","retriever_type":"vector"} ] }
      { "id": "<req-id>", "response_type": "answer", "content": "部分答案...", "done": false }
      { "id": "<req-id>", "response_type": "answer", "content": "最后一段", "done": true }
      ```

- POST `/api/v1/knowledge-search` — 知识检索（不经 LLM 总结，不创建消息）
  - Body(JSON): `{ "knowledge_base_id": string, "query": string }`
  - 200 响应(JSON): `{ "success": true, "data": [ types.RetrieveResult... ] }`
  - 示例（SSE 问答）：
    ```bash
    curl -N -X POST http://localhost:8080/api/v1/knowledge-chat/$SESSION_ID \
      -H "Authorization: Bearer $TOKEN" -H 'Content-Type: application/json' \
      -d '{"query":"请根据知识库总结XX"}'
    ```
  - 示例（直接检索）：
    ```bash
    curl -X POST http://localhost:8080/api/v1/knowledge-search \
      -H "Authorization: Bearer $TOKEN" -H 'Content-Type: application/json' \
      -d '{"knowledge_base_id":"kb-00000001","query":"报销标准"}'
    ```

## 消息 Messages
- GET `/api/v1/messages/:session_id/load` — 向上滚动加载更早消息
  - Query: `limit?`(默认20), `before_time?`(RFC3339Nano)
  - 200 响应(JSON): `{ "success": true, "data": [ types.Message... ] }`

- DELETE `/api/v1/messages/:session_id/:id` — 删除某条消息
  - 200 响应(JSON): `{ "success": true, "message": "Message deleted successfully" }`
  - 示例：
    ```bash
    curl -X DELETE http://localhost:8080/api/v1/messages/$SESSION_ID/$MSG_ID \
      -H "Authorization: Bearer $TOKEN"
    ```

## 模型 Models
- POST `/api/v1/models` — 创建模型（Chat/Embedding/Rerank/VLM）
  - Body(JSON): `{ "name": string, "type": "knowledge_qa|embedding|rerank|vllm", "source": "remote|local|ollama", "description"?: string, "parameters": { "base_url"?: string, "api_key"?: string, "embedding_parameters"?: { "dimension": number } }, "is_default"?: bool }`
  - 201 响应(JSON): `{ "success": true, "data": types.Model }`

- GET `/api/v1/models` — 模型列表
  - 200 响应(JSON): `{ "success": true, "data": [ types.Model... ] }`

- GET `/api/v1/models/:id` — 模型详情
  - 200 响应(JSON): `{ "success": true, "data": types.Model }`

- PUT `/api/v1/models/:id` — 更新模型
  - Body(JSON): `{ "name"?, "description"?, "parameters"?, "is_default"? }`
  - 200 响应(JSON): `{ "success": true, "data": types.Model }`

- DELETE `/api/v1/models/:id` — 删除模型
  - 200 响应(JSON): `{ "success": true, "message": "Model deleted" }`
  - 示例：
    ```bash
    curl -X DELETE http://localhost:8080/api/v1/models/$MODEL_ID \
      -H "Authorization: Bearer $TOKEN"
    ```

## 评估 Evaluation
- POST `/api/v1/evaluation/` — 触发评估
  - Body(JSON 或表单): `{ "dataset_id"?: string, "knowledge_base_id"?: string, "chat_id"?: string, "rerank_id"?: string }`
  - 200 响应(JSON): `{ "success": true, "data": { task_id, status, ... } }`

- GET `/api/v1/evaluation/` — 获取评估结果
  - Query: `task_id`
  - 200 响应(JSON): `{ "success": true, "data": { ...结果... } }`
  - 示例：
    ```bash
    curl -X GET 'http://localhost:8080/api/v1/evaluation/?task_id=$TASK_ID' \
      -H "Authorization: Bearer $TOKEN"
    ```

## 初始化 Initialization（模型与环境）
- GET `/api/v1/initialization/config/:kbId` — 按知识库获取当前配置
  - 200 响应(JSON): `{ "success": true, "data": { llm?, embedding?, rerank?, multimodal?, documentSplitting, hasFiles } }`

- POST `/api/v1/initialization/initialize/:kbId` — 按知识库执行初始化
  - Body(JSON):
    ```json
    {
      "llm": {"source":"remote|ollama","modelName":"...","baseUrl":"...","apiKey":"..."},
      "embedding": {"source":"remote|ollama","modelName":"...","baseUrl":"...","apiKey":"...","dimension":768},
      "rerank": {"enabled":true,"modelName":"...","baseUrl":"...","apiKey":"..."},
      "multimodal": {"enabled":true,"vlm": {"modelName":"...","baseUrl":"...","apiKey":"...","interfaceType":"openai|ollama"}, "storageType":"cos|minio", "cos"?: {...}, "minio"?: {...}},
      "documentSplitting": {"chunkSize":1000,"chunkOverlap":200,"separators":["\n\n","\n","。"]}
    }
    ```
  - 200 响应(JSON): `{ "success": true, "data": { models: [...] } }`
  - 示例：
    ```bash
    curl -X POST http://localhost:8080/api/v1/initialization/initialize/kb-00000001 \
      -H "Authorization: Bearer $TOKEN" -H 'Content-Type: application/json' \
      -d '{
        "llm": {"source":"ollama","modelName":"qwen:7b","baseUrl":"","apiKey":""},
        "embedding": {"source":"ollama","modelName":"nomic-embed-text","baseUrl":"","apiKey":"","dimension":768},
        "rerank": {"enabled": false},
        "multimodal": {"enabled": true, "vlm": {"modelName":"qwen2.5vl:3b","baseUrl":"","apiKey":"","interfaceType":"ollama"}, "storageType":"minio", "minio": {"bucketName":"kb","pathPrefix":"imgs/"}},
        "documentSplitting": {"chunkSize":1000,"chunkOverlap":200,"separators":["\n\n","\n","。"]}
      }'
    ```

- GET `/api/v1/initialization/ollama/status` — 检查 Ollama 状态
- GET `/api/v1/initialization/ollama/models` — 列出 Ollama 模型
- POST `/api/v1/initialization/ollama/models/check` — 校验模型可用（Body: `{ "model": "name" }` 等）
- POST `/api/v1/initialization/ollama/models/download` — 触发下载模型（Body: `{ "modelName": "qwen2.5:7b" }`），返回 taskId
- GET `/api/v1/initialization/ollama/download/progress/:taskId` — 下载进度
- GET `/api/v1/initialization/ollama/download/tasks` — 下载任务列表
  - 示例（下载与查询进度）：
    ```bash
    curl -X POST http://localhost:8080/api/v1/initialization/ollama/models/download \
      -H "Authorization: Bearer $TOKEN" -H 'Content-Type: application/json' \
      -d '{"modelName":"qwen2.5:7b"}'
    curl -X GET http://localhost:8080/api/v1/initialization/ollama/download/tasks \
      -H "Authorization: Bearer $TOKEN"
    ```

- POST `/api/v1/initialization/remote/check` — 校验远程模型（OpenAI 兼容）
  - Body(JSON): `{ "baseUrl": string, "apiKey"?: string, "modelName": string, "type": "chat|embedding|rerank" }`

- POST `/api/v1/initialization/embedding/test` — 测试嵌入模型
  - Body(JSON): `{ "baseUrl": string, "apiKey"?: string, "modelName": string, "text": string }`

- POST `/api/v1/initialization/rerank/check` — 校验 Rerank 模型
  - Body(JSON): `{ "baseUrl": string, "apiKey"?: string, "modelName": string }`

- POST `/api/v1/initialization/multimodal/test` — 测试多模态能力
  - Content-Type: `multipart/form-data`
  - Form：`image`(文件) + VLM/COS/MinIO/切分参数（见代码 `testMultimodalFunction`）
  - 关键表单字段：
    - `vlm_model`, `vlm_base_url`, `vlm_api_key`, `vlm_interface_type`（openai|ollama）
    - `storage_type`（cos|minio）；当为 cos：`cos_secret_id|cos_secret_key|cos_region|cos_bucket_name|cos_app_id|cos_path_prefix`；当为 minio：`minio_bucket_name|minio_path_prefix`
    - 切分：`chunk_size`(100–10000), `chunk_overlap`(>=0,<chunk_size), `separators`(JSON 数组字符串)
  - 示例：
    ```bash
    curl -X POST http://localhost:8080/api/v1/initialization/multimodal/test \
      -H "Authorization: Bearer $TOKEN" \
      -F image=@/path/to/img.png \
      -F vlm_model=qwen2.5vl:3b -F vlm_interface_type=ollama \
      -F storage_type=minio -F minio_bucket_name=kb -F minio_path_prefix=imgs/ \
      -F chunk_size=1000 -F chunk_overlap=200 -F separators='["\\n\\n","\\n","。"]'
    ```

## 系统信息 System
- GET `/api/v1/system/info` — 系统信息（版本、构建信息等）
  - 200 响应(JSON): `{ "code": 0, "msg": "success", "data": { "version": "...", "commit_id": "...", "build_time": "...", "go_version": "..." } }`
  - 示例：
    ```bash
    curl http://localhost:8080/api/v1/system/info
    ```

## 流式（SSE）说明
- `POST /api/v1/knowledge-chat/:session_id` 返回 Server-Sent Events（`text/event-stream`），逐块推送生成结果。
- `GET /api/v1/sessions/continue-stream/:session_id` 用于在断线后继续接收活跃的流。

事件数据结构（JSON）均为 `types.StreamResponse`：
- `references` 事件：`{ id, response_type: "references", knowledge_references: [...] }`
- `answer` 事件：`{ id, response_type: "answer", content, done }`

示例（Node/浏览器使用 fetch-event-source）：
```ts
import { fetchEventSource } from '@microsoft/fetch-event-source'
await fetchEventSource('http://localhost:8080/api/v1/knowledge-chat/<session_id>', {
  method: 'POST',
  headers: {
    'Authorization': `Bearer ${token}`,
    'Content-Type': 'application/json',
  },
  body: JSON.stringify({ query: '你的问题' }),
  onmessage(ev) {
    const data = JSON.parse(ev.data)
    // data.response_type === 'references' | 'answer'
  }
})
```

## 健康检查
- GET `/health`
  - 200 响应(JSON): `{ "status": "ok" }`

---
注：详细的参数与示例请求/响应可参考 `docs/API.md`，本清单用于路由与职责对照速查。
