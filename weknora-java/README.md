# WeKnora Java版本

基于原始WeKnora Go项目的Java Spring Boot重构版本。

## 架构对比

### Go版本 → Java版本技术栈映射

| Go组件 | Java对应技术 | 说明 |
|--------|------------|------|
| Gin Web框架 | Spring Boot + Spring MVC | Web服务框架 |
| GORM | Spring Data JPA | ORM数据库操作 |
| go-dig | Spring IoC容器 | 依赖注入 |
| Viper | Spring Boot Configuration | 配置管理 |
| context.Context | Spring Security Context | 请求上下文 |
| goroutine | @Async + ThreadPoolTaskExecutor | 异步处理 |
| interfaces | Interface + @Service | 服务接口 |

### 包结构映射

| Go包结构 | Java包结构 |
|----------|-----------|
| `internal/handler` | `com.weknora.controller` |
| `internal/application/service` | `com.weknora.service` |
| `internal/application/repository` | `com.weknora.repository` |
| `internal/types` | `com.weknora.dto` |
| `internal/models` | `com.weknora.model` |
| `internal/config` | `com.weknora.config` |
| `internal/middleware` | `com.weknora.interceptor` |
| `internal/errors` | `com.weknora.exception` |

## 核心模块设计

### 1. 配置层 (Configuration Layer)
- `@ConfigurationProperties` 映射配置文件
- `@Configuration` 类管理Bean创建
- `application.yml` 替代Go的config结构

### 2. 控制层 (Controller Layer)
- `@RestController` 处理HTTP请求
- `@RequestMapping` 定义路由
- 统一异常处理和响应格式

### 3. 服务层 (Service Layer)
- `@Service` 注解业务逻辑组件
- `@Transactional` 事务管理
- 接口-实现分离设计

### 4. 数据层 (Repository Layer)
- Spring Data JPA Repository
- 自定义查询方法
- 向量数据库集成

### 5. 模型层 (Model Layer)
- JPA实体类映射数据库表
- DTO对象传输数据
- 验证注解约束

## 技术选型

- **框架**: Spring Boot 3.2+
- **Java版本**: JDK 17+
- **数据库**: PostgreSQL + pgvector
- **搜索引擎**: Elasticsearch 8.x
- **向量存储**: pgvector扩展
- **文档解析**: Apache Tika
- **消息队列**: Redis + Spring队列
- **监控**: Micrometer + Prometheus
- **测试**: JUnit 5 + Testcontainers