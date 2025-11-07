# syntax=docker/dockerfile:1.4
# 多阶段构建 - 第一阶段：构建
FROM maven:3.8-openjdk-17 AS builder

# 设置工作目录
WORKDIR /app

# 仅复制pom.xml以便充分利用缓存
COPY pom.xml .

# 预先下载依赖，使用BuildKit缓存加速后续构建
RUN --mount=type=cache,target=/root/.m2 mvn -B dependency:go-offline

# 复制源代码
COPY src ./src

# 下载依赖并构建可执行JAR
RUN --mount=type=cache,target=/root/.m2 mvn -B -DskipTests clean package spring-boot:repackage

# 第二阶段：运行
FROM openjdk:17-jdk-slim

# 安装必要的工具
RUN apt-get update && apt-get install -y \
    curl \
    && rm -rf /var/lib/apt/lists/*

# 设置工作目录
WORKDIR /app

# 从构建阶段复制jar文件
COPY --from=builder /app/target/weknora-java-*.jar app.jar

# 复制配置文件
COPY --from=builder /app/src/main/resources/application.yaml /app/config/application.yaml

# 创建数据目录
RUN mkdir -p /data/files /app/dataset/samples

# 暴露端口
EXPOSE 8080

# 健康检查
HEALTHCHECK --interval=30s --timeout=10s --retries=3 \
    CMD curl -f http://localhost:8080/api/v1/system/health || exit 1

# 设置JVM参数
ENV JAVA_OPTS="-Xmx2g -Xms512m -XX:+UseG1GC -XX:MaxGCPauseMillis=100"

# 启动命令
ENTRYPOINT ["sh", "-c", "java $JAVA_OPTS -jar app.jar --spring.config.location=classpath:/application.yaml,file:/app/config/application.yaml"]
