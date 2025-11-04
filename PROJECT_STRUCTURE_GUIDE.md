# 📚 WeKnora 项目结构说明

## 🎯 项目现状

WeKnora 项目目前有 **两个后端实现版本**：

1. **Go版本**（原版/主版本） - 生产就绪
2. **Java版本**（移植版） - 功能完整，刚完成真实化改造

## 🗂️ 目录结构

```
WeKnora-main/
├── 📁 Go版本核心代码
│   ├── cmd/                    # Go 主程序入口
│   ├── internal/               # Go 业务逻辑
│   ├── go.mod & go.sum        # Go 依赖管理
│   └── docker-compose.yml     # Go 版本的 Docker 配置
│
├── 📁 Java版本代码
│   └── weknora-java/          # Java Spring Boot 项目
│       ├── src/               # Java 源代码
│       ├── pom.xml            # Maven 依赖管理
│       └── Dockerfile         # Java 版本的 Docker 镜像
│
├── 📁 共享服务
│   ├── services/docreader/    # Python 文档处理服务（两版本共用）
│   ├── frontend/               # Vue.js 前端（两版本共用）
│   ├── dataset/                # 数据集文件（两版本共用）
│   └── migrations/             # 数据库脚本（两版本共用）
│
├── 📁 部署配置
│   ├── docker-compose.yml     # Go 版本完整部署
│   ├── docker-compose.java.yml # Java 版本完整部署
│   └── scripts/
│       ├── start_all.sh       # Go 版本启动脚本
│       └── start_java.sh      # Java 版本启动脚本
│
└── 📁 文档
    ├── README.md               # 项目主文档（Go版为主）
    ├── README_CN.md            # 中文文档
    ├── JAVA_IMPLEMENTATION_SUMMARY.md  # Java版实现总结
    └── JAVA_DOCKER_GUIDE.md   # Java版Docker指南
```

## 🤔 为什么有两个版本？

### Go版本（原版）
- ✅ **官方主版本**，功能最完整
- ✅ 性能优异，资源占用少
- ✅ 适合生产环境部署
- ✅ 社区主要维护版本

### Java版本（移植版）
- ✅ 为Java生态用户提供的选择
- ✅ 刚完成所有模拟代码真实化
- ✅ 便于Java开发者二次开发
- ✅ 企业Java技术栈集成友好

## 🎮 如何选择使用哪个版本？

### 快速决策树

```
需要生产部署？
├─ 是 → 使用 Go 版本
└─ 否 → 继续判断
        │
        主要技术栈是Java？
        ├─ 是 → 使用 Java 版本
        └─ 否 → 使用 Go 版本
```

### 详细对比

| 特性 | Go 版本 | Java 版本 | 建议场景 |
|------|---------|-----------|----------|
| **性能** | ⭐⭐⭐⭐⭐ | ⭐⭐⭐ | 高并发选Go |
| **内存占用** | ~100MB | 512MB-2GB | 资源受限选Go |
| **启动速度** | 秒级 | 10-30秒 | 频繁重启选Go |
| **开发体验** | 一般 | 优秀(IDE) | 开发调试选Java |
| **生态系统** | 云原生 | 企业级 | 按技术栈选择 |
| **维护状态** | 主要维护 | 社区维护 | 长期项目选Go |

## 🚀 启动指南

### 只想快速体验？

```bash
# 使用 Go 版本（推荐）
./scripts/start_all.sh

# 访问：http://localhost
```

### 想使用 Java 版本？

```bash
# 使用 Java 版本
./scripts/start_java.sh start

# 访问：http://localhost:3000
```

### 开发调试？

#### Go 版本开发
```bash
# 启动依赖服务
docker-compose up -d postgres redis docreader

# 本地运行 Go
go run cmd/server/main.go
```

#### Java 版本开发
```bash
# 启动依赖服务  
docker-compose -f docker-compose.java.yml up -d postgres redis docreader

# 本地运行 Java
cd weknora-java
mvn spring-boot:run
```

## 🔄 版本切换

两个版本**不能同时运行**（端口冲突），切换方法：

```bash
# 从 Go 切换到 Java
docker-compose down                      # 停止 Go 版本
docker-compose -f docker-compose.java.yml up -d  # 启动 Java 版本

# 从 Java 切换到 Go
docker-compose -f docker-compose.java.yml down   # 停止 Java 版本
docker-compose up -d                      # 启动 Go 版本
```

## 📦 共享组件说明

以下组件两个版本都会使用：

1. **PostgreSQL** - 数据库（端口 5432）
2. **DocReader** - 文档处理（端口 50051）  
3. **Redis** - 缓存（端口 6379）
4. **MinIO** - 对象存储（端口 9000/9001）
5. **Ollama** - LLM服务（端口 11434）
6. **Frontend** - 前端界面（端口 80/3000）

## 🛠️ 开发建议

### 如果你要修改代码

- **改进核心功能** → 优先在 Go 版本修改
- **添加 Java 特性** → 在 Java 版本修改
- **修改前端** → frontend/ 目录（两版本共享）
- **改进文档处理** → services/docreader/（两版本共享）

### 如果你要部署生产

**强烈建议使用 Go 版本**：
- 更稳定
- 更新更频繁
- 资源占用少
- 社区支持好

## ❓ FAQ

**Q: 我应该删除其中一个版本吗？**
A: 不建议。保留两个版本可以满足不同用户需求。

**Q: 数据库是共享的吗？**
A: 是的，如果使用同一个PostgreSQL实例，数据是共享的。

**Q: 能同时运行两个版本吗？**
A: 不能，它们默认使用相同端口。除非修改端口配置。

**Q: 哪个版本功能更完整？**
A: 功能已经完全一致，Java版刚完成所有真实化实现。

**Q: 我是新手，用哪个？**
A: 用 Go 版本，直接运行 `./scripts/start_all.sh`

## 📝 总结

- **生产环境** = Go 版本
- **Java 开发** = Java 版本  
- **快速体验** = Go 版本
- **二次开发** = 看你的技术栈

---

💡 **提示**：如果还是觉得混乱，就只关注 Go 版本，忽略 weknora-java/ 目录即可。
