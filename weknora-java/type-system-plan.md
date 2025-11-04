# WeKnora Java 类型系统统一计划

## 问题分析

当前项目存在以下类型不一致问题：

1. **Controller返回类型混乱**：
   - 部分Controller使用 `Mono<Map<String, Serializable>>`
   - 部分Service和其他地方使用 `Map<String, Object>`
   - ApiResponse工具类使用 `Map<String, Object>`

2. **响应工具类不统一**：
   - ApiResponse 使用 `Map<String, Object>`
   - ResponseUtils 使用 `Map<String, Serializable>`
   - Result 类使用泛型

3. **Domain类Serializable缺失**：
   - 6个domain类未实现Serializable

## 修复计划

### 阶段1：统一所有响应工具类 (30分钟)
1. 修复 ApiResponse.java - 将所有 `Map<String, Object>` 改为 `Map<String, Serializable>`
2. 检查并修复所有受影响的Service实现类

### 阶段2：为domain类添加Serializable (15分钟)
1. RefreshToken.java
2. AuthToken.java
3. EvalQrel.java
4. QAPair.java
5. EvalDataset.java
6. EvalQuery.java

### 阶段3：修复所有Controller类型不一致 (45分钟)
1. 检查所有Controller确保使用 `Mono<Map<String, Serializable>>`
2. 修复所有类型转换问题
3. 确保所有方法引用正确

### 阶段4：修复Service层类型问题 (30分钟)
1. 检查所有Service实现
2. 修复Map类型不一致
3. 确保所有返回值正确

### 阶段5：验证和测试 (15分钟)
1. 编译检查
2. 确保无警告
3. 验证类型一致性

## 预期结果

- 整个项目使用一致的 `Map<String, Serializable>` 类型
- 所有domain类实现Serializable
- 消除所有编译错误和类型警告
- 保持业务逻辑不变