#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BIN_DIR="$SCRIPT_DIR/../bin"

echo "=========================================="
echo "  CDDA Live Demo - 下载 CDDA"
echo "=========================================="
echo ""

# 检测系统
OS="$(uname -s)"
ARCH="$(uname -m)"

echo "[1/5] 检测系统..."
echo "    OS: $OS"
echo "    架构: $ARCH"

case "$OS" in
    Linux)
        if [ "$ARCH" = "x86_64" ]; then
            PLATFORM="linux-x64"
            echo "    ✓ Linux x86_64 支持"
        else
            echo "    ✗ 不支持的架构: $ARCH"
            exit 1
        fi
        ;;
    Darwin)
        if [ "$ARCH" = "x86_64" ] || [ "$ARCH" = "arm64" ]; then
            PLATFORM="osx-$ARCH"
            echo "    ✓ macOS $ARCH 支持"
        else
            echo "    ✗ 不支持的架构: $ARCH"
            exit 1
        fi
        ;;
    *)
        echo "    ✗ 不支持的操作系统: $OS"
        echo ""
        echo "请手动下载: https://github.com/CleverRaven/Cataclysm-DDA/releases"
        echo "选择 'Console' 版本，解压到 bin/ 目录"
        exit 1
        ;;
esac
echo ""

# 创建目录
echo "[2/5] 创建目录..."
mkdir -p "$BIN_DIR"
echo "    ✓ 目录已就绪: $BIN_DIR"
echo ""

# 获取最新版本号
echo "[3/5] 获取最新版本..."
LATEST=$(curl -sL "https://api.github.com/repos/CleverRaven/Cataclysm-DDA/releases/latest" | grep -oP '"tag_name": "\K[^"]+' 2>/dev/null || echo "")

if [ -z "$LATEST" ]; then
    echo "    ⚠ 无法获取最新版本，使用稳定版 0.F-3"
    LATEST="0.F-3"
else
    echo "    ✓ 最新版本: $LATEST"
fi
echo ""

# 构建下载 URL
FILENAME="cdda-$LATEST-$PLATFORM-console.zip"
URL="https://github.com/CleverRaven/Cataclysm-DDA/releases/download/$LATEST/$FILENAME"

echo "[4/5] 下载 CDDA 文本模式..."
echo "    文件: $FILENAME"
echo "    链接: $URL"
echo ""

cd "$BIN_DIR"

if command -v curl >/dev/null 2>&1; then
    echo "    使用 curl 下载..."
    echo "    (这可能需要几分钟，取决于网速)"
    echo ""
    
    # 显示下载进度
    curl -L -# -o "$FILENAME" "$URL"
    
    CURL_EXIT=$?
    if [ $CURL_EXIT -ne 0 ]; then
        echo ""
        echo "    ✗ 下载失败 (curl 退出码: $CURL_EXIT)"
        echo ""
        echo "    手动下载方法:"
        echo "    1. 打开: https://github.com/CleverRaven/Cataclysm-DDA/releases"
        echo "    2. 找到版本 $LATEST"
        echo "    3. 下载: $FILENAME"
        echo "    4. 解压到 bin/ 目录"
        exit 1
    fi
    echo "    ✓ 下载完成"
elif command -v wget >/dev/null 2>&1; then
    echo "    使用 wget 下载..."
    wget -q --show-progress "$URL"
    echo "    ✓ 下载完成"
else
    echo "    ✗ 错误: 需要 curl 或 wget"
    echo ""
    echo "    安装方法:"
    echo "    Ubuntu/Debian: sudo apt install curl"
    echo "    macOS: 自带 curl"
    exit 1
fi
echo ""

# 解压
echo "[5/5] 解压 CDDA..."
echo "    查找解压工具..."

if command -v unzip >/dev/null 2>&1; then
    echo "    使用 unzip 解压..."
    unzip -o "$FILENAME"
    echo "    ✓ 解压完成"
elif command -v bsdtar >/dev/null 2>&1; then
    echo "    使用 bsdtar 解压..."
    bsdtar -xf "$FILENAME"
    echo "    ✓ 解压完成"
else
    echo "    ✗ 错误: 需要 unzip 或 bsdtar"
    echo ""
    echo "    安装方法:"
    echo "    Ubuntu/Debian: sudo apt install unzip"
    echo "    macOS: 自带 unzip"
    rm -f "$FILENAME"
    exit 1
fi
echo ""

# 查找 cataclysm 可执行文件
echo "    查找 cataclysm 可执行文件..."
if [ -f "./cataclysm" ]; then
    chmod +x ./cataclysm
    echo "    ✓ 找到: ./cataclysm"
elif [ -f "./cataclysm-tiles" ]; then
    mv ./cataclysm-tiles ./cataclysm
    chmod +x ./cataclysm
    echo "    ✓ 找到 (tiles 版本): ./cataclysm"
else
    echo "    ✗ 错误: 解压后未找到 cataclysm 可执行文件"
    echo ""
    echo "    当前目录内容:"
    ls -la
    echo ""
    echo "    可能是下载的文件格式不同，请检查:"
    echo "    1. 解压下载的文件"
    echo "    2. 找到 cataclysm 或 cataclysm-tiles"
    echo "    3. 移动到 bin/ 目录"
    rm -f "$FILENAME"
    exit 1
fi

# 验证
echo ""
echo "    验证安装..."
CDDA_VERSION=$(./cataclysm --version 2>&1 | head -1 || echo "unknown")
echo "    ✓ 版本: $CDDA_VERSION"

# 清理
rm -f "$FILENAME"

echo ""
echo "=========================================="
echo "  ✓ CDDA 下载并安装完成！"
echo "=========================================="
echo ""
echo "已安装到: $BIN_DIR/cataclysm"
echo ""
echo "下一步:"
echo "  1. 运行 ./setup.sh 验证环境"
echo "  2. 运行 ./start.sh 启动游戏"
echo "  3. 在 OpenClaw 中使用 /游戏开始 启动直播"
