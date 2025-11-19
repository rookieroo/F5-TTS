#!/bin/bash
# 健康检查脚本

# 检查服务健康状态
check_service() {
    local service=$1
    local url=$2
    
    if curl -f -s -o /dev/null "$url"; then
        echo "✓ $service: 健康"
        return 0
    else
        echo "✗ $service: 不健康"
        return 1
    fi
}

echo "F5-TTS 服务健康检查"
echo "===================="
echo ""

# 检查 F5-TTS
check_service "F5-TTS" "http://localhost:7860"
f5tts_status=$?

# 检查 Nginx
check_service "Nginx" "http://localhost:8080/health"
nginx_status=$?

# 检查 GPU (如果有)
echo ""
echo "GPU 状态:"
if command -v nvidia-smi &> /dev/null; then
    nvidia-smi --query-gpu=utilization.gpu,memory.used,memory.total --format=csv,noheader,nounits | \
    awk '{printf "  GPU 使用率: %s%% | 显存: %s/%s MB\n", $1, $2, $3}'
else
    echo "  无 GPU 或未安装 NVIDIA 驱动"
fi

# 检查容器状态
echo ""
echo "容器状态:"
docker compose ps --format "table {{.Name}}\t{{.Status}}\t{{.Ports}}"

# 检查资源使用
echo ""
echo "资源使用:"
docker stats --no-stream --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}" \
    $(docker compose ps -q 2>/dev/null)

# 返回状态
echo ""
if [ $f5tts_status -eq 0 ] && [ $nginx_status -eq 0 ]; then
    echo "✓ 所有服务运行正常"
    exit 0
else
    echo "✗ 部分服务异常"
    exit 1
fi
