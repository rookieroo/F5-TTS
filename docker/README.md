# F5-TTS Docker 部署文档

## 📋 项目概述

本项目提供了一个完整的 F5-TTS Docker 部署方案，包含以下功能：

- 🎙️ **F5-TTS 语音合成服务** - 基于 Gradio 的 Web 界面
- 🔒 **管理员身份认证** - HTTP Basic Auth 保护
- 🌐 **Cloudflare Tunnel** - 安全地暴露到公网
- 🐳 **Docker Compose** - 一键部署所有服务

## 📁 项目结构

```
docker/
├── docker-compose.yml           # Docker Compose 配置文件
├── deploy.sh                    # 一键部署脚本
├── .env.example                 # 环境变量模板
├── auth_wrapper.py              # Gradio 认证包装器
├── nginx/
│   ├── nginx.conf              # Nginx 反向代理配置
│   └── .htpasswd.example       # 密码文件示例
└── cloudflared/
    └── config.yml.example      # Cloudflare Tunnel 配置示例
```

## 🚀 快速开始

### 1. 系统要求

- **操作系统**: Linux / macOS / Windows (WSL2)
- **Docker**: >= 20.10
- **Docker Compose**: >= 2.0
- **GPU** (推荐): NVIDIA GPU + NVIDIA Container Toolkit
- **内存**: >= 8GB RAM
- **存储**: >= 20GB 可用空间

### 2. 安装 Docker 和 NVIDIA Container Toolkit

#### Ubuntu/Debian:
```bash
# 安装 Docker
curl -fsSL https://get.docker.com | sh
sudo usermod -aG docker $USER

# 安装 NVIDIA Container Toolkit (如果有 GPU)
distribution=$(. /etc/os-release;echo $ID$VERSION_ID)
curl -s -L https://nvidia.github.io/nvidia-docker/gpgkey | sudo apt-key add -
curl -s -L https://nvidia.github.io/nvidia-docker/$distribution/nvidia-docker.list | \
  sudo tee /etc/apt/sources.list.d/nvidia-docker.list
sudo apt-get update
sudo apt-get install -y nvidia-container-toolkit
sudo systemctl restart docker
```

#### macOS:
```bash
# 安装 Docker Desktop
brew install --cask docker

# 注意: macOS 上无法使用 NVIDIA GPU，将使用 CPU 模式
```

### 3. 配置部署

```bash
# 进入 docker 目录
cd /Users/apple/Desktop/code/web/F5-TTS/docker

# 复制环境变量模板
cp .env.example .env

# 编辑 .env 文件，配置管理员账号和 Cloudflare Token
nano .env
```

#### `.env` 文件配置说明:

```bash
# 管理员账号 (必填)
ADMIN_USERNAME=admin
ADMIN_PASSWORD=your_secure_password_here

# Cloudflare Tunnel Token (必填，用于公网访问)
CLOUDFLARE_TUNNEL_TOKEN=your_tunnel_token_here

# 域名 (必填)
CLOUDFLARE_DOMAIN=f5-tts.yourdomain.com
```

### 4. 获取 Cloudflare Tunnel Token

