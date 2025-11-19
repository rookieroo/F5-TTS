# 🚀 F5-TTS 快速部署指南

## 一、系统要求

- Docker + Docker Compose
- NVIDIA GPU (推荐，可选)
- 8GB+ RAM
- 20GB+ 存储空间

## 二、快速部署 (3 分钟)

### 1. 进入 docker 目录

```bash
cd /Users/apple/Desktop/code/web/F5-TTS/docker
```

### 2. 配置环境变量

```bash
# 复制配置模板
cp .env.example .env

# 编辑配置 (修改密码和 Cloudflare Token)
nano .env
```

**必须修改的配置:**

```bash
# 管理员账号
ADMIN_USERNAME=admin
ADMIN_PASSWORD=your_secure_password  # ⚠️ 必须修改

# Cloudflare Tunnel Token (用于公网访问)
CLOUDFLARE_TUNNEL_TOKEN=your_token   # ⚠️ 必须配置

# 域名
CLOUDFLARE_DOMAIN=f5-tts.yourdomain.com
```

### 3. 一键部署

```bash
# 给脚本添加执行权限
chmod +x deploy.sh manage.sh

# 运行部署
./deploy.sh
```

### 4. 访问服务

- **本地**: http://localhost:8080
- **公网**: https://f5-tts.yourdomain.com

**登录凭证**: 使用 `.env` 中配置的 `ADMIN_USERNAME` 和 `ADMIN_PASSWORD`

## 三、Cloudflare Tunnel 设置

### 获取 Tunnel Token:

1. 访问: https://one.dash.cloudflare.com/
2. 进入 **Access** → **Tunnels**
3. 点击 **Create a tunnel** → 输入名称 (如: `f5-tts`)
4. 选择 **Cloudflared** 类型
5. 复制生成的 **Token**
6. 粘贴到 `.env` 文件的 `CLOUDFLARE_TUNNEL_TOKEN`

### 配置公共主机名:

在 Tunnel 设置页面，添加：

- **Subdomain**: `f5-tts`
- **Domain**: 你的域名
- **Service**: `http://nginx-auth:80`

## 四、常用命令

### 使用管理工具 (推荐):

```bash
./manage.sh
```

提供交互式菜单，包含所有常用操作。

### 手动命令:

```bash
# 查看状态
docker compose ps

# 查看日志
docker compose logs -f

# 停止服务
docker compose down

# 重启服务
docker compose restart

# 更新服务
docker compose pull
docker compose up -d
```

## 五、修改密码

```bash
# 方法 1: 使用管理工具
./manage.sh  # 选择 "7) 修改密码"

# 方法 2: 手动修改
docker run --rm httpd:alpine htpasswd -nbB admin new_password > nginx/.htpasswd
docker compose restart nginx-auth
```

## 六、故障排查

### GPU 未检测到?

```bash
# 检查 NVIDIA 驱动
nvidia-smi

# 检查 Docker GPU 支持
docker run --rm --gpus all nvidia/cuda:12.4.0-base-ubuntu22.04 nvidia-smi
```

### 端口冲突?

```bash
# 检查端口占用
lsof -i :8080
lsof -i :7860

# 修改端口 (编辑 docker-compose.yml)
```

### 认证失败?

```bash
# 检查密码文件
cat nginx/.htpasswd

# 重新生成
./manage.sh  # 选择 "7) 修改密码"
```

### Cloudflare 连接失败?

```bash
# 查看日志
docker compose logs cloudflared

# 检查 Token
cat .env | grep CLOUDFLARE_TUNNEL_TOKEN
```

## 七、备份与恢复

```bash
# 备份数据
./manage.sh  # 选择 "8) 备份数据"

# 恢复数据
./manage.sh  # 选择 "9) 恢复数据"
```

## 八、性能优化

### GPU 加速:

确保安装了 NVIDIA Container Toolkit:

```bash
# Ubuntu/Debian
distribution=$(. /etc/os-release;echo $ID$VERSION_ID)
curl -s -L https://nvidia.github.io/nvidia-docker/gpgkey | sudo apt-key add -
curl -s -L https://nvidia.github.io/nvidia-docker/$distribution/nvidia-docker.list | \
  sudo tee /etc/apt/sources.list.d/nvidia-docker.list
sudo apt-get update
sudo apt-get install -y nvidia-container-toolkit
sudo systemctl restart docker
```

### 资源限制:

编辑 `docker-compose.yml`，添加资源限制:

```yaml
deploy:
  resources:
    limits:
      cpus: '4'
      memory: 16G
```

## 九、安全建议

- ✅ 使用强密码 (16+ 字符)
- ✅ 定期更新服务
- ✅ 监控访问日志
- ✅ 使用 Cloudflare Access 添加额外保护
- ✅ 定期备份数据

## 十、API 使用示例

### Python:

```python
import requests
from requests.auth import HTTPBasicAuth

auth = HTTPBasicAuth('admin', 'your_password')
url = "http://localhost:8080/api/predict"

files = {'reference_audio': open('ref.wav', 'rb')}
data = {
    'reference_text': 'Reference text',
    'generation_text': 'Text to generate'
}

response = requests.post(url, files=files, data=data, auth=auth)
print(response.json())
```

### cURL:

```bash
curl -u admin:password \
  -F "reference_audio=@ref.wav" \
  -F "reference_text=Reference text" \
  -F "generation_text=Text to generate" \
  http://localhost:8080/api/predict
```

## 📞 获取帮助

- 📖 完整文档: [README.md](./README.md)
- 🐛 问题反馈: https://github.com/SWivid/F5-TTS/issues
- 💬 社区讨论: https://github.com/SWivid/F5-TTS/discussions
