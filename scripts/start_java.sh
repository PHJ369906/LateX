#!/bin/bash
# Java版WeKnora启动脚本

# 设置颜色
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

# 获取脚本目录
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$( cd "$SCRIPT_DIR/.." && pwd )"

echo -e "${GREEN}WeKnora Java版启动脚本${NC}"
echo "================================"

# 选择可用的 Docker Compose 命令
DOCKER_COMPOSE_BIN=""
DOCKER_COMPOSE_SUBCMD=""

detect_compose_cmd() {
    if docker compose version &> /dev/null; then
        DOCKER_COMPOSE_BIN="docker"
        DOCKER_COMPOSE_SUBCMD="compose"
        return 0
    fi

    if command -v docker-compose &> /dev/null; then
        if docker-compose version &> /dev/null; then
            DOCKER_COMPOSE_BIN="docker-compose"
            DOCKER_COMPOSE_SUBCMD=""
            return 0
        fi
    fi

    return 1
}

run_compose() {
    local args=("$@")
    if [ -n "$DOCKER_COMPOSE_SUBCMD" ]; then
        "$DOCKER_COMPOSE_BIN" "$DOCKER_COMPOSE_SUBCMD" "${args[@]}"
    else
        "$DOCKER_COMPOSE_BIN" "${args[@]}"
    fi
}

# 确认 docker compose 可用
if ! detect_compose_cmd; then
    echo -e "${RED}[ERROR]${NC} 未检测到 docker compose，请安装 docker compose 插件或 docker-compose。"
    exit 1
fi

# 检查参数
ACTION=${1:-start}

case $ACTION in
  start)
    echo -e "${BLUE}[INFO]${NC} 启动Java版WeKnora服务..."
    
    # 检查.env文件
    if [ ! -f "$PROJECT_ROOT/.env" ]; then
        echo -e "${YELLOW}[WARN]${NC} .env文件不存在，创建默认配置..."
        cat > "$PROJECT_ROOT/.env" << EOF
# 数据库配置
DB_USER=postgres
DB_PASSWORD=postgres123!@#
DB_NAME=WeKnora

# MinIO配置  
MINIO_ACCESS_KEY_ID=minioadmin
MINIO_SECRET_ACCESS_KEY=minioadmin
MINIO_BUCKET_NAME=weknora

# LLM配置
LLM_PROVIDER=ollama
OLLAMA_BASE_URL=http://host.docker.internal:11434
EOF
    fi
    
    cd "$PROJECT_ROOT"
    
    # 使用Java版docker-compose启动
    run_compose -f docker-compose.java.yml up -d --build
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}[SUCCESS]${NC} Java版服务启动成功！"
        echo ""
        echo "服务地址："
        echo "  - API接口: http://localhost:8080"
        echo "  - 前端界面: http://localhost:3000"
        echo "  - MinIO控制台: http://localhost:9001"
        echo "  - PostgreSQL: localhost:5432"
        echo ""
        echo "查看日志: docker-compose -f docker-compose.java.yml logs -f weknora-java"
    else
        echo -e "${RED}[ERROR]${NC} 服务启动失败"
        exit 1
    fi
    ;;
    
  stop)
    echo -e "${BLUE}[INFO]${NC} 停止Java版WeKnora服务..."
    cd "$PROJECT_ROOT"
    run_compose -f docker-compose.java.yml down
    echo -e "${GREEN}[SUCCESS]${NC} 服务已停止"
    ;;
    
  restart)
    echo -e "${BLUE}[INFO]${NC} 重启Java版WeKnora服务..."
    $0 stop
    sleep 2
    $0 start
    ;;
    
  logs)
    cd "$PROJECT_ROOT"
    run_compose -f docker-compose.java.yml logs -f weknora-java
    ;;
    
  status)
    cd "$PROJECT_ROOT"
    echo -e "${BLUE}[INFO]${NC} 服务状态："
    run_compose -f docker-compose.java.yml ps
    ;;
    
  build)
    echo -e "${BLUE}[INFO]${NC} 构建Java版镜像..."
    cd "$PROJECT_ROOT/weknora-java"
    docker build -t weknora-java:latest .
    echo -e "${GREEN}[SUCCESS]${NC} 镜像构建完成"
    ;;
    
  *)
    echo "用法: $0 {start|stop|restart|logs|status|build}"
    echo ""
    echo "命令说明："
    echo "  start   - 启动Java版服务"
    echo "  stop    - 停止服务"
    echo "  restart - 重启服务"
    echo "  logs    - 查看服务日志"
    echo "  status  - 查看服务状态"
    echo "  build   - 构建Docker镜像"
    exit 1
    ;;
esac
