# Java版本中的TODO和模拟代码汇总

## 概述
Java版本实现了主要的API接口，但仍存在一些模拟实现和待完成功能。

## 一、模拟代码（Mock Implementation）

### 1. DatasetServiceImpl - 评估数据集服务
**位置**: `com.tencent.weknora.service.impl.DatasetServiceImpl`

**模拟内容**：
- 整个数据集服务使用硬编码的模拟数据
- 模拟了parquet文件的加载，实际使用内存中的静态数据
- 包含5个模拟问题和对应的答案、语料

```java
// 模拟queries.parquet数据
queries.put(1L, "What is the capital of China?");
queries.put(2L, "How does photosynthesis work?");
// ...更多硬编码数据

// 模拟corpus.parquet数据  
corpus.put(1L, "Beijing is the capital city of China...");
// ...更多硬编码数据
```

**影响**：评估功能只能使用这些预定义的测试数据，无法真正加载外部数据集

### 2. SessionServiceImpl - 流式续传功能
**位置**: `com.tencent.weknora.service.impl.SessionServiceImpl:579-580`

**问题代码**：
```java
// 这里应该实现实际的流式续传逻辑
// 暂时返回一个简单的响应
return Flux.just("data: {\"type\":\"continue\",\"message\":\"Stream continue not implemented yet\"}\n\n");
```

**影响**：无法真正恢复中断的流式响应

### 3. InitializationServiceImpl - 多模态测试
**位置**: `com.tencent.weknora.service.impl.InitializationServiceImpl:492-497`

**问题代码**：
```java
// 暂时返回模拟结果
Map<String, Object> testResultMap = new HashMap<>();
testResultMap.put("success", true);
testResultMap.put("partCount", partList.size());
testResultMap.put("message", "Multimodal test completed");
return Mono.just(Result.ok(testResultMap));
```

**影响**：多模态功能测试只返回模拟结果，未真正测试功能

## 二、待实现功能（TODOs）

### 1. LLM标题生成功能
**位置**: `SessionServiceImpl:285-289`

```java
// 这里应该调用LLM服务生成标题
// 暂时使用模拟生成的标题
String generatedTitle = messages.stream()
        .filter(msg -> "user".equals(msg.getRole()))
        .findFirst()
        .map(msg -> msg.getContent().substring(0, Math.min(msg.getContent().length(), 20)))
        .orElse("New Session");
return Mono.just(generatedTitle);
```

**问题**：标题生成功能没有真正调用LLM，只是简单截取用户消息的前20个字符

### 2. 嵌入模型测试
**位置**: `InitializationServiceImpl:326`

```java
String sample = "hello"; // 测试文本
```

**问题**：测试文本过于简单，应该使用更有代表性的测试样本

## 三、临时实现（Temporary Implementation）

### 1. 错误处理中的静态响应
**位置**: `com.tencent.weknora.common.ApiResponses`

```java
"message", "Not implemented"
```

**问题**：某些API返回"Not implemented"错误，表明功能尚未完成

### 2. 数据集服务的兜底处理
**位置**: `DatasetServiceImpl:179-184`

```java
// 模拟Go版本的行为 - 当前只支持默认数据集
if ("default".equals(datasetId) || "1".equals(datasetId)) {
    return Mono.just(defaultDataset);
} else {
    log.warn("Dataset not found: {}, returning default dataset", datasetId);
    return Mono.just(defaultDataset);  // 不管请求什么数据集，都返回默认的
}
```

**问题**：无论请求哪个数据集ID，都返回相同的默认数据集

## 四、需要改进的地方

### 1. 数据加载
- 需要实现真正的parquet文件读取功能
- 应该从文件系统或数据库加载评估数据集

### 2. 流式处理
- 完善流式响应的续传功能
- 实现断点续传机制

### 3. LLM集成
- 实现真正的LLM标题生成
- 完善多模态处理能力

### 4. 测试数据
- 使用更真实的测试数据替代硬编码
- 增加更多样的测试场景

## 五、与Go版本的对比

| 功能点 | Go版本状态 | Java版本状态 | 差异说明 |
|-------|-----------|------------|---------|
| 数据集加载 | ✅ 完整实现 | ⚠️ 模拟实现 | Java版使用硬编码数据 |
| 流式续传 | ✅ 完整实现 | ❌ 未实现 | Java版返回"not implemented" |
| LLM标题生成 | ✅ 调用真实LLM | ⚠️ 简单截取 | Java版只截取前20字符 |
| 多模态测试 | ✅ 真实测试 | ⚠️ 模拟返回 | Java版只返回模拟结果 |
| Parquet文件支持 | ✅ 支持 | ❌ 不支持 | Java版需要添加parquet依赖 |

## 六、建议优先级

### 高优先级（影响核心功能）
1. **实现真正的数据集加载** - 评估功能依赖此项
2. **完善LLM标题生成** - 影响用户体验
3. **实现流式续传** - 保证聊天连续性

### 中优先级（功能完整性）
1. **多模态功能测试** - 完善测试能力
2. **Parquet文件支持** - 与Go版本保持一致

### 低优先级（优化项）
1. **测试数据多样化** - 提升测试覆盖度
2. **错误信息优化** - 改进用户提示

## 七、技术债务评估

**当前技术债务**：
- 模拟代码约占 5-10% 的服务层代码
- 主要集中在评估和测试相关功能
- 核心业务功能（知识库、会话、聊天）基本完整

**建议**：
1. 分阶段替换模拟实现
2. 优先保证核心功能的完整性
3. 建立自动化测试确保重构不影响现有功能