1. 访问 [Cloudflare Zero Trust Dashboard](https://one.dash.cloudflare.com/)
2. 进入 **Access** → **Tunnels**
3. 点击 **Create a tunnel**
4. 选择 **Cloudflared** 类型
5. 输入 Tunnel 名称 (例如: `f5-tts`)
6. 保存并复制生成的 **Tunnel Token**
7. 配置公共主机名:
   - **Subdomain**: `f5-tts` (或其他子域名)
   - **Domain**: 选择你的域名
   - **Service**: `http://nginx-auth:80`

### 5. 一键部署

```bash
# 给脚本添加执行权限
chmod +x deploy.sh

# 运行部署脚本
./deploy.sh
```

部署脚本会自动完成：
- ✅ 检查系统要求
- ✅ 生成密码文件
- ✅ 构建 Docker 镜像
- ✅ 启动所有服务
- ✅ 显示访问信息

## 🔐 身份认证

### 双层认证机制

本部署方案提供了双层认证保护：

1. **Nginx HTTP Basic Auth** (第一层)
   - 在反向代理层面进行认证
   - 保护所有 HTTP 请求
   - 使用 `.htpasswd` 文件存储加密密码

2. **Gradio 内置认证** (第二层，可选)
   - 在应用层面进行认证
   - 通过 `auth_wrapper.py` 实现
   - 可通过环境变量 `ENABLE_AUTH` 开启/关闭

### 修改管理员密码

```bash
# 方法 1: 重新生成 .htpasswd 文件
docker run --rm httpd:alpine htpasswd -nbB admin new_password > nginx/.htpasswd

# 方法 2: 使用 Python
python3 -c "import bcrypt; print('admin:' + bcrypt.hashpw(b'new_password', bcrypt.gensalt()).decode())" > nginx/.htpasswd

# 重启 nginx 服务
docker compose restart nginx-auth
```

## 📊 服务管理

### 查看服务状态

```bash
docker compose ps
```

### 查看日志

```bash
# 查看所有服务日志
docker compose logs -f

# 查看特定服务日志
docker compose logs -f f5-tts
docker compose logs -f nginx-auth
docker compose logs -f cloudflared
```

### 停止服务

```bash
docker compose down
```

### 重启服务

```bash
docker compose restart
```

### 更新服务

```bash
# 重新构建镜像
docker compose build --no-cache

# 重启服务
docker compose up -d
```

## 🌐 访问服务

### 本地访问

- **URL**: http://localhost:8080
- **认证**: 需要输入管理员用户名和密码

### 公网访问 (通过 Cloudflare Tunnel)

- **URL**: https://f5-tts.yourdomain.com
- **认证**: 需要输入管理员用户名和密码
- **优势**:
  - 自动 HTTPS (Cloudflare SSL)
  - DDoS 保护
  - 无需开放服务器端口
  - 隐藏源服务器 IP

## 🎯 API 使用

F5-TTS 提供了 RESTful API，可以通过编程方式调用:

### API 端点

```bash
# 基础 URL
http://localhost:8080/api/

# 或公网访问
https://f5-tts.yourdomain.com/api/
```

### Python 示例

```python
import requests
from requests.auth import HTTPBasicAuth

# 认证信息
auth = HTTPBasicAuth('admin', 'your_password')

# API 调用
url = "http://localhost:8080/api/predict"
files = {
    'reference_audio': open('ref_audio.wav', 'rb'),
}
data = {
    'reference_text': 'This is reference text',
    'generation_text': 'This is the text to generate',
}

response = requests.post(url, files=files, data=data, auth=auth)
print(response.json())
```

### cURL 示例

```bash
curl -X POST \
  -u admin:your_password \
  -F "reference_audio=@ref_audio.wav" \
  -F "reference_text=This is reference text" \
  -F "generation_text=This is the text to generate" \
  http://localhost:8080/api/predict
```

## 🔧 故障排查

### 1. GPU 未检测到

```bash
# 检查 NVIDIA 驱动
nvidia-smi

# 检查 Docker GPU 支持
docker run --rm --gpus all nvidia/cuda:12.4.0-base-ubuntu22.04 nvidia-smi

# 如果失败，重新安装 NVIDIA Container Toolkit
```

### 2. 容器启动失败

```bash
# 查看详细日志
docker compose logs f5-tts

# 检查端口占用
lsof -i :7860
lsof -i :8080

# 清理并重启
docker compose down -v
docker compose up -d
```

### 3. Cloudflare Tunnel 连接失败

```bash
# 检查 Token 是否正确
docker compose logs cloudflared

# 确认域名解析
nslookup f5-tts.yourdomain.com

# 重启 Tunnel
docker compose restart cloudflared
```

### 4. 认证失败

```bash
# 检查密码文件
cat nginx/.htpasswd

# 重新生成密码文件
docker run --rm httpd:alpine htpasswd -nbB admin your_password > nginx/.htpasswd

# 重启 Nginx
docker compose restart nginx-auth
```

## 🔒 安全建议

1. **修改默认密码**: 务必修改 `.env` 中的 `ADMIN_PASSWORD`
2. **使用强密码**: 至少 16 位，包含大小写字母、数字和特殊字符
3. **定期更新**: 定期更新 Docker 镜像和依赖
4. **限制访问**: 使用 Cloudflare Access 添加额外的访问控制
5. **监控日志**: 定期检查访问日志，发现异常访问
6. **备份数据**: 定期备份模型和生成的音频文件

## 📦 数据持久化

容器使用 Docker Volume 持久化数据：

- `f5-tts-cache`: Hugging Face 模型缓存
- `./outputs`: 生成的音频文件
- `./data`: 训练数据和微调模型

### 备份数据

```bash
# 备份 Volume
docker run --rm -v f5-tts-cache:/data -v $(pwd):/backup alpine tar czf /backup/f5-tts-cache-backup.tar.gz /data

# 备份输出文件
tar czf outputs-backup.tar.gz outputs/
```

## 🎨 自定义配置

### 修改 Gradio 主题

编辑 `docker-compose.yml`，添加环境变量：

```yaml
environment:
  - GRADIO_THEME=soft  # 可选: default, soft, glass, monochrome
```

### 修改资源限制

编辑 `docker-compose.yml`，添加资源限制：

```yaml
deploy:
  resources:
    limits:
      cpus: '4'
      memory: 16G
    reservations:
      memory: 8G
```

## 📞 支持与反馈

如有问题或建议，请：

1. 查看 [F5-TTS 官方文档](https://github.com/SWivid/F5-TTS)
2. 提交 [Issue](https://github.com/SWivid/F5-TTS/issues)
3. 加入社区讨论

## 📄 许可证

本项目遵循 MIT 许可证。详见 [LICENSE](../LICENSE) 文件。
