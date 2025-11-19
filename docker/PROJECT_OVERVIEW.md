# 📦 F5-TTS Docker 部署项目总览

## 项目完成 ✅

本项目已成功创建了一个完整的 F5-TTS Docker 部署方案，包含以下特性：

### ✨ 核心功能

1. **F5-TTS 语音合成服务**
   - 基于 PyTorch 和 CUDA 的 GPU 加速
   - Gradio Web UI 界面
   - RESTful API 支持
   - 模型自动下载和缓存

2. **双层身份认证**
   - Nginx HTTP Basic Auth（第一层）
   - Gradio 内置认证（第二层，可选）
   - 管理员权限控制

3. **Cloudflare Tunnel 集成**
   - 安全的公网访问
   - 自动 HTTPS
   - DDoS 保护
   - 隐藏源服务器 IP

4. **完整的管理工具**
   - 一键部署脚本
   - 交互式管理工具
   - 健康检查脚本
   - 备份恢复功能
   - 一键卸载脚本

---

## 📂 项目文件结构

```
docker/
├── docker-compose.yml           # Docker Compose 主配置
├── Dockerfile                   # F5-TTS 容器镜像定义
├── .env.example                 # 环境变量模板
├── .gitignore                   # Git 忽略规则
│
├── auth_wrapper.py              # Gradio 认证包装器
│
├── deploy.sh                    # 🚀 一键部署脚本
├── manage.sh                    # 🛠️ 交互式管理工具
├── health-check.sh              # 💊 健康检查脚本
├── uninstall.sh                 # 🗑️ 卸载脚本
│
├── nginx/
│   ├── nginx.conf               # Nginx 反向代理配置
│   └── .htpasswd.example        # HTTP Basic Auth 密码模板
│
├── cloudflared/
│   └── config.yml.example       # Cloudflare Tunnel 配置模板
│
├── README.md                    # 📖 完整文档
├── QUICKSTART.md                # 🚀 快速入门指南
└── PROJECT_OVERVIEW.md          # 📦 本文件
```

---

## 🚀 快速开始

### 1. 配置环境

```bash
cd /Users/apple/Desktop/code/web/F5-TTS/docker
cp .env.example .env
nano .env  # 修改 ADMIN_PASSWORD 和 CLOUDFLARE_TUNNEL_TOKEN
```

### 2. 一键部署

```bash
chmod +x *.sh
./deploy.sh
```

### 3. 访问服务

- **本地**: http://localhost:8080
- **公网**: https://f5-tts.yourdomain.com

---

## 🔧 管理工具使用

### 交互式管理工具

```bash
./manage.sh
```

提供以下功能：
1. 启动服务
2. 停止服务
3. 重启服务
4. 查看状态
5. 查看日志
6. 更新服务
7. 修改密码
8. 备份数据
9. 恢复数据
10. 清理缓存

### 健康检查

```bash
./health-check.sh
```

检查所有服务的运行状态和资源使用情况。

### 卸载

```bash
./uninstall.sh
```

完全卸载所有服务和数据（可选备份）。

---

## 🔐 安全特性

### 双层认证

1. **Nginx 层认证**（默认启用）
   - HTTP Basic Auth
   - 保护所有 HTTP 请求
   - 使用 bcrypt 加密密码

2. **Gradio 层认证**（可选）
   - 应用层认证
   - 通过环境变量控制
   - 支持自定义用户验证

### Cloudflare 保护

- 自动 SSL/TLS 加密
- DDoS 攻击防护
- Bot 检测和防护
- 隐藏真实服务器 IP
- 访问日志和分析

---

## 📊 架构设计

```
                    互联网
                      ↓
            Cloudflare Tunnel
                (cloudflared)
                      ↓
                  Nginx 反向代理
              (HTTP Basic Auth)
                      ↓
                  F5-TTS 服务
              (Gradio + PyTorch)
                      ↓
                  NVIDIA GPU
```

### 服务说明

1. **F5-TTS Container**
   - 运行环境: PyTorch + CUDA
   - Web 框架: Gradio
   - 端口: 7860 (容器内)
   - GPU: NVIDIA Runtime

2. **Nginx Container**
   - 反向代理 + 认证
   - 端口: 80 (容器内), 8080 (主机)
   - 认证: HTTP Basic Auth

3. **Cloudflared Container**
   - Cloudflare Tunnel 客户端
   - 安全连接到 Cloudflare 网络
   - 无需开放公网端口

---

## 🔄 工作流程

### 部署流程

1. 用户配置 `.env` 文件
2. 运行 `deploy.sh` 脚本
3. 脚本自动：
   - 检查系统要求
   - 生成认证密码文件
   - 构建 Docker 镜像
   - 启动所有服务
   - 显示访问信息

### 请求流程

1. 用户访问域名（通过 Cloudflare）
2. Cloudflare Tunnel 转发请求到 Nginx
3. Nginx 进行 HTTP Basic Auth 验证
4. 验证通过后，转发到 F5-TTS Gradio
5. Gradio 进行第二层认证（可选）
6. 处理语音合成请求
7. 返回生成的音频

---

## 🌟 核心特点

### 1. 一键部署
- 自动化脚本处理所有配置
- 无需手动编辑多个文件
- 友好的交互式提示

### 2. 安全可靠
- 双层身份认证
- 加密传输（HTTPS）
- DDoS 保护
- 访问控制

