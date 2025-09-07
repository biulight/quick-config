#!/bin/bash

# 代理设置脚本
# HTTP代理端口: 6152
# SOCKS5代理端口: 6153

HTTP_PROXY_PORT=6152
SOCKS5_PROXY_PORT=6153
HTTP_PROXY="http://127.0.0.1:${HTTP_PROXY_PORT}"
SOCKS5_PROXY="socks5://127.0.0.1:${SOCKS5_PROXY_PORT}"

echo "🚀 设置代理配置..."

# 检测SOCKS5代理是否可用
check_socks5_proxy() {
    # 方法1：使用netcat检测SOCKS5端口是否开放
    if command -v nc >/dev/null 2>&1; then
        if nc -z 127.0.0.1 ${SOCKS5_PROXY_PORT} 2>/dev/null; then
            echo "🔍 使用netcat检测到SOCKS5代理端口开放"
            return 0
        fi
    fi
    
    # 方法2：使用lsof检查端口是否被监听
    if command -v lsof >/dev/null 2>&1; then
        if lsof -i :${SOCKS5_PROXY_PORT} >/dev/null 2>&1; then
            echo "🔍 使用lsof检测到SOCKS5代理端口被监听"
            return 0
        fi
    fi
    
    # 方法3：使用netstat检查端口
    if command -v netstat >/dev/null 2>&1; then
        if netstat -an 2>/dev/null | grep -q ":${SOCKS5_PROXY_PORT}.*LISTEN"; then
            echo "🔍 使用netstat检测到SOCKS5代理端口监听中"
            return 0
        fi
    fi
    
    # 方法4：使用telnet作为最后的备选方案
    if command -v telnet >/dev/null 2>&1; then
        if timeout 2 telnet 127.0.0.1 ${SOCKS5_PROXY_PORT} </dev/null >/dev/null 2>&1; then
            echo "🔍 使用telnet检测到SOCKS5代理可连接"
            return 0
        fi
    fi
    
    return 1
}

# 优先使用SOCKS5代理，不可用时使用HTTP代理
if check_socks5_proxy; then
    echo "✅ SOCKS5代理可用，优先使用SOCKS5代理"
    PREFERRED_PROXY="${SOCKS5_PROXY}"
    PROXY_TYPE="SOCKS5"
else
    echo "⚠️  SOCKS5代理不可用，回退到HTTP代理"
    PREFERRED_PROXY="${HTTP_PROXY}"
    PROXY_TYPE="HTTP"
fi

# 设置系统环境变量代理
export http_proxy="${PREFERRED_PROXY}"
export https_proxy="${PREFERRED_PROXY}"
export HTTP_PROXY="${PREFERRED_PROXY}"
export HTTPS_PROXY="${PREFERRED_PROXY}"
export all_proxy="${PREFERRED_PROXY}"
export ALL_PROXY="${PREFERRED_PROXY}"

# 设置不使用代理的地址
export no_proxy="localhost,127.0.0.1,::1,.local"
export NO_PROXY="localhost,127.0.0.1,::1,.local"

# Git、NPM等工具通常不支持SOCKS5，使用HTTP代理
# 注意：这里使用原始HTTP代理地址，不是被SOCKS5覆盖的变量
HTTP_PROXY_ORIGINAL="http://127.0.0.1:${HTTP_PROXY_PORT}"
if [ "$PROXY_TYPE" = "SOCKS5" ]; then
    echo "🔧 配置Git代理（使用HTTP代理，因为Git不支持SOCKS5）..."
    TOOL_PROXY="${HTTP_PROXY_ORIGINAL}"
else
    echo "🔧 配置Git代理..."
    TOOL_PROXY="${HTTP_PROXY_ORIGINAL}"
fi

git config --global http.proxy "${TOOL_PROXY}"
git config --global https.proxy "${TOOL_PROXY}"

# 设置NPM代理
echo "📦 配置NPM代理..."
npm config set proxy "${TOOL_PROXY}"
npm config set https-proxy "${TOOL_PROXY}"
npm config set registry https://registry.npmjs.org/

# 设置Yarn代理（如果有的话）
if command -v yarn >/dev/null 2>&1; then
    echo "🧶 配置Yarn代理..."
    yarn config set proxy "${TOOL_PROXY}"
    yarn config set https-proxy "${TOOL_PROXY}"
fi

# 设置pnpm代理（如果有的话）
if command -v pnpm >/dev/null 2>&1; then
    echo "📌 配置pnpm代理..."
    pnpm config set proxy "${TOOL_PROXY}"
    pnpm config set https-proxy "${TOOL_PROXY}"
fi

# 设置gemini-cli代理（如果有的话）
if command -v gemini >/dev/null 2>&1; then
    echo "💎 配置gemini-cli代理..."
    # gemini-cli 使用系统环境变量，但为了确保兼容性，也设置特定的代理环境变量
    export GEMINI_PROXY="${PREFERRED_PROXY}"
    export GEMINI_HTTP_PROXY="${TOOL_PROXY}"
    export GEMINI_HTTPS_PROXY="${TOOL_PROXY}"
    
    # 为gemini命令创建代理别名，因为gemini需要显式指定--proxy参数
    alias gemini="command gemini --proxy '${TOOL_PROXY}'"
fi

echo "✅ 代理设置完成！"
echo ""
echo "当前代理配置："
echo "系统代理类型: ${PROXY_TYPE}"
echo "系统代理地址: ${PREFERRED_PROXY}"
echo "工具代理地址: ${TOOL_PROXY}"
echo "HTTP代理: ${HTTP_PROXY_ORIGINAL}"
echo "SOCKS5代理: ${SOCKS5_PROXY}"
if command -v gemini >/dev/null 2>&1; then
    echo "gemini-cli代理: ✅ 已配置"
else
    echo "gemini-cli代理: ❌ 未安装"
fi
echo ""
echo "要取消代理设置，请运行: source ~/bin/unset_proxy.sh"
