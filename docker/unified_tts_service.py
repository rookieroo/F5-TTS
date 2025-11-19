#!/usr/bin/env python3
"""
统一 TTS 服务 - 集成 F5-TTS 和 IndexTTS2
提供统一的 Gradio UI 和 REST API
支持管理员认证
"""

import os
import sys
import argparse
import gradio as gr
from typing import Optional, Literal

# 添加路径
sys.path.insert(0, '/workspace/F5-TTS/src')
sys.path.insert(0, '/workspace/index-tts')

# 环境变量配置
ENABLE_AUTH = os.getenv('ENABLE_AUTH', 'true').lower() == 'true'
ADMIN_USERNAME = os.getenv('ADMIN_USERNAME', 'admin')
ADMIN_PASSWORD = os.getenv('ADMIN_PASSWORD', 'changeme')

# TTS 引擎枚举
TTS_ENGINES = {
    'f5tts': 'F5-TTS (Fast & Efficient)',
    'indextts2': 'IndexTTS2 (Emotion Control)'
}

class UnifiedTTSService:
    def __init__(
        self,
        f5tts_model_dir: str = "/workspace/F5-TTS",
        indextts_model_dir: str = "/workspace/index-tts/checkpoints",
        use_fp16: bool = False,
        use_deepspeed: bool = False,
        use_cpu: bool = False
    ):
        """初始化统一 TTS 服务"""
        self.f5tts_model = None
        self.indextts_model = None
        self.f5tts_model_dir = f5tts_model_dir
        self.indextts_model_dir = indextts_model_dir
        self.use_fp16 = use_fp16
        self.use_deepspeed = use_deepspeed
        self.use_cpu = use_cpu
        
        print("="*60)
        print("初始化统一 TTS 服务")
        print(f"CPU 模式: {use_cpu}")
        print(f"FP16 模式: {use_fp16}")
        print("="*60)
        
    def load_f5tts(self):
        """延迟加载 F5-TTS 模型"""
        if self.f5tts_model is None:
            print("\n🔄 加载 F5-TTS 模型...")
            try:
                from f5_tts.api import F5TTS
                self.f5tts_model = F5TTS()
                print("✓ F5-TTS 模型加载成功")
            except Exception as e:
                print(f"✗ F5-TTS 模型加载失败: {e}")
                raise
        return self.f5tts_model
    
    def load_indextts(self):
        """延迟加载 IndexTTS2 模型"""
        if self.indextts_model is None:
            print("\n🔄 加载 IndexTTS2 模型...")
            try:
                from indextts.infer_v2 import IndexTTS2
                self.indextts_model = IndexTTS2(
                    cfg_path=os.path.join(self.indextts_model_dir, "config.yaml"),
                    model_dir=self.indextts_model_dir,
                    use_fp16=self.use_fp16,
                    use_cuda_kernel=False,
                    use_deepspeed=self.use_deepspeed
                )
                print("✓ IndexTTS2 模型加载成功")
            except Exception as e:
                print(f"✗ IndexTTS2 模型加载失败: {e}")
                raise
        return self.indextts_model
    
    def infer_f5tts(
        self,
        ref_audio: str,
        ref_text: str,
        gen_text: str,
        output_path: str = "/workspace/outputs/f5tts_output.wav",
        **kwargs
    ):
        """使用 F5-TTS 进行推理"""
        model = self.load_f5tts()
        
        result = model.infer(
            ref_file=ref_audio,
            ref_text=ref_text,
            gen_text=gen_text,
            file_wave=output_path,
            **kwargs
        )
        
        return output_path
    
    def infer_indextts(
        self,
        ref_audio: str,
        gen_text: str,
        output_path: str = "/workspace/outputs/indextts_output.wav",
        emo_audio: Optional[str] = None,
        emo_vector: Optional[list] = None,
        emo_alpha: float = 1.0,
        **kwargs
    ):
        """使用 IndexTTS2 进行推理"""
        model = self.load_indextts()
        
        model.infer(
            spk_audio_prompt=ref_audio,
            text=gen_text,
            output_path=output_path,
            emo_audio_prompt=emo_audio,
            emo_vector=emo_vector,
            emo_alpha=emo_alpha,
            verbose=True,
            **kwargs
        )
        
        return output_path


