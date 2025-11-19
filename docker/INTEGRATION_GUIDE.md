# 🔗 与 propsdin-theme 项目集成方案

## 方案概览

为 propsdin-theme 项目的**管理员用户**提供 TTS 功能，支持三种集成方式。

---

## 方案 1: API 集成（推荐）⭐

### 架构

```
propsdin-theme (前端)
       ↓
   验证管理员身份
       ↓
  调用后端 API
       ↓
propsdin-theme (后端)
       ↓
  携带认证信息
       ↓
Unified TTS Service
```

### 实现步骤

#### 1️⃣ 在 propsdin-theme 后端添加 TTS API 代理

```javascript
// propsdin-theme/src/api/tts.js (Node.js/Express 示例)
const express = require('express');
const axios = require('axios');
const router = express.Router();

// TTS 服务配置
const TTS_SERVICE_URL = process.env.TTS_SERVICE_URL || 'http://localhost:8080';
const TTS_USERNAME = process.env.TTS_USERNAME || 'admin';
const TTS_PASSWORD = process.env.TTS_PASSWORD;

// 中间件：验证管理员身份
function requireAdmin(req, res, next) {
  if (req.user && req.user.role === 'admin') {
    next();
  } else {
    res.status(403).json({ error: '需要管理员权限' });
  }
}

// API: 生成语音
router.post('/api/tts/generate', requireAdmin, async (req, res) => {
  try {
    const { engine, refAudio, refText, genText, ...options } = req.body;
    
    // 调用 TTS 服务
    const response = await axios.post(
      `${TTS_SERVICE_URL}/api/predict`,
      {
        engine,
        ref_audio: refAudio,
        ref_text: refText,
        gen_text: genText,
        ...options
      },
      {
        auth: {
          username: TTS_USERNAME,
          password: TTS_PASSWORD
        },
        timeout: 120000  // 2分钟超时
      }
    );
    
    res.json(response.data);
  } catch (error) {
    console.error('TTS 生成失败:', error);
    res.status(500).json({ 
      error: 'TTS 生成失败', 
      details: error.message 
    });
  }
});

// API: 检查 TTS 服务状态
router.get('/api/tts/status', requireAdmin, async (req, res) => {
  try {
    const response = await axios.get(`${TTS_SERVICE_URL}/health`, {
      auth: {
        username: TTS_USERNAME,
        password: TTS_PASSWORD
      }
    });
    res.json({ status: 'online', ...response.data });
  } catch (error) {
    res.json({ status: 'offline', error: error.message });
  }
});

module.exports = router;
```

#### 2️⃣ 在 propsdin-theme 前端创建 TTS 组件

```typescript
// propsdin-theme/src/components/AdminTTS.tsx (React 示例)
import React, { useState } from 'react';
import axios from 'axios';

interface TTSOptions {
  engine: 'F5-TTS' | 'IndexTTS2';
  refAudio: File | null;
  refText: string;
  genText: string;
  // 其他选项...
}

export const AdminTTS: React.FC = () => {
  const [options, setOptions] = useState<TTSOptions>({
    engine: 'F5-TTS',
    refAudio: null,
    refText: '',
    genText: ''
  });
  
  const [loading, setLoading] = useState(false);
  const [audioUrl, setAudioUrl] = useState<string | null>(null);
  const [error, setError] = useState<string | null>(null);

  const handleGenerate = async () => {
    if (!options.refAudio || !options.genText) {
      setError('请提供参考音频和目标文本');
      return;
    }

    setLoading(true);
    setError(null);

    try {
      const formData = new FormData();
      formData.append('engine', options.engine);
      formData.append('refAudio', options.refAudio);
      formData.append('refText', options.refText);
      formData.append('genText', options.genText);

      const response = await axios.post('/api/tts/generate', formData, {
        headers: {
          'Content-Type': 'multipart/form-data'
        }
      });

      // 假设返回的是音频 URL
      setAudioUrl(response.data.audioUrl);
    } catch (err: any) {
      setError(err.response?.data?.error || '生成失败');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="admin-tts-panel">
      <h2>🎙️ TTS 语音合成</h2>
      
      <div className="tts-controls">
        {/* 引擎选择 */}
        <label>
          TTS 引擎:
          <select 
            value={options.engine} 
            onChange={(e) => setOptions({...options, engine: e.target.value as any})}
          >
            <option value="F5-TTS">F5-TTS (快速)</option>
            <option value="IndexTTS2">IndexTTS2 (情感控制)</option>
          </select>
        </label>

        {/* 参考音频 */}
        <label>
          参考音频:
          <input
            type="file"
            accept="audio/*"
            onChange={(e) => setOptions({...options, refAudio: e.target.files?.[0] || null})}
          />
        </label>

        {/* 参考文本 */}
        {options.engine === 'F5-TTS' && (
          <label>
            参考文本:
            <input
              type="text"
              value={options.refText}
              onChange={(e) => setOptions({...options, refText: e.target.value})}
              placeholder="参考音频的文字内容..."
            />
          </label>
        )}

        {/* 目标文本 */}
        <label>
          目标文本:
          <textarea
            value={options.genText}
            onChange={(e) => setOptions({...options, genText: e.target.value})}
            placeholder="要合成的文字内容..."
            rows={5}
          />
        </label>

        {/* 生成按钮 */}
        <button 
          onClick={handleGenerate} 
          disabled={loading}
          className="btn-primary"
        >
          {loading ? '生成中...' : '🎵 生成语音'}
        </button>
      </div>

      {/* 错误提示 */}
      {error && (
        <div className="error-message">{error}</div>
      )}

      {/* 音频播放器 */}
      {audioUrl && (
        <div className="audio-result">
          <h3>生成结果:</h3>
          <audio controls src={audioUrl} />
          <a href={audioUrl} download>下载音频</a>
        </div>
      )}
    </div>
  );
};
```

