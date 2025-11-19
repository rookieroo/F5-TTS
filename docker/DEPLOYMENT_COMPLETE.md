# 🎉 F5-TTS Docker 项目部署完成

## ✅ 项目已完成

恭喜！F5-TTS Docker 部署项目已经成功创建。所有文件都已准备就绪，可以开始部署了。

---

## 📦 创建的文件清单

### 核心配置文件
```
docker/
├── docker-compose.yml           ✅ Docker Compose 主配置
├── Dockerfile                   ✅ 自定义 F5-TTS 镜像
├── .env.example                 ✅ 环境变量模板
├── .gitignore                   ✅ Git 忽略配置
└── auth_wrapper.py              ✅ Gradio 认证包装器
```

### 脚本工具
```
docker/
├── deploy.sh                    ✅ 一键部署脚本
├── manage.sh                    ✅ 交互式管理工具
├── health-check.sh              ✅ 健康检查脚本
└── uninstall.sh                 ✅ 卸载脚本
```

### Nginx 配置
```
docker/nginx/
├── nginx.conf                   ✅ Nginx 反向代理配置
└── .htpasswd.example            ✅ 密码文件模板
```

### Cloudflare 配置
```
docker/cloudflared/
└── config.yml.example           ✅ Cloudflare Tunnel 配置模板
```

### 文档
```
docker/
├── README.md                    ✅ 完整部署文档
├── QUICKSTART.md                ✅ 快速入门指南
├── PROJECT_OVERVIEW.md          ✅ 项目总览
└── DEPLOYMENT_COMPLETE.md       ✅ 本文件
```

**总计**: 17 个文件 ✨

---

## 🚀 下一步操作

### 1️⃣ 配置环境变量（必须）

```bash
cd /Users/apple/Desktop/code/web/F5-TTS/docker

# 复制配置模板
cp .env.example .env

# 编辑配置文件
nano .env
```

**必须修改的配置项**:
- ✏️ `ADMIN_PASSWORD`: 设置强密码
- ✏️ `CLOUDFLARE_TUNNEL_TOKEN`: 从 Cloudflare 获取
- ✏️ `CLOUDFLARE_DOMAIN`: 你的域名

### 2️⃣ 获取 Cloudflare Tunnel Token

1. 访问: https://one.dash.cloudflare.com/
2. 进入 **Access** → **Tunnels**
3. 点击 **Create a tunnel**
4. 输入名称（如: `f5-tts`）
5. 复制生成的 **Token**
6. 粘贴到 `.env` 文件

### 3️⃣ 一键部署

```bash
# 添加执行权限（已完成）
chmod +x *.sh

# 运行部署脚本
./deploy.sh
```

部署过程约需 5-10 分钟，取决于网络速度和硬件配置。

### 4️⃣ 验证部署

```bash
# 检查服务状态
./health-check.sh

# 查看日志
docker compose logs -f
```

### 5️⃣ 访问服务

- 🏠 **本地访问**: http://localhost:8080
- 🌐 **公网访问**: https://f5-tts.yourdomain.com

**登录凭证**: 使用 `.env` 中配置的用户名和密码

---

## 🎯 核心功能

### ✨ 已实现的功能

- ✅ **F5-TTS 语音合成服务**
  - 基于 Gradio 的 Web UI
  - GPU 加速支持
  - RESTful API

- ✅ **双层身份认证**
  - Nginx HTTP Basic Auth
  - Gradio 应用层认证（可选）

- ✅ **Cloudflare Tunnel**
  - 安全的公网访问
  - 自动 HTTPS
  - DDoS 保护

- ✅ **完整的管理工具**
  - 一键部署
  - 交互式管理
  - 健康检查
  - 备份恢复

---

## 🔐 安全特性

### 认证机制

1. **HTTP Basic Auth**（Nginx 层）
   - 第一道防线
   - 保护所有 HTTP 请求
   - bcrypt 加密密码

2. **Gradio 认证**（应用层）
   - 第二道防线（可选）
   - 可通过 `ENABLE_AUTH` 控制
   - 支持自定义验证逻辑