def create_gradio_interface(tts_service: UnifiedTTSService):
    """创建 Gradio 界面"""
    
    def infer_wrapper(
        engine: str,
        ref_audio,
        ref_text: str,
        gen_text: str,
        # F5-TTS 参数
        remove_silence: bool,
        speed: float,
        nfe_steps: int,
        # IndexTTS 参数
        emo_audio,
        emo_alpha: float,
        emo_happy: float,
        emo_angry: float,
        emo_sad: float,
        emo_fear: float,
        emo_disgust: float,
        emo_low: float,
        emo_surprise: float,
        emo_calm: float,
    ):
        """统一的推理包装器"""
        if not ref_audio or not gen_text.strip():
            return None, "请提供参考音频和目标文本"
        
        try:
            if engine == "F5-TTS":
                output = tts_service.infer_f5tts(
                    ref_audio=ref_audio,
                    ref_text=ref_text,
                    gen_text=gen_text,
                    remove_silence=remove_silence,
                    speed=speed
                )
                info = f"✓ F5-TTS 生成成功\n路径: {output}"
            else:  # IndexTTS2
                emo_vector = [
                    emo_happy, emo_angry, emo_sad, emo_fear,
                    emo_disgust, emo_low, emo_surprise, emo_calm
                ]
                
                output = tts_service.infer_indextts(
                    ref_audio=ref_audio,
                    gen_text=gen_text,
                    emo_audio=emo_audio if emo_audio else None,
                    emo_vector=emo_vector,
                    emo_alpha=emo_alpha
                )
                info = f"✓ IndexTTS2 生成成功\n路径: {output}\n情感向量: {emo_vector}"
            
            return output, info
        
        except Exception as e:
            error_msg = f"✗ 生成失败: {str(e)}"
            print(error_msg)
            return None, error_msg
    
    # 创建界面
    with gr.Blocks(title="统一 TTS 服务") as app:
        gr.Markdown("""
        # 🎙️ 统一 TTS 服务
        
        集成 F5-TTS 和 IndexTTS2，提供强大的语音合成能力
        
        - **F5-TTS**: 快速、高质量的语音合成
        - **IndexTTS2**: 丰富的情感控制（8维情感向量）
        """)
        
        with gr.Row():
            with gr.Column():
                engine_choice = gr.Radio(
                    choices=["F5-TTS", "IndexTTS2"],
                    value="F5-TTS",
                    label="选择 TTS 引擎"
                )
                
                ref_audio = gr.Audio(
                    label="参考音频（音色）",
                    type="filepath"
                )
                
                ref_text = gr.Textbox(
                    label="参考文本（F5-TTS 需要）",
                    placeholder="参考音频的文字内容...",
                    lines=2
                )
                
                gen_text = gr.Textbox(
                    label="目标文本",
                    placeholder="要合成的文字内容...",
                    lines=5
                )
                
                generate_btn = gr.Button("🎵 生成语音", variant="primary")
            
            with gr.Column():
                audio_output = gr.Audio(label="生成的音频")
                info_output = gr.Textbox(label="状态信息", lines=5)
        
        # F5-TTS 参数
        with gr.Accordion("F5-TTS 参数", open=False):
            with gr.Row():
                remove_silence = gr.Checkbox(label="移除静音", value=False)
                speed = gr.Slider(label="语速", minimum=0.5, maximum=2.0, value=1.0, step=0.1)
                nfe_steps = gr.Slider(label="NFE Steps", minimum=4, maximum=64, value=32, step=2)
        
        # IndexTTS 参数
        with gr.Accordion("IndexTTS2 参数", open=False):
            emo_audio = gr.Audio(label="情感参考音频（可选）", type="filepath")
            emo_alpha = gr.Slider(label="情感强度", minimum=0.0, maximum=1.0, value=0.65, step=0.01)
            
            gr.Markdown("### 8维情感控制")
            with gr.Row():
                with gr.Column():
                    emo_happy = gr.Slider(label="😊 高兴", minimum=0.0, maximum=1.0, value=0.0, step=0.05)
                    emo_angry = gr.Slider(label="😠 愤怒", minimum=0.0, maximum=1.0, value=0.0, step=0.05)
                    emo_sad = gr.Slider(label="😢 悲伤", minimum=0.0, maximum=1.0, value=0.0, step=0.05)
                    emo_fear = gr.Slider(label="😨 害怕", minimum=0.0, maximum=1.0, value=0.0, step=0.05)
                with gr.Column():
                    emo_disgust = gr.Slider(label="🤢 厌恶", minimum=0.0, maximum=1.0, value=0.0, step=0.05)
                    emo_low = gr.Slider(label="😔 低落", minimum=0.0, maximum=1.0, value=0.0, step=0.05)
                    emo_surprise = gr.Slider(label="😲 惊讶", minimum=0.0, maximum=1.0, value=0.0, step=0.05)
                    emo_calm = gr.Slider(label="😌 平静", minimum=0.0, maximum=1.0, value=0.0, step=0.05)
        
        # 绑定事件
        generate_btn.click(
            fn=infer_wrapper,
            inputs=[
                engine_choice, ref_audio, ref_text, gen_text,
                remove_silence, speed, nfe_steps,
                emo_audio, emo_alpha,
                emo_happy, emo_angry, emo_sad, emo_fear,
                emo_disgust, emo_low, emo_surprise, emo_calm
            ],
            outputs=[audio_output, info_output]
        )
    
    return app


