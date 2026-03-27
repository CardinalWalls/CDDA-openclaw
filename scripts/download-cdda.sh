#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BIN_DIR="$SCRIPT_DIR/../bin"

mkdir -p "$BIN_DIR"
cd "$BIN_DIR"

echo "=== 下载 CDDA 文本模式 ==="
echo ""

# 检测系统
OS="$(uname -s)"
ARCH="$(uname -m)"

case "$OS" in
    Linux)
        if [ "$ARCH" = "x86_64" ]; then
            PLATFORM="linux-x64"
        else
            echo "不支持的架构: $ARCH"
            exit 1
        fi
        ;;
    Darwin)
        if [ "$ARCH" = "x86_64" ] || [ "$ARCH" = "arm64" ]; then
            PLATFORM="osx-$ARCH"
        else
            echo "不支持的架构: $ARCH"
            exit 1
        fi
        ;;
    *)
        echo "不支持的操作系统: $OS"
        echo ""
        echo "请手动下载: https://github.com/CleverRaven/Cataclysm-DDA/releases"
        echo "选择 'Tiles' 或 'Console' 版本"
        echo "解压后将 cataclysm 放到 bin/ 目录"
        exit 1
        ;;
esac

# 获取最新版本号
echo "获取最新版本..."
LATEST=$(curl -sL "https://api.github.com/repos/CleverRaven/Cataclysm-DDA/releases/latest" | grep -oP '"tag_name": "\K[^"]+' || echo "")

if [ -z "$LATEST" ]; then
    echo "无法获取最新版本，使用默认版本..."
    LATEST="0.F-3"
fi

echo "最新版本: $LATEST"

# 构建下载 URL (Console 版本 = 文本模式)
FILENAME="cdda-$LATEST-$PLATFORM-console.zip"
URL="https://github.com/CleverRaven/Cataclysm-DDA/releases/download/$LATEST/$FILENAME"

echo ""
echo "下载: $FILENAME"
echo "URL: $URL"
echo ""

if command -v curl >/dev/null 2>&1; then
    curl -L -O "$URL"
elif command -v wget >/dev/null 2>&1; then
    wget "$URL"
else
    echo "ERROR: 需要 curl 或 wget"
    exit 1
fi

# 解压
echo ""
echo "解压..."
if command -v unzip >/dev/null 2>&1; then
    unzip -o "$FILENAME"
elif command -v bsdtar >/dev/null 2>&1; then
    bsdtar -xf "$FILENAME"
else
    echo "ERROR: 需要 unzip 或 bsdtar"
    exit 1
fi

# 查找 cataclysm 可执行文件
if [ -f "./cataclysm" ]; then
    chmod +x ./cataclysm
    echo ""
    echo "=== CDDA 已安装 ==="
    ./cataclysm --version || true
elif [ -f "./cataclysm-tiles" ]; then
    mv ./cataclysm-tiles ./cataclysm
    chmod +x ./cataclysm
    echo ""
    echo "=== CDDA Tiles 版本已安装 ==="
    ./cataclysm --version || true
else
    echo "ERROR: 解压后未找到 cataclysm 可执行文件"
    ls -la
    exit 1
fi

# 清理
rm -f "$FILENAME"

echo ""
echo "CDDA 已安装到: $BIN_DIR/cataclysm"
