#!/bin/bash
# F5-TTS Docker 一键卸载脚本

set -e

echo "================================================"
echo "  F5-TTS Docker 卸载"
echo "================================================"
echo ""

RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
NC='\033[0m'

echo -e "${YELLOW}警告: 此操作将删除以下内容:${NC}"
echo "  - 所有 Docker 容器"
echo "  - 所有 Docker 镜像"
echo "  - 所有 Docker Volume (包括模型缓存)"
echo "  - 配置文件 (.env, .htpasswd)"
echo ""
echo -e "${RED}此操作不可恢复!${NC}"
echo ""
echo -n "确认卸载? [y/N]: "
read -r confirm

if [ "$confirm" != "y" ] && [ "$confirm" != "Y" ]; then
    echo "取消卸载"
    exit 0
fi

cd "$(dirname "$0")"

# 询问是否备份
echo ""
echo -n "是否在卸载前备份数据? [Y/n]: "
read -r backup_confirm

if [ "$backup_confirm" != "n" ] && [ "$backup_confirm" != "N" ]; then
    echo -e "${GREEN}执行备份...${NC}"
    ./manage.sh <<< "8"  # 自动选择备份选项
    echo -e "${GREEN}✓ 备份完成${NC}"
fi

# 停止并删除容器
echo ""
echo -e "${YELLOW}停止并删除容器...${NC}"
docker compose down -v

# 删除镜像
echo -e "${YELLOW}删除镜像...${NC}"
docker rmi $(docker images | grep f5-tts | awk '{print $3}') 2>/dev/null || true

# 删除配置文件
echo -e "${YELLOW}删除配置文件...${NC}"
rm -f .env nginx/.htpasswd

# 询问是否删除备份
echo ""
echo -n "是否删除备份文件? [y/N]: "
read -r delete_backup

if [ "$delete_backup" == "y" ] || [ "$delete_backup" == "Y" ]; then
    rm -rf backups/
    echo -e "${GREEN}✓ 备份已删除${NC}"
fi

# 清理 Docker 系统
echo ""
echo -n "是否清理 Docker 系统缓存? [y/N]: "
read -r clean_system

if [ "$clean_system" == "y" ] || [ "$clean_system" == "Y" ]; then
    docker system prune -af --volumes
    echo -e "${GREEN}✓ Docker 系统已清理${NC}"
fi

echo ""
echo -e "${GREEN}================================================${NC}"
echo -e "${GREEN}  F5-TTS 已完全卸载${NC}"
echo -e "${GREEN}================================================${NC}"
