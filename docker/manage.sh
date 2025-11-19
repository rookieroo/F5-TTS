#!/bin/bash
set -e

echo "================================================"
echo "  F5-TTS 管理工具"
echo "================================================"
echo ""

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# 显示菜单
show_menu() {
    echo -e "${BLUE}请选择操作:${NC}"
    echo "  1) 启动服务"
    echo "  2) 停止服务"
    echo "  3) 重启服务"
    echo "  4) 查看状态"
    echo "  5) 查看日志"
    echo "  6) 更新服务"
    echo "  7) 修改密码"
    echo "  8) 备份数据"
    echo "  9) 恢复数据"
    echo "  10) 清理缓存"
    echo "  0) 退出"
    echo ""
    echo -n "请输入选项 [0-10]: "
}

# 启动服务
start_services() {
    echo -e "${BLUE}启动服务...${NC}"
    docker compose up -d
    echo -e "${GREEN}✓ 服务已启动${NC}"
    show_status
}

# 停止服务
stop_services() {
    echo -e "${BLUE}停止服务...${NC}"
    docker compose down
    echo -e "${GREEN}✓ 服务已停止${NC}"
}

# 重启服务
restart_services() {
    echo -e "${BLUE}重启服务...${NC}"
    docker compose restart
    echo -e "${GREEN}✓ 服务已重启${NC}"
    show_status
}

# 查看状态
show_status() {
    echo -e "${BLUE}服务状态:${NC}"
    docker compose ps
    echo ""
    
    # 显示资源使用
    echo -e "${BLUE}资源使用:${NC}"
    docker stats --no-stream --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}" \
        $(docker compose ps -q 2>/dev/null)
    echo ""
}

# 查看日志
view_logs() {
    echo -e "${BLUE}选择要查看的服务日志:${NC}"
    echo "  1) F5-TTS"
    echo "  2) Nginx"
    echo "  3) Cloudflared"
    echo "  4) 所有服务"
    echo ""
    echo -n "请输入选项 [1-4]: "
    read -r choice
    
    case $choice in
        1)
            docker compose logs -f f5-tts
            ;;
        2)
            docker compose logs -f nginx-auth
            ;;
        3)
            docker compose logs -f cloudflared
            ;;
        4)
            docker compose logs -f
            ;;
        *)
            echo -e "${RED}无效选项${NC}"
            ;;
    esac
}

# 更新服务
update_services() {
    echo -e "${BLUE}更新服务...${NC}"
    
    # 拉取最新代码
    echo "拉取最新代码..."
    cd .. && git pull && cd docker
    
    # 重新构建镜像
    echo "重新构建镜像..."
    docker compose build --no-cache
    
    # 重启服务
    echo "重启服务..."
    docker compose up -d
    
    echo -e "${GREEN}✓ 服务已更新${NC}"
}

