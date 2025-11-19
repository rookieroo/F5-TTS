# 🚀 统一 TTS 服务 - 快速部署指南

## 📋 总结回答你的问题

### Q1: 是否需要将 IndexTTS 也安装到 Docker 中？

**答案: 是的，推荐统一部署** ✅

我已经创建了一个**统一 TTS 服务**，在一个 Docker 容器中同时运行：
- ✅ **F5-TTS** - 快速、高质量
- ✅ **IndexTTS2** - 情感控制丰富

**优势：**
- 一个容器，一键部署
- 统一的 Web UI，可切换引擎
- 共享 GPU 资源
- 统一认证管理

### Q2: 如何让 propsdin-theme 的管理员用户都能使用？

**答案: 三种集成方案** 🔗

#### 方案 1: API 集成（推荐）
- 在 propsdin-theme 后端创建 TTS API 代理
- 验证管理员身份后调用 TTS 服务
- 最佳用户体验

#### 方案 2: Iframe 嵌入（最简单）
- 直接在管理员面板嵌入 TTS UI
- 5分钟即可完成
- 适合快速验证

#### 方案 3: JWT 统一认证（最安全）
- 使用 JWT Token 统一身份认证
- 无需二次登录
- 适合大规模部署

---

## 🏗️ 项目结构

```
docker/
├── Dockerfile.unified               # 统一 TTS 服务镜像
├── docker-compose.unified.yml       # Docker Compose 配置
├── unified_tts_service.py          # 统一 TTS 服务主程序
├── UNIFIED_TTS_SOLUTION.md         # 架构方案文档
├── INTEGRATION_GUIDE.md            # 与 propsdin-theme 集成指南
└── QUICKSTART_UNIFIED.md           # 本文件
```

---

## ⚡ 快速开始（10分钟）

### 1. 配置环境变量

```bash
cd /Users/apple/Desktop/code/web/F5-TTS/docker

# 复制配置
cp .env.example .env

# 编辑配置
nano .env
```

**必须修改：**
```bash
ADMIN_USERNAME=admin
ADMIN_PASSWORD=your_secure_password  # ⚠️ 修改密码
CLOUDFLARE_TUNNEL_TOKEN=your_token   # ⚠️ Cloudflare Token
CLOUDFLARE_DOMAIN=tts.yourdomain.com
```

### 2. 生成密码文件

```bash
# 使用 Docker 生成
docker run --rm httpd:alpine htpasswd -nbB admin your_password > nginx/.htpasswd
```

### 3. 部署服务

```bash
# 使用统一配置部署
docker compose -f docker-compose.unified.yml build
docker compose -f docker-compose.unified.yml up -d
```

**注意：** 首次启动会下载模型文件（约 5-10GB），需要 10-15 分钟。

### 4. 验证部署

```bash
# 检查服务状态
docker compose -f docker-compose.unified.yml ps

# 查看日志
docker compose -f docker-compose.unified.yml logs -f unified-tts
```

### 5. 访问服务

- **本地**: http://localhost:8080
- **公网**: https://tts.yourdomain.com

登录凭证: 使用 `.env` 中的 `ADMIN_USERNAME` 和 `ADMIN_PASSWORD`

---

## 🎯 在 propsdin-theme 中使用

### 方法 A: Iframe 嵌入（最简单，5分钟）

在管理员页面中添加：

```html
<!-- propsdin-theme/admin-panel.html -->
<div class="tts-panel">
  <h2>🎙️ TTS 语音合成</h2>
  <iframe 
    src="https://tts.yourdomain.com" 
    width="100%" 
    height="800px"
    frameborder="0">
  </iframe>
</div>
```

### 方法 B: API 集成（完整示例）

#### 1. 后端 API（Node.js/Express）

```javascript
// propsdin-theme/src/api/tts.js
const express = require('express');
const axios = require('axios');
const router = express.Router();

// 中间件：验证管理员
function requireAdmin(req, res, next) {
  if (req.user?.role === 'admin') {
    next();
  } else {
    res.status(403).json({ error: '需要管理员权限' });
  }
}

// API：生成语音
router.post('/api/tts/generate', requireAdmin, async (req, res) => {
  try {
    const response = await axios.post(
      'http://localhost:8080/api/predict',
      req.body,
      {
        auth: {
          username: process.env.TTS_USERNAME,
          password: process.env.TTS_PASSWORD
        },
        timeout: 120000
      }
    );
    
    res.json(response.data);
  } catch (error) {
    res.status(500).json({ error: 'TTS 生成失败' });
  }
});

module.exports = router;
```

#### 2. 前端组件（React）

