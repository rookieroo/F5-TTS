#!/usr/bin/env python3
"""
F5-TTS Gradio 认证包装器
为 Gradio 应用添加管理员身份验证功能
"""

import os
import sys
from functools import wraps

def check_auth():
    """检查是否启用认证"""
    return os.getenv('ENABLE_AUTH', 'true').lower() == 'true'

def get_admin_credentials():
    """获取管理员凭证"""
    username = os.getenv('ADMIN_USERNAME', 'admin')
    password = os.getenv('ADMIN_PASSWORD', 'changeme')
    return username, password

def gradio_auth(username: str, password: str) -> bool:
    """
    Gradio 认证函数
    返回 True 允许访问，False 拒绝访问
    """
    if not check_auth():
        return True  # 如果未启用认证，允许所有访问
    
    admin_user, admin_pass = get_admin_credentials()
    
    # 验证用户名和密码
    if username == admin_user and password == admin_pass:
        print(f"✓ 管理员 '{username}' 登录成功")
        return True
    
    print(f"✗ 登录失败: 用户名或密码错误 (尝试用户: {username})")
    return False

def create_gradio_app():
    """创建带认证的 Gradio 应用"""
    # 导入原始的 infer_gradio 模块
    from f5_tts.infer import infer_gradio
    
    # 获取原始的 app 和 main 函数
    original_main = infer_gradio.main
    original_app = infer_gradio.app
    
    # 如果启用认证，为 app 添加认证
    if check_auth():
        print("\n" + "="*60)
        print("🔒 管理员认证已启用")
        admin_user, admin_pass = get_admin_credentials()
        print(f"   用户名: {admin_user}")
        print(f"   密码: {'*' * len(admin_pass)}")
        print("="*60 + "\n")
        
        # 修改 launch 方法，添加认证
        original_launch = original_app.launch
        
        def auth_launch(*args, **kwargs):
            kwargs['auth'] = gradio_auth
            kwargs['auth_message'] = "请使用管理员账号登录 F5-TTS"
            return original_launch(*args, **kwargs)
        
        original_app.launch = auth_launch
    else:
        print("\n" + "="*60)
        print("⚠️  管理员认证已禁用 - 所有人都可以访问")
        print("="*60 + "\n")
    
    return original_main

if __name__ == "__main__":
    # 检查 CPU 模式参数
    import argparse
    parser = argparse.ArgumentParser()
    parser.add_argument("--cpu", action="store_true", help="使用 CPU 模式")
    parser.add_argument("--port", type=int, default=7860, help="服务端口")
    parser.add_argument("--host", type=str, default="0.0.0.0", help="服务主机")
    parser.add_argument("--api", action="store_true", help="启用 API")
    args, unknown = parser.parse_known_args()
    
    # 设置 CPU 模式环境变量
    if args.cpu:
        os.environ["CUDA_VISIBLE_DEVICES"] = ""
        os.environ["USE_CPU"] = "true"
        print("🖥️  使用 CPU 推理模式")
    
    # 启动带认证的应用
    main = create_gradio_app()
    
    # 传递剩余的命令行参数
    import sys
    sys.argv = [sys.argv[0]] + unknown
    if args.port != 7860:
        sys.argv.extend(["--port", str(args.port)])
    if args.host != "0.0.0.0":
        sys.argv.extend(["--host", args.host])
    if args.api:
        sys.argv.append("--api")
    
    main()