# 修改密码
change_password() {
    echo -e "${BLUE}修改管理员密码${NC}"
    echo ""
    echo -n "请输入新密码: "
    read -s new_password
    echo ""
    echo -n "确认新密码: "
    read -s confirm_password
    echo ""
    
    if [ "$new_password" != "$confirm_password" ]; then
        echo -e "${RED}错误: 两次输入的密码不一致${NC}"
        return 1
    fi
    
    if [ ${#new_password} -lt 8 ]; then
        echo -e "${RED}错误: 密码长度至少 8 位${NC}"
        return 1
    fi
    
    # 更新 .htpasswd
    echo "更新密码文件..."
    source .env
    username=${ADMIN_USERNAME:-admin}
    docker run --rm httpd:alpine htpasswd -nbB "$username" "$new_password" > nginx/.htpasswd
    
    # 更新 .env 文件
    sed -i.bak "s/ADMIN_PASSWORD=.*/ADMIN_PASSWORD=$new_password/" .env
    
    # 重启 Nginx
    docker compose restart nginx-auth
    
    echo -e "${GREEN}✓ 密码已更新${NC}"
}

# 备份数据
backup_data() {
    echo -e "${BLUE}备份数据...${NC}"
    
    backup_dir="backups/backup_$(date +%Y%m%d_%H%M%S)"
    mkdir -p "$backup_dir"
    
    # 备份配置
    echo "备份配置文件..."
    cp .env "$backup_dir/"
    cp nginx/.htpasswd "$backup_dir/" 2>/dev/null || true
    
    # 备份 Docker Volume
    echo "备份模型缓存..."
    docker run --rm \
        -v f5-tts-cache:/data \
        -v "$(pwd)/$backup_dir":/backup \
        alpine tar czf /backup/cache.tar.gz /data
    
    # 备份输出文件
    if [ -d "../outputs" ]; then
        echo "备份输出文件..."
        tar czf "$backup_dir/outputs.tar.gz" -C .. outputs
    fi
    
    # 备份数据文件
    if [ -d "../data" ]; then
        echo "备份数据文件..."
        tar czf "$backup_dir/data.tar.gz" -C .. data
    fi
    
    echo -e "${GREEN}✓ 备份完成: $backup_dir${NC}"
}

# 恢复数据
restore_data() {
    echo -e "${BLUE}恢复数据${NC}"
    echo ""
    
    if [ ! -d "backups" ]; then
        echo -e "${RED}错误: 未找到备份目录${NC}"
        return 1
    fi
    
    echo "可用的备份:"
    ls -1 backups/ | nl
    echo ""
    echo -n "请选择要恢复的备份编号: "
    read -r backup_num
    
    backup_dir=$(ls -1 backups/ | sed -n "${backup_num}p")
    
    if [ -z "$backup_dir" ] || [ ! -d "backups/$backup_dir" ]; then
        echo -e "${RED}错误: 无效的备份编号${NC}"
        return 1
    fi
    
    echo -e "${YELLOW}警告: 恢复操作会覆盖当前数据${NC}"
    echo -n "确认恢复? [y/N]: "
    read -r confirm
    
    if [ "$confirm" != "y" ] && [ "$confirm" != "Y" ]; then
        echo "取消恢复"
        return 0
    fi
    
    # 停止服务
    echo "停止服务..."
    docker compose down
    
    # 恢复配置
    echo "恢复配置..."
    cp "backups/$backup_dir/.env" .env
    cp "backups/$backup_dir/.htpasswd" nginx/ 2>/dev/null || true
    
    # 恢复缓存
    if [ -f "backups/$backup_dir/cache.tar.gz" ]; then
        echo "恢复模型缓存..."
        docker run --rm \
            -v f5-tts-cache:/data \
            -v "$(pwd)/backups/$backup_dir":/backup \
            alpine sh -c "cd / && tar xzf /backup/cache.tar.gz"
    fi
    
    # 恢复输出
    if [ -f "backups/$backup_dir/outputs.tar.gz" ]; then
        echo "恢复输出文件..."
        tar xzf "backups/$backup_dir/outputs.tar.gz" -C ..
    fi
    
    # 恢复数据
    if [ -f "backups/$backup_dir/data.tar.gz" ]; then
        echo "恢复数据文件..."
        tar xzf "backups/$backup_dir/data.tar.gz" -C ..
    fi
    
    # 启动服务
    echo "启动服务..."
    docker compose up -d
    
    echo -e "${GREEN}✓ 恢复完成${NC}"
}

# 清理缓存
clean_cache() {
    echo -e "${BLUE}清理缓存${NC}"
    echo ""
    echo -e "${YELLOW}警告: 此操作会删除所有缓存的模型，下次启动需要重新下载${NC}"
    echo -n "确认清理? [y/N]: "
    read -r confirm
    
    if [ "$confirm" != "y" ] && [ "$confirm" != "Y" ]; then
        echo "取消清理"
        return 0
    fi
    
    # 停止服务
    docker compose down
    
    # 删除 Volume
    docker volume rm f5-tts-cache 2>/dev/null || true
    
    # 清理 Docker 缓存
    docker system prune -f
    
    echo -e "${GREEN}✓ 缓存已清理${NC}"
}

# 主循环
main() {
    cd "$(dirname "$0")"
    
    while true; do
        echo ""
        show_menu
        read -r choice
        echo ""
        
        case $choice in
            1)
                start_services
                ;;
            2)
                stop_services
                ;;
            3)
                restart_services
                ;;
            4)
                show_status
                ;;
            5)
                view_logs
                ;;
            6)
                update_services
                ;;
            7)
                change_password
                ;;
            8)
                backup_data
                ;;
            9)
                restore_data
                ;;
            10)
                clean_cache
                ;;
            0)
                echo -e "${GREEN}再见!${NC}"
                exit 0
                ;;
            *)
                echo -e "${RED}无效选项，请重试${NC}"
                ;;
        esac
        
        echo ""
        echo -n "按 Enter 键继续..."
        read -r
        clear
    done
}

# 执行主函数
main