```typescript
// propsdin-theme/src/components/TTSPanel.tsx
import React, { useState } from 'react';
import axios from 'axios';

export const TTSPanel = () => {
  const [engine, setEngine] = useState('F5-TTS');
  const [refAudio, setRefAudio] = useState(null);
  const [genText, setGenText] = useState('');
  const [audioUrl, setAudioUrl] = useState(null);
  const [loading, setLoading] = useState(false);

  const handleGenerate = async () => {
    setLoading(true);
    try {
      const formData = new FormData();
      formData.append('engine', engine);
      formData.append('refAudio', refAudio);
      formData.append('genText', genText);

      const response = await axios.post('/api/tts/generate', formData);
      setAudioUrl(response.data.audioUrl);
    } catch (error) {
      alert('生成失败');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="tts-panel">
      <h2>🎙️ TTS 语音合成</h2>
      
      <select value={engine} onChange={(e) => setEngine(e.target.value)}>
        <option value="F5-TTS">F5-TTS (快速)</option>
        <option value="IndexTTS2">IndexTTS2 (情感)</option>
      </select>

      <input
        type="file"
        accept="audio/*"
        onChange={(e) => setRefAudio(e.target.files[0])}
      />

      <textarea
        value={genText}
        onChange={(e) => setGenText(e.target.value)}
        placeholder="输入要合成的文本..."
        rows={5}
      />

      <button onClick={handleGenerate} disabled={loading}>
        {loading ? '生成中...' : '🎵 生成语音'}
      </button>

      {audioUrl && <audio controls src={audioUrl} />}
    </div>
  );
};
```

---

## 📊 功能对比

| 特性 | F5-TTS | IndexTTS2 |
|------|--------|-----------|
| 推理速度 | ⚡ 快 | 🐢 较慢 |
| 音质 | ✅ 优秀 | ✅ 优秀 |
| 情感控制 | ❌ 无 | ✅ 8维情感向量 |
| 情感参考音频 | ❌ 不支持 | ✅ 支持 |
| 模型大小 | 📦 中等 | 📦 较大 |
| 显存占用 | 💾 4-6GB | 💾 6-8GB |
| 适用场景 | 快速合成 | 情感表达 |

---

## 🛠️ 常用命令

### 启动服务
```bash
docker compose -f docker-compose.unified.yml up -d
```

### 停止服务
```bash
docker compose -f docker-compose.unified.yml down
```

### 查看日志
```bash
docker compose -f docker-compose.unified.yml logs -f
```

### 重启服务
```bash
docker compose -f docker-compose.unified.yml restart
```

### 查看状态
```bash
docker compose -f docker-compose.unified.yml ps
```

### 进入容器
```bash
docker exec -it unified-tts-service bash
```

---

## 🔧 故障排查

### 问题 1: 模型下载失败

**原因**: Hugging Face 访问慢

**解决**:
```bash
# 使用镜像
export HF_ENDPOINT=https://hf-mirror.com

# 或在 .env 中配置
HF_ENDPOINT=https://hf-mirror.com
```

### 问题 2: GPU 未识别

**检查**:
```bash
# 检查 NVIDIA 驱动
nvidia-smi

# 检查 Docker GPU 支持
docker run --rm --gpus all nvidia/cuda:12.4.0-base-ubuntu22.04 nvidia-smi
```

### 问题 3: 容器启动失败

**查看日志**:
```bash
docker compose -f docker-compose.unified.yml logs unified-tts
```

### 问题 4: 内存不足

**优化**:
```yaml
# docker-compose.unified.yml
environment:
  - USE_FP16=true  # 启用 FP16 推理
```

---

## 📈 性能优化

### 1. 启用 FP16

```bash
# 修改启动命令
command: >
  python3 /workspace/unified_tts_service.py
  --port 7860
  --host 0.0.0.0
  --fp16  # 添加这行
```

**效果**: 显存减少 ~50%，速度提升 ~30%

### 2. 启用 DeepSpeed（可选）

```bash
command: >
  python3 /workspace/unified_tts_service.py
  --port 7860
  --host 0.0.0.0
  --fp16
  --deepspeed  # 添加这行
```

**注意**: 不是所有系统都能获得加速

### 3. 资源限制

```yaml
deploy:
  resources:
    limits:
      cpus: '8'
      memory: 32G
    reservations:
      memory: 16G
```

---

## 🔒 安全建议

1. ✅ 修改默认密码
2. ✅ 使用强密码（16+ 字符）
3. ✅ 定期更新镜像
4. ✅ 限制管理员数量
5. ✅ 启用速率限制
6. ✅ 监控访问日志
7. ✅ 定期备份数据

---

## 📚 相关文档

- [完整部署文档](./README.md)
- [架构方案](./UNIFIED_TTS_SOLUTION.md)
- [集成指南](./INTEGRATION_GUIDE.md)
- [项目总览](./PROJECT_OVERVIEW.md)

---

## ✅ 部署检查清单

- [ ] Docker 和 NVIDIA Container Toolkit 已安装
- [ ] 环境变量已配置（`.env`）
- [ ] 密码文件已生成（`nginx/.htpasswd`）
- [ ] Cloudflare Tunnel Token 已获取
- [ ] 服务已启动
- [ ] 健康检查通过
- [ ] 本地访问正常
- [ ] 公网访问正常
- [ ] 认证功能正常
- [ ] 两个引擎都能正常工作

---

## 🎉 完成！

现在你拥有一个功能完整的统一 TTS 服务，可以：

✅ 使用 F5-TTS 进行快速语音合成
✅ 使用 IndexTTS2 进行情感控制
✅ 通过 Cloudflare 安全地暴露到公网
✅ 只允许管理员访问
✅ 与 propsdin-theme 项目集成

**下一步**: 选择一个集成方案，在 propsdin-theme 中使用！

---

**有问题？** 查看 [INTEGRATION_GUIDE.md](./INTEGRATION_GUIDE.md) 获取详细的集成示例。