### 3. 易于管理
- 交互式管理工具
- 自动备份和恢复
- 健康检查
- 日志查看

### 4. 高性能
- GPU 加速
- 模型缓存
- 反向代理优化
- WebSocket 支持

### 5. 可扩展
- 模块化架构
- Docker 容器化
- 易于添加新功能
- 支持水平扩展

---

## 📝 配置说明

### 环境变量 (.env)

```bash
# 管理员认证
ADMIN_USERNAME=admin              # 管理员用户名
ADMIN_PASSWORD=secure_password    # 管理员密码（必须修改）
ENABLE_AUTH=true                  # 是否启用认证

# Cloudflare Tunnel
CLOUDFLARE_TUNNEL_TOKEN=xxx       # Tunnel Token（必须配置）
CLOUDFLARE_DOMAIN=f5-tts.your.com # 你的域名

# GPU 配置
NVIDIA_VISIBLE_DEVICES=all        # 使用所有 GPU

# 网络端口
NGINX_PORT=8080                   # Nginx 监听端口
```

### Docker Compose 配置

- **f5-tts**: 主服务容器
  - GPU: NVIDIA Runtime
  - 端口: 7860
  - Volume: 模型缓存、输出、数据

- **nginx-auth**: 反向代理 + 认证
  - 端口: 8080
  - 依赖: f5-tts

- **cloudflared**: Cloudflare Tunnel
  - 依赖: nginx-auth
  - 环境变量: TUNNEL_TOKEN

---

## 🔗 集成到 propsdin-theme 项目

如果要集成到 `/Users/apple/Desktop/code/web/propsdin-theme` 项目：

### 方式 1: API 调用

在 propsdin-theme 中通过 HTTP 请求调用 F5-TTS API：

```javascript
// 示例: Node.js / Express
const axios = require('axios');

async function generateSpeech(referenceText, generationText) {
  const auth = {
    username: 'admin',
    password: 'your_password'
  };
  
  const response = await axios.post(
    'https://f5-tts.yourdomain.com/api/predict',
    {
      reference_text: referenceText,
      generation_text: generationText
    },
    { auth }
  );
  
  return response.data;
}
```

### 方式 2: Iframe 嵌入

在 propsdin-theme 的管理员页面嵌入 F5-TTS：

```html
<iframe 
  src="https://f5-tts.yourdomain.com" 
  width="100%" 
  height="800px"
  frameborder="0">
</iframe>
```

### 方式 3: 统一认证

如果 propsdin-theme 有自己的认证系统，可以：

1. 修改 `auth_wrapper.py`，对接 propsdin-theme 的认证 API
2. 使用 JWT Token 进行跨服务认证
3. 配置 Nginx 转发认证头

---

## 🛠️ 自定义和扩展

### 添加自定义模型

1. 将模型文件放到 `data/` 目录
2. 修改 F5-TTS 配置文件
3. 重启服务

### 修改主题样式

编辑 `docker-compose.yml`，添加 Gradio 主题环境变量：

```yaml
environment:
  - GRADIO_THEME=soft
```

### 添加监控

集成 Prometheus + Grafana：

```yaml
# 在 docker-compose.yml 添加
prometheus:
  image: prom/prometheus
  volumes:
    - ./prometheus.yml:/etc/prometheus/prometheus.yml

grafana:
  image: grafana/grafana
  ports:
    - "3000:3000"
```

---

## 📊 性能优化建议

### GPU 优化
- 使用最新的 NVIDIA 驱动
- 启用 CUDA 12.4+
- 配置合适的 batch size

### 网络优化
- 启用 HTTP/2
- 配置 gzip 压缩
- CDN 加速静态资源

### 存储优化
- 使用 SSD 存储
- 定期清理旧文件
- 配置日志轮转

---

## 📞 支持和维护

### 日志位置

- **F5-TTS**: `docker compose logs f5-tts`
- **Nginx**: `docker compose logs nginx-auth`
- **Cloudflared**: `docker compose logs cloudflared`

### 常见问题

参见：
- [README.md](./README.md) - 完整文档
- [QUICKSTART.md](./QUICKSTART.md) - 快速入门

### 获取帮助

- GitHub Issues: https://github.com/SWivid/F5-TTS/issues
- 项目文档: https://github.com/SWivid/F5-TTS

---

## ✅ 项目检查清单

部署前检查：
- [ ] Docker 和 Docker Compose 已安装
- [ ] NVIDIA GPU 驱动已安装（如果使用 GPU）
- [ ] 已配置 `.env` 文件
- [ ] 已修改默认密码
- [ ] 已获取 Cloudflare Tunnel Token
- [ ] 域名已配置

部署后检查：
- [ ] 所有容器正常运行
- [ ] 本地访问 http://localhost:8080 正常
- [ ] 认证功能正常
- [ ] 公网访问正常（如果配置了 Cloudflare）
- [ ] API 调用正常
- [ ] GPU 被正确识别（如果使用 GPU）

---

## 🎉 总结

本项目提供了一个**生产级别**的 F5-TTS Docker 部署方案，具有：

✅ 完整的功能
✅ 安全的认证
✅ 便捷的管理
✅ 详细的文档
✅ 易于扩展

可以直接用于生产环境，为管理员提供安全、可靠的语音合成服务！

---

**作者**: GitHub Copilot  
**版本**: 1.0.0  
**日期**: 2025-11-19  
**许可**: MIT License