### Cloudflare 保护

- 🔒 SSL/TLS 加密
- 🛡️ DDoS 防护
- 🤖 Bot 防护
- 🔍 访问分析
- 🌍 全球 CDN

---

## 🛠️ 管理工具使用

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
7. **修改密码**
8. **备份数据**
9. **恢复数据**
10. 清理缓存

### 常用命令

```bash
# 查看状态
docker compose ps

# 查看日志
docker compose logs -f f5-tts

# 重启服务
docker compose restart

# 停止服务
docker compose down

# 健康检查
./health-check.sh
```

---

## 🔗 集成到 propsdin-theme 项目

### 方案 1: API 调用

在 propsdin-theme 项目中通过 API 调用 F5-TTS：

```javascript
// Node.js 示例
const axios = require('axios');

async function generateSpeech(text) {
  const response = await axios.post(
    'https://f5-tts.yourdomain.com/api/predict',
    {
      generation_text: text,
      // ... 其他参数
    },
    {
      auth: {
        username: 'admin',
        password: process.env.F5TTS_PASSWORD
      }
    }
  );
  
  return response.data;
}

// 在 Express 路由中使用
app.post('/api/tts', isAdmin, async (req, res) => {
  const { text } = req.body;
  const audio = await generateSpeech(text);
  res.json({ audio });
});
```

### 方案 2: Iframe 嵌入

在管理员页面嵌入 F5-TTS UI：

```html
<!-- 在 propsdin-theme 管理员页面中 -->
<div class="admin-panel">
  <h2>语音合成工具</h2>
  <iframe 
    src="https://f5-tts.yourdomain.com"
    width="100%"
    height="800px"
    frameborder="0"
    sandbox="allow-same-origin allow-scripts allow-forms">
  </iframe>
</div>
```

### 方案 3: 统一认证

如果需要与 propsdin-theme 的认证系统集成：

1. **修改 `auth_wrapper.py`**:
```python
def check_admin_from_propsdin(token):
    # 调用 propsdin-theme 的认证 API
    response = requests.get(
        'http://propsdin-theme/api/verify-admin',
        headers={'Authorization': f'Bearer {token}'}
    )
    return response.status_code == 200

def gradio_auth(username: str, password: str) -> bool:
    # 验证是否为管理员 token
    if check_admin_from_propsdin(password):
        return True
    # 或使用默认认证
    return default_auth(username, password)
```

2. **在 propsdin-theme 中生成访问 token**:
```javascript
// 管理员登录后生成专用 token
app.post('/admin/generate-tts-token', isAdmin, (req, res) => {
  const token = jwt.sign(
    { userId: req.user.id, role: 'admin' },
    process.env.JWT_SECRET,
    { expiresIn: '1h' }
  );
  res.json({ token });
});
```

---

## 📊 监控和日志

### 查看实时日志

```bash
# 所有服务
docker compose logs -f

# 特定服务
docker compose logs -f f5-tts
docker compose logs -f nginx-auth
docker compose logs -f cloudflared
```

### 资源监控

```bash
# 实时资源使用
docker stats

# 健康检查
./health-check.sh

# GPU 使用情况
nvidia-smi
```

### 访问日志

Nginx 访问日志包含：
- 请求 IP
- 请求时间
- 请求路径
- 响应状态
- 用户代理

```bash
docker compose logs nginx-auth | grep "GET\|POST"
```

---

## 🔧 常见问题

### Q1: GPU 未被识别？

```bash
# 检查 NVIDIA 驱动
nvidia-smi

# 检查 Docker GPU 支持
docker run --rm --gpus all nvidia/cuda:12.4.0-base-ubuntu22.04 nvidia-smi

# 重启 Docker
sudo systemctl restart docker
```

### Q2: 端口冲突？

```bash
# 检查端口占用
lsof -i :8080
lsof -i :7860

# 修改 docker-compose.yml 中的端口映射
```

### Q3: 认证失败？

