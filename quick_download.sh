#!/bin/bash
# 快速下载 F5-TTS 模型（使用国内镜像）

echo "🚀 使用 HF-Mirror 加速下载..."

# 设置镜像
export HF_ENDPOINT=https://hf-mirror.com

# 使用 huggingface-cli 下载
echo "📥 下载 F5-TTS 模型..."
huggingface-cli download SWivid/F5-TTS --local-dir-use-symlinks False

echo "📥 下载 Vocos 声码器..."
huggingface-cli download charactr/vocos-mel-24khz --local-dir-use-symlinks False

echo "✅ 下载完成！"
