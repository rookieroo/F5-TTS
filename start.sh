#!/bin/bash
# F5-TTS 启动脚本（优化配置用于 M4 芯片）

export PYTORCH_ENABLE_MPS_FALLBACK=1

conda activate f5-tts
python src/f5_tts/infer/infer_gradio.py