```bash
# 重新生成密码文件
./manage.sh  # 选择 "7) 修改密码"

# 或手动生成
docker run --rm httpd:alpine htpasswd -nbB admin new_password > nginx/.htpasswd
docker compose restart nginx-auth
```

### Q4: Cloudflare 连接失败？

```bash
# 检查 Token
cat .env | grep CLOUDFLARE_TUNNEL_TOKEN

# 查看 cloudflared 日志
docker compose logs cloudflared

# 重启 Tunnel
docker compose restart cloudflared
```

---

## 📚 文档参考

| 文档 | 用途 |
|------|------|
| [QUICKSTART.md](./QUICKSTART.md) | 快速入门（3 分钟） |
| [README.md](./README.md) | 完整部署文档 |
| [PROJECT_OVERVIEW.md](./PROJECT_OVERVIEW.md) | 项目架构和设计 |

---

## 🎨 自定义配置

### 修改 Gradio 主题

编辑 `docker-compose.yml`:
```yaml
environment:
  - GRADIO_THEME=soft  # soft, glass, monochrome
```

### 修改资源限制

编辑 `docker-compose.yml`:
```yaml
deploy:
  resources:
    limits:
      cpus: '4'
      memory: 16G
```

### 添加自定义模型

1. 将模型放到 `../data/models/`
2. 修改 F5-TTS 配置
3. 重启服务

---

## 🔄 更新和维护

### 更新 F5-TTS

```bash
# 方法 1: 使用管理工具
./manage.sh  # 选择 "6) 更新服务"

# 方法 2: 手动更新
cd /Users/apple/Desktop/code/web/F5-TTS
git pull
cd docker
docker compose build --no-cache
docker compose up -d
```

### 备份数据

```bash
# 使用管理工具
./manage.sh  # 选择 "8) 备份数据"

# 手动备份
./manage.sh <<< "8"
```

### 恢复数据

```bash
# 使用管理工具
./manage.sh  # 选择 "9) 恢复数据"
```

---

## 🔒 安全建议

- ✅ 使用强密码（16+ 字符）
- ✅ 定期更新服务和依赖
- ✅ 启用 Cloudflare Access（额外保护）
- ✅ 监控访问日志
- ✅ 定期备份数据
- ✅ 限制管理员数量
- ✅ 使用 VPN 访问管理界面（可选）

---

## 📞 获取支持

### 官方资源

- 📖 [F5-TTS GitHub](https://github.com/SWivid/F5-TTS)
- 🐛 [提交 Issue](https://github.com/SWivid/F5-TTS/issues)
- 💬 [社区讨论](https://github.com/SWivid/F5-TTS/discussions)

### 本地文档

- [完整文档](./README.md)
- [快速入门](./QUICKSTART.md)
- [项目总览](./PROJECT_OVERVIEW.md)

---

## ✅ 部署检查清单

### 部署前

- [ ] Docker 已安装
- [ ] Docker Compose 已安装
- [ ] NVIDIA 驱动已安装（如果使用 GPU）
- [ ] 已配置 `.env` 文件
- [ ] 已修改默认密码
- [ ] 已获取 Cloudflare Tunnel Token
- [ ] 域名已正确配置

### 部署后

- [ ] 所有容器运行正常
- [ ] 本地访问正常（http://localhost:8080）
- [ ] 认证功能正常
- [ ] 公网访问正常（https://your-domain.com）
- [ ] API 调用正常
- [ ] GPU 被正确识别（如果使用）
- [ ] 健康检查通过

---

## 🎉 完成！

你现在拥有一个**生产级别**的 F5-TTS 部署方案，包含：

✨ 完整的功能  
🔒 安全的认证  
🛠️ 便捷的管理  
📖 详细的文档  
🚀 一键部署  

准备好了吗？运行 `./deploy.sh` 开始部署！

---

**项目创建**: 2025-11-19  
**版本**: 1.0.0  
**许可**: MIT License  

如有问题，请查阅文档或提交 Issue。祝使用愉快！🎊
