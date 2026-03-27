#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CDDA_BIN="$SCRIPT_DIR/bin/cataclysm"
SESSION="${SESSION:-cdda-text}"
LOGDIR="$SCRIPT_DIR/runs/$(date +%Y%m%d-%H%M%S)"

echo "=========================================="
echo "  CDDA Live Demo - 启动游戏"
echo "=========================================="
echo ""

mkdir -p "$LOGDIR"
mkdir -p "$SCRIPT_DIR/bin"

FAILED=0

# 1. 检查 tmux
echo "[1/5] 检查 tmux..."
if ! command -v tmux >/dev/null 2>&1; then
    echo "    ✗ tmux 未安装"
    echo ""
    echo "    【解决方法】"
    echo "    Ubuntu/Debian: sudo apt install tmux"
    echo "    macOS: brew install tmux"
    FAILED=1
else
    echo "    ✓ tmux 已就绪"
fi
echo ""

# 2. 检查 CDDA
echo "[2/5] 检查 CDDA..."
if [ ! -x "$CDDA_BIN" ]; then
    echo "    ✗ CDDA 二进制未找到或不可执行"
    echo "    路径: $CDDA_BIN"
    echo ""
    echo "    【解决方法】"
    echo "    运行: ./scripts/download-cdda.sh"
    FAILED=1
else
    CDDA_VERSION=$("$CDDA_BIN" --version 2>&1 | head -1 || echo "unknown")
    echo "    ✓ CDDA 已就绪"
    echo "    版本: $CDDA_VERSION"
fi
echo ""

# 如果前置检查失败，退出
if [ $FAILED -eq 1 ]; then
    echo "=========================================="
    echo "  ✗ 启动失败，请先修复上述问题"
    echo "=========================================="
    exit 1
fi

# 3. 杀掉已有 session
echo "[3/5] 清理旧 session..."
if tmux has-session -t "$SESSION" 2>/dev/null; then
    echo "    发现旧 session，杀掉..."
    tmux kill-session -t "$SESSION" 2>/dev/null || true
    echo "    ✓ 已清理"
else
    echo "    ℹ 没有旧 session"
fi
echo ""

# 4. 启动新 session
echo "[4/5] 启动 CDDA..."
echo "    Session 名称: $SESSION"
echo "    工作目录: $SCRIPT_DIR/bin"
echo "    二进制: ./cataclysm --basepath . --userdir ./.cdda-user"
echo ""

tmux new-session -d -s "$SESSION" -c "$SCRIPT_DIR/bin" \
    "TERM=xterm-256color ./cataclysm --basepath . --userdir ./.cdda-user"

if [ $? -eq 0 ]; then
    echo "    ✓ tmux session 已创建"
else
    echo "    ✗ tmux session 创建失败"
    exit 1
fi

echo "    等待游戏初始化..."
sleep 3
echo ""

# 5. 等待游戏就绪
echo "[5/5] 等待游戏就绪..."

check_game_ready() {
    local screen
    screen=$(tmux capture-pane -t "$SESSION" -p 2>/dev/null || echo "")
    
    local has_date=$(echo "$screen" | grep -c "^.*Date:.*[A-Z].*" || true)
    local has_place=$(echo "$screen" | grep -c "^.*Place:.*[a-z]" || true)
    local has_player=$(echo "$screen" | grep -c "@" || true)
    
    [ "$has_date" -ge 1 ] && [ "$has_place" -ge 1 ] && [ "$has_player" -ge 1 ]
}

get_screen_hint() {
    tmux capture-pane -t "$SESSION" -p 2>/dev/null | grep -oE "\[MOTD\]|\[New Game\]|\[Load\]|Date:|Place:|@|e - Show" | head -3 || echo ""
}

waited=0
max_wait=60
NEED_CREATE_CHARACTER=false

while [ $waited -lt $max_wait ]; do
    local screen
    screen=$(tmux capture-pane -t "$SESSION" -p 2>/dev/null || echo "")
    
    # 检查是否在主菜单
    if echo "$screen" | grep -qE "\[MOTD\]|\[New Game\]|\[Load\]"; then
        if [ "$NEED_CREATE_CHARACTER" = false ]; then
            echo "    检测到主菜单，开始新游戏..."
            echo "    按 'n' 创建新角色..."
            tmux send-keys -t "$SESSION" "n"
            sleep 2
            NEED_CREATE_CHARACTER=true
        fi
    elif echo "$screen" | grep -qE "Play Now!|Yes, let's|" && [ "$NEED_CREATE_CHARACTER" = true ]; then
        echo "    确认角色创建..."
        tmux send-keys -t "$SESSION" "Enter"
        sleep 2
        
        echo "    快速导航 (Tab x 6 + Y)..."
        for i in $(seq 1 6); do
            tmux send-keys -t "$SESSION" "Tab"
            sleep 0.5
            echo "    - Tab $i/6"
        done
        sleep 1
        tmux send-keys -t "$SESSION" "Y"
        sleep 3
        NEED_CREATE_CHARACTER=done
    elif echo "$screen" | grep -q "e - Show extended description"; then
        echo "    退出 look around 模式..."
        tmux send-keys -t "$SESSION" "Escape"
        sleep 2
    fi
    
    # 检查游戏是否就绪
    if check_game_ready; then
        echo "    ✓ 游戏就绪! (耗时 ${waited}s)"
        break
    fi
    
    sleep 1
    waited=$((waited + 1))
    
    if [ $((waited % 10)) -eq 0 ]; then
        echo "    ...仍在等待 (${waited}s)"
        echo "    当前屏幕提示: $(get_screen_hint)"
    fi
done

echo ""

# 保存初始状态
tmux capture-pane -t "$SESSION" -p > "$LOGDIR/00-game-started.txt" 2>/dev/null || true

# 最终检查
if check_game_ready; then
    echo "=========================================="
    echo "  ✓ CDDA 已成功启动！"
    echo "=========================================="
    echo ""
    echo "【查看游戏】"
    echo "  tmux attach -t $SESSION"
    echo ""
    echo "【分离 tmux】（不关闭游戏）"
    echo "  按 Ctrl+B 然后按 D"
    echo ""
    echo "【关闭游戏】"
    echo "  tmux kill-session -t $SESSION"
    echo ""
    echo "【日志目录】"
    echo "  $LOGDIR"
    echo ""
    echo "现在可以在 OpenClaw 中使用:"
    echo "  /游戏开始"
else
    echo "=========================================="
    echo "  ⚠ 游戏可能未完全就绪"
    echo "=========================================="
    echo ""
    echo "请手动检查:"
    echo "  tmux attach -t $SESSION"
    echo ""
    echo "如果卡在主菜单，手动操作:"
    echo "  按 'n' -> Enter -> Tab x 6 -> 'Y'"
fi