#### 3️⃣ 在管理员面板中使用

```typescript
// propsdin-theme/src/pages/AdminPanel.tsx
import { AdminTTS } from '@/components/AdminTTS';

export const AdminPanel = () => {
  return (
    <div className="admin-panel">
      <h1>管理员面板</h1>
      
      {/* 其他管理功能... */}
      
      {/* TTS 功能 */}
      <section>
        <AdminTTS />
      </section>
    </div>
  );
};
```

---

## 方案 2: Iframe 嵌入

### 特点

- 直接嵌入 TTS 服务的 Web UI
- 无需额外开发
- 认证由 TTS 服务处理

### 实现

```typescript
// propsdin-theme/src/components/TTSIframe.tsx
import React from 'react';

export const TTSIframe: React.FC = () => {
  const ttsUrl = process.env.REACT_APP_TTS_URL || 'https://tts.yourdomain.com';

  return (
    <div className="tts-iframe-container">
      <h2>🎙️ TTS 语音合成工具</h2>
      <iframe
        src={ttsUrl}
        width="100%"
        height="800px"
        frameBorder="0"
        title="TTS Service"
        sandbox="allow-same-origin allow-scripts allow-forms allow-popups"
      />
    </div>
  );
};
```

### 优缺点

**优点:**
- ✅ 实现简单
- ✅ 功能完整
- ✅ 无需维护前端代码

**缺点:**
- ⚠️ 用户体验不统一
- ⚠️ 需要两次认证（propsdin-theme + TTS 服务）
- ⚠️ 跨域问题

---

## 方案 3: 统一认证（JWT Token）

### 架构

```
用户 → propsdin-theme 登录
       ↓
  生成 JWT Token (包含角色信息)
       ↓
  访问 TTS 服务时携带 Token
       ↓
TTS 服务验证 Token
       ↓
  验证通过 → 提供服务
```

### 实现步骤

#### 1️⃣ 修改 TTS 服务认证逻辑

```python
# docker/auth_middleware.py
import os
import jwt
from functools import wraps
from datetime import datetime, timedelta

JWT_SECRET = os.getenv('JWT_SECRET', 'your-secret-key')
JWT_ALGORITHM = 'HS256'

def verify_jwt_token(token: str) -> dict:
    """验证 JWT Token"""
    try:
        payload = jwt.decode(token, JWT_SECRET, algorithms=[JWT_ALGORITHM])
        
        # 检查是否过期
        if datetime.fromtimestamp(payload['exp']) < datetime.now():
            raise Exception('Token 已过期')
        
        # 检查角色
        if payload.get('role') != 'admin':
            raise Exception('需要管理员权限')
        
        return payload
    except Exception as e:
        print(f'Token 验证失败: {e}')
        return None

def gradio_auth_jwt(username: str, password: str) -> bool:
    """
    Gradio 认证函数 - 支持 JWT Token
    如果 username 为空，password 作为 JWT Token
    """
    # 方式 1: 传统用户名密码
    if username:
        admin_user = os.getenv('ADMIN_USERNAME', 'admin')
        admin_pass = os.getenv('ADMIN_PASSWORD', 'changeme')
        
        if username == admin_user and password == admin_pass:
            return True
    
    # 方式 2: JWT Token (password 字段传入 token)
    if verify_jwt_token(password):
        return True
    
    return False
```

