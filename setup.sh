#!/usr/bin/env bash
set -euo pipefail

echo "=== CDDA Live Demo 设置检查 ==="

# 检查 tmux
if command -v tmux >/dev/null 2>&1; then
    echo "[OK] tmux: $(tmux -V)"
else
    echo "[ERROR] tmux 未安装"
    echo ""
    echo "安装方法:"
    echo "  Ubuntu/Debian: sudo apt install tmux"
    echo "  macOS: brew install tmux"
    echo "  Fedora: sudo dnf install tmux"
    exit 1
fi

# 检查 CDDA 二进制
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CDDA_BIN="$SCRIPT_DIR/bin/cataclysm"

if [ -x "$CDDA_BIN" ]; then
    echo "[OK] CDDA: $CDDA_BIN"
else
    echo "[WARN] CDDA 二进制未找到: $CDDA_BIN"
    echo ""
    echo "请运行: ./scripts/download-cdda.sh"
    echo "或手动下载: https://github.com/CleverRaven/Cataclysm-DDA/releases"
fi

# 检查 MoonBit (可选)
if command -v moon >/dev/null 2>&1; then
    echo "[OK] MoonBit: $(moon --version 2>/dev/null || echo 'installed')"
else
    echo "[INFO] MoonBit 未安装 (可选，用于开发)"
fi

echo ""
echo "设置检查完成!"
echo ""
echo "下一步:"
echo "  1. 下载 CDDA: ./scripts/download-cdda.sh"
echo "  2. 启动游戏: ./start.sh"
echo "  3. 开始直播: /游戏开始 (在 OpenClaw 中)"
