#!/usr/bin/env bash
set -euo pipefail

echo "=========================================="
echo "  CDDA Live Demo - 环境检查"
echo "=========================================="
echo ""

FAILED=0

# 1. 检查 tmux
echo "[1/3] 检查 tmux..."
if command -v tmux >/dev/null 2>&1; then
    TMUX_VERSION=$(tmux -V)
    echo "    ✓ tmux 已安装: $TMUX_VERSION"
else
    echo "    ✗ tmux 未安装"
    echo ""
    echo "    【解决方法】"
    echo "    Ubuntu/Debian: sudo apt install tmux"
    echo "    macOS: brew install tmux"
    echo "    Fedora: sudo dnf install tmux"
    FAILED=1
fi
echo ""

# 2. 检查 CDDA
echo "[2/3] 检查 CDDA 二进制..."
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CDDA_BIN="$SCRIPT_DIR/bin/cataclysm"

if [ -x "$CDDA_BIN" ]; then
    echo "    ✓ CDDA 已找到: $CDDA_BIN"
    CDDA_VERSION=$("$CDDA_BIN" --version 2>&1 | head -1 || echo "unknown")
    echo "    ✓ 版本: $CDDA_VERSION"
else
    echo "    ✗ CDDA 二进制未找到或不可执行: $CDDA_BIN"
    echo ""
    echo "    【解决方法】"
    echo "    运行: ./scripts/download-cdda.sh"
    echo "    或手动下载: https://github.com/CleverRaven/Cataclysm-DDA/releases"
    echo "    选择 'Console' 版本，解压到 bin/ 目录"
    FAILED=1
fi
echo ""

# 3. 检查 MoonBit (可选)
echo "[3/3] 检查 MoonBit (可选)..."
if command -v moon >/dev/null 2>&1; then
    MOON_VERSION=$(moon --version 2>&1 | head -1 || echo "installed")
    echo "    ✓ MoonBit: $MOON_VERSION"
else
    echo "    ℹ MoonBit 未安装 (可选，用于开发)"
fi
echo ""

echo "=========================================="
if [ $FAILED -eq 0 ]; then
    echo "  ✓ 环境检查通过！"
    echo "=========================================="
    echo ""
    echo "下一步:"
    echo "  1. 首次运行: ./scripts/download-cdda.sh"
    echo "  2. 启动游戏: ./start.sh"
    echo "  3. 开始直播: /游戏开始 (在 OpenClaw 中)"
else
    echo "  ✗ 环境检查未通过，请修复上述问题"
    echo "=========================================="
    exit 1
fi