#### 2️⃣ 在 propsdin-theme 中生成 Token

```javascript
// propsdin-theme/src/api/auth.js
const jwt = require('jsonwebtoken');

const JWT_SECRET = process.env.JWT_SECRET;

// 生成 TTS 访问 Token
router.post('/api/admin/generate-tts-token', requireAdmin, (req, res) => {
  const token = jwt.sign(
    {
      userId: req.user.id,
      username: req.user.username,
      role: 'admin'
    },
    JWT_SECRET,
    { expiresIn: '1h' }  // 1小时有效期
  );
  
  res.json({ token });
});
```

#### 3️⃣ 前端使用 Token 访问

```typescript
// 获取 Token
const response = await axios.post('/api/admin/generate-tts-token');
const ttsToken = response.data.token;

// 使用 Token 访问 TTS 服务
const ttsResponse = await axios.post(
  'https://tts.yourdomain.com/api/predict',
  { ...ttsOptions },
  {
    auth: {
      username: '',  // 空用户名表示使用 Token
      password: ttsToken
    }
  }
);
```

---

## 推荐实施流程

### 第一阶段：基础集成（1-2天）

1. 部署统一 TTS 服务（使用 docker-compose.unified.yml）
2. 在 propsdin-theme 中实现方案 2（Iframe 嵌入）
3. 测试基本功能

### 第二阶段：API 集成（3-5天）

1. 在 propsdin-theme 后端实现 TTS API 代理
2. 创建前端 TTS 组件
3. 优化用户体验

### 第三阶段：统一认证（可选，2-3天）

1. 实现 JWT Token 认证
2. 修改 TTS 服务认证逻辑
3. 前后端联调

---

## 安全性考虑

### 1. 权限控制

```javascript
// 确保只有管理员可以访问
const checkAdminRole = (req, res, next) => {
  if (!req.user) {
    return res.status(401).json({ error: '未登录' });
  }
  
  if (req.user.role !== 'admin') {
    return res.status(403).json({ error: '需要管理员权限' });
  }
  
  next();
};
```

### 2. 速率限制

```javascript
const rateLimit = require('express-rate-limit');

const ttsLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,  // 15分钟
  max: 10,  // 最多 10 次请求
  message: 'TTS 请求过于频繁，请稍后再试'
});

router.use('/api/tts', ttsLimiter);
```

### 3. 输入验证

```javascript
const { body, validationResult } = require('express-validator');

router.post('/api/tts/generate',
  requireAdmin,
  [
    body('genText').isLength({ min: 1, max: 1000 }).trim(),
    body('engine').isIn(['F5-TTS', 'IndexTTS2'])
  ],
  (req, res) => {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }
    
    // 处理请求...
  }
);
```

---

## 部署清单

- [ ] 统一 TTS 服务已部署
- [ ] Cloudflare Tunnel 已配置
- [ ] TTS 服务健康检查通过
- [ ] propsdin-theme 后端 API 已实现
- [ ] propsdin-theme 前端组件已创建
- [ ] 管理员权限验证已实现
- [ ] 安全措施已到位（速率限制、输入验证）
- [ ] 文档已更新
- [ ] 测试已完成

---

## 常见问题

### Q: 如何处理大文件上传？

A: 配置 Nginx 和后端的最大请求大小：

```nginx
# nginx.conf
client_max_body_size 100M;
```

```javascript
// Express
app.use(express.json({ limit: '100mb' }));
app.use(express.urlencoded({ limit: '100mb', extended: true }));
```

### Q: 生成速度慢怎么办？

A: 
1. 启用 FP16 推理
2. 使用 DeepSpeed 加速
3. 考虑异步处理 + 轮询结果

### Q: 如何支持多个管理员？

A: 在数据库中维护管理员列表，后端 API 检查用户角色。

---

## 示例代码仓库

完整示例代码见：
- TTS 服务: `/Users/apple/Desktop/code/web/F5-TTS/docker/`
- 集成示例: 见上文

---

**下一步:** 选择一个方案开始实施！推荐从方案 2 开始快速验证，然后升级到方案 1。
