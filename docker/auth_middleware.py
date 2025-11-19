#!/usr/bin/env python3
"""
认证中间件 - 用于统一 TTS 服务的身份验证
"""

import os
import hashlib
import hmac
from functools import wraps
from typing import Optional

class AuthMiddleware:
    def __init__(self, username: str, password: str):
        """初始化认证中间件
        
        Args:
            username: 管理员用户名
            password: 管理员密码
        """
        self.username = username
        self.password_hash = self._hash_password(password)
    
    def _hash_password(self, password: str) -> str:
        """对密码进行哈希处理"""
        return hashlib.sha256(password.encode('utf-8')).hexdigest()
    
    def verify_credentials(self, username: str, password: str) -> bool:
        """验证用户凭据
        
        Args:
            username: 用户名
            password: 密码
            
        Returns:
            验证结果
        """
        if username != self.username:
            return False
        
        password_hash = self._hash_password(password)
        return hmac.compare_digest(password_hash, self.password_hash)
    
    def require_auth(self, func):
        """装饰器：要求认证
        
        Args:
            func: 被装饰的函数
            
        Returns:
            装饰后的函数
        """
        @wraps(func)
        def wrapper(*args, **kwargs):
            # 在实际的 Web 框架中，这里会检查请求的认证信息
            # 对于 Gradio，认证由 gradio.auth 处理
            return func(*args, **kwargs)
        return wrapper

# 全局认证实例
auth_middleware = None

def init_auth(username: str, password: str) -> AuthMiddleware:
    """初始化全局认证实例
    
    Args:
        username: 管理员用户名
        password: 管理员密码
        
    Returns:
        认证中间件实例
    """
    global auth_middleware
    auth_middleware = AuthMiddleware(username, password)
    return auth_middleware

def get_auth() -> Optional[AuthMiddleware]:
    """获取全局认证实例
    
    Returns:
        认证中间件实例，如果未初始化则返回 None
    """
    return auth_middleware

# 便捷函数
def verify_user(username: str, password: str) -> bool:
    """验证用户凭据的便捷函数
    
    Args:
        username: 用户名
        password: 密码
        
    Returns:
        验证结果
    """
    auth = get_auth()
    if auth is None:
        return False
    return auth.verify_credentials(username, password)