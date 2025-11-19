#!/bin/bash
set -e

echo "================================================"
echo "  F5-TTS Docker 部署脚本"
echo "================================================"
echo ""

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 检查必要的工具
check_requirements() {
    echo -e "${BLUE}检查系统要求...${NC}"
    
    if ! command -v docker &> /dev/null; then
        echo -e "${RED}错误: Docker 未安装${NC}"
        echo "请访问 https://docs.docker.com/get-docker/ 安装 Docker"
        exit 1
    fi
    
    if ! command -v docker compose &> /dev/null; then
        echo -e "${RED}错误: Docker Compose 未安装${NC}"
        echo "请访问 https://docs.docker.com/compose/install/ 安装 Docker Compose"
        exit 1
    fi
    
    # 检查 NVIDIA GPU (可选)
    if command -v nvidia-smi &> /dev/null; then
        echo -e "${GREEN}✓ 检测到 NVIDIA GPU${NC}"
        nvidia-smi --query-gpu=name --format=csv,noheader
    else
        echo -e "${YELLOW}⚠ 未检测到 NVIDIA GPU，将使用 CPU 模式${NC}"
    fi
    
    echo ""
}

# 生成密码文件
generate_htpasswd() {
    echo -e "${BLUE}生成认证密码文件...${NC}"
    
    if [ -f "nginx/.htpasswd" ]; then
        echo -e "${YELLOW}密码文件已存在，跳过生成${NC}"
        return
    fi
    
    # 从 .env 文件读取用户名和密码
    if [ -f ".env" ]; then
        source .env
        USERNAME=${ADMIN_USERNAME:-admin}
        PASSWORD=${ADMIN_PASSWORD:-changeme}
    else
        USERNAME="admin"
        PASSWORD="changeme"
        echo -e "${YELLOW}警告: 未找到 .env 文件，使用默认凭证${NC}"
    fi
    
    # 使用 docker 临时容器生成 htpasswd
    echo -e "${GREEN}生成密码文件 (用户: ${USERNAME})${NC}"
    docker run --rm httpd:alpine htpasswd -nbB "$USERNAME" "$PASSWORD" > nginx/.htpasswd
    
    echo -e "${GREEN}✓ 密码文件生成完成${NC}"
    echo ""
}

# 配置环境变量
setup_env() {
    echo -e "${BLUE}配置环境变量...${NC}"
    
    if [ ! -f ".env" ]; then
        echo -e "${YELLOW}创建 .env 文件...${NC}"
        cp .env.example .env
        
        echo ""
        echo -e "${YELLOW}请编辑 .env 文件，配置以下内容:${NC}"
        echo "  1. ADMIN_USERNAME 和 ADMIN_PASSWORD (管理员账号)"
        echo "  2. CLOUDFLARE_TUNNEL_TOKEN (Cloudflare Tunnel Token)"
        echo "  3. CLOUDFLARE_DOMAIN (你的域名)"
        echo ""
        echo -e "${RED}按 Enter 继续编辑 .env 文件...${NC}"
        read -r
        
        # 尝试打开编辑器
        if command -v nano &> /dev/null; then
            nano .env
        elif command -v vim &> /dev/null; then
            vim .env
        else
            echo -e "${YELLOW}请手动编辑 .env 文件${NC}"
        fi
    else
        echo -e "${GREEN}✓ .env 文件已存在${NC}"
    fi
    
    echo ""
}

# 配置 Cloudflare Tunnel
setup_cloudflare() {
    echo -e "${BLUE}配置 Cloudflare Tunnel...${NC}"
    
    if [ ! -f "cloudflared/config.yml" ]; then
        echo -e "${YELLOW}创建 Cloudflare Tunnel 配置...${NC}"
        cp cloudflared/config.yml.example cloudflared/config.yml
        
        echo ""
        echo -e "${YELLOW}Cloudflare Tunnel 配置提示:${NC}"
        echo "  1. 访问 https://one.dash.cloudflare.com/"
        echo "  2. 创建一个新的 Tunnel"
        echo "  3. 复制 Tunnel Token"
        echo "  4. 将 Token 粘贴到 .env 文件的 CLOUDFLARE_TUNNEL_TOKEN"
        echo ""
        echo "或者在 docker-compose.yml 中直接使用 TUNNEL_TOKEN 环境变量"
        echo ""
    else
        echo -e "${GREEN}✓ Cloudflare 配置已存在${NC}"
    fi
    
    echo ""
}

# 构建并启动服务
start_services() {
    echo -e "${BLUE}构建并启动服务...${NC}"
    
    # 构建镜像
    echo "构建 F5-TTS 镜像..."
    docker compose build
    
    # 启动服务
    echo "启动服务..."
    docker compose up -d
    
    echo ""
    echo -e "${GREEN}✓ 服务启动成功!${NC}"
    echo ""
}

# 显示服务状态
show_status() {
    echo -e "${BLUE}服务状态:${NC}"
    docker compose ps
    echo ""
    
    echo -e "${BLUE}访问信息:${NC}"
    echo "  本地访问 (需要认证): http://localhost:8080"
    
    if [ -f ".env" ]; then
        source .env
        if [ -n "$CLOUDFLARE_DOMAIN" ]; then
            echo "  公网访问 (通过 Cloudflare): https://$CLOUDFLARE_DOMAIN"
        fi
    fi
    
    echo ""
    echo -e "${BLUE}查看日志:${NC}"
    echo "  docker compose logs -f f5-tts"
    echo "  docker compose logs -f nginx-auth"
    echo "  docker compose logs -f cloudflared"
    echo ""
    
    echo -e "${BLUE}停止服务:${NC}"
    echo "  docker compose down"
    echo ""
}

# 主函数
main() {
    cd "$(dirname "$0")"
    
    check_requirements
    setup_env
    generate_htpasswd
    setup_cloudflare
    start_services
    show_status
    
    echo -e "${GREEN}================================================${NC}"
    echo -e "${GREEN}  F5-TTS 部署完成!${NC}"
    echo -e "${GREEN}================================================${NC}"
}

# 执行主函数
main
