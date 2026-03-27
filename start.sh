#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CDDA_BIN="$SCRIPT_DIR/bin/cataclysm"
SESSION="${SESSION:-cdda-text}"
LOGDIR="$SCRIPT_DIR/runs/$(date +%Y%m%d-%H%M%S)"

mkdir -p "$LOGDIR"
mkdir -p "$SCRIPT_DIR/bin"

# 检查 tmux
if ! command -v tmux >/dev/null 2>&1; then
    echo "ERROR: tmux 未安装"
    exit 1
fi

# 检查 CDDA
if [ ! -x "$CDDA_BIN" ]; then
    echo "ERROR: CDDA 二进制未找到: $CDDA_BIN"
    echo "请先运行: ./scripts/download-cdda.sh"
    exit 1
fi

echo "=== 启动 CDDA ==="
echo "Session: $SESSION"
echo "Binary: $CDDA_BIN"

# 杀掉已有 session
if tmux has-session -t "$SESSION" 2>/dev/null; then
    echo "杀掉已有 session..."
    tmux kill-session -t "$SESSION"
fi

# 启动新 session
echo "启动 tmux session..."
tmux new-session -d -s "$SESSION" -c "$SCRIPT_DIR/bin" \
    "TERM=xterm-256color ./cataclysm --basepath . --userdir ./.cdda-user"

echo "等待游戏启动..."
sleep 3

# 检查当前状态
check_game_ready() {
    local screen
    screen=$(tmux capture-pane -t "$SESSION" -p 2>/dev/null || echo "")
    
    local has_date=$(echo "$screen" | grep -c "^.*Date:.*[A-Z].*" || true)
    local has_place=$(echo "$screen" | grep -c "^.*Place:.*[a-z]" || true)
    local has_player=$(echo "$screen" | grep -c "@" || true)
    
    [ "$has_date" -ge 1 ] && [ "$has_place" -ge 1 ] && [ "$has_player" -ge 1 ]
}

# 等待游戏就绪或处理主菜单
wait_for_game() {
    local waited=0
    local max_wait=60
    
    while [ $waited -lt $max_wait ]; do
        local screen
        screen=$(tmux capture-pane -t "$SESSION" -p 2>/dev/null || echo "")
        
        # 检查是否在主菜单
        if echo "$screen" | grep -qE "\[MOTD\]|\[New Game\]|\[Load\]"; then
            echo "检测到主菜单，开始新游戏..."
            tmux send-keys -t "$SESSION" "n"
            sleep 2
            
            # 按 Enter 进入游戏
            tmux send-keys -t "$SESSION" "Enter"
            sleep 2
            
            # Tab 导航 + Y 确认 (快速创建角色)
            echo "创建角色..."
            for i in $(seq 1 6); do
                tmux send-keys -t "$SESSION" "Tab"
                sleep 0.5
            done
            sleep 1
            tmux send-keys -t "$SESSION" "Y"
            sleep 3
        fi
        
        # 检查是否在 look around 模式
        if echo "$screen" | grep -q "e - Show extended description"; then
            echo "退出 look around 模式..."
            tmux send-keys -t "$SESSION" "Escape"
            sleep 2
        fi
        
        # 检查游戏是否就绪
        if check_game_ready; then
            echo "游戏就绪! (等待 ${waited}s)"
            return 0
        fi
        
        sleep 1
        waited=$((waited + 1))
        
        if [ $((waited % 10)) -eq 0 ]; then
            echo "仍在等待... (${waited}s)"
        fi
    done
    
    echo "WARNING: 游戏可能未就绪 (等待 ${max_wait}s)"
    return 1
}

wait_for_game

# 保存初始状态
tmux capture-pane -t "$SESSION" -p > "$LOGDIR/00-game-started.txt" 2>/dev/null || true

echo ""
echo "=== CDDA 已启动 ==="
echo ""
echo "查看游戏: tmux attach -t $SESSION"
echo "分离: Ctrl+B 然后 D"
echo "日志目录: $LOGDIR"
echo ""
echo "在 OpenClaw 中使用 /游戏开始 启动直播!"