def gradio_auth(username: str, password: str) -> bool:
    """Gradio 认证函数"""
    if not ENABLE_AUTH:
        return True
    
    if username == ADMIN_USERNAME and password == ADMIN_PASSWORD:
        print(f"✓ 管理员 '{username}' 登录成功")
        return True
    
    print(f"✗ 登录失败: 用户名或密码错误")
    return False


def main():
    parser = argparse.ArgumentParser(description="统一 TTS 服务")
    parser.add_argument("--port", type=int, default=7860, help="服务端口")
    parser.add_argument("--host", type=str, default="0.0.0.0", help="服务主机")
    parser.add_argument("--share", action="store_true", help="创建公开链接")
    parser.add_argument("--fp16", action="store_true", help="使用 FP16 推理")
    parser.add_argument("--cpu", action="store_true", help="使用 CPU 推理模式")
    parser.add_argument("--deepspeed", action="store_true", help="使用 DeepSpeed 加速")
    parser.add_argument("--f5tts-model-dir", default="/workspace/F5-TTS", help="F5-TTS 模型目录")
    parser.add_argument("--indextts-model-dir", default="/workspace/index-tts/checkpoints", help="IndexTTS 模型目录")
    
    args = parser.parse_args()
    
    # 从环境变量读取 CPU 设置
    use_cpu = args.cpu or os.getenv('USE_CPU', 'false').lower() == 'true'
    use_fp16 = args.fp16 or os.getenv('USE_FP16', 'false').lower() == 'true'
    
    # 初始化服务
    tts_service = UnifiedTTSService(
        f5tts_model_dir=args.f5tts_model_dir,
        indextts_model_dir=args.indextts_model_dir,
        use_fp16=use_fp16,
        use_deepspeed=args.deepspeed,
        use_cpu=use_cpu
    )
    
    # 创建界面
    app = create_gradio_interface(tts_service)
    
    # 配置认证
    auth_config = {}
    if ENABLE_AUTH:
        print("\n" + "="*60)
        print("🔒 管理员认证已启用")
        print(f"   用户名: {ADMIN_USERNAME}")
        print(f"   密码: {'*' * len(ADMIN_PASSWORD)}")
        print("="*60 + "\n")
        auth_config['auth'] = gradio_auth
        auth_config['auth_message'] = "请使用管理员账号登录统一 TTS 服务"
    else:
        print("\n" + "="*60)
        print("⚠️  管理员认证已禁用")
        print("="*60 + "\n")
    
    # 启动服务
    app.queue().launch(
        server_name=args.host,
        server_port=args.port,
        share=args.share,
        show_api=True,
        **auth_config
    )


if __name__ == "__main__":
    main()
