#!/usr/bin/env bash
# Quick start: ensure CDDA is running and in playing state
# Run this BEFORE running the harness
# IMPORTANT: Do NOT kill the session between runs - keep it alive!

set -euo pipefail

SESSION="${SESSION:-cdda-text}"
ROOT="/home/indows/projects/cdda-moonbit-workspace"
LOGDIR="$ROOT/project-rebuild/03-agent-play-harness/runs/$(date +%Y%m%d-%H%M%S)"
mkdir -p "$LOGDIR"

log() { echo "[$(date +%H:%M:%S)] $1"; }

# 1. Check if session exists
if tmux has-session -t "$SESSION" 2>/dev/null; then
    log "Session $SESSION exists"
else
    log "Starting new CDDA session..."
    cd "$ROOT/repos/Cataclysm-DDA"
    tmux new-session -d -s "$SESSION" "TERM=xterm-256color ./cataclysm --basepath . --userdir ./.cdda-user"
    sleep 3
fi

# 2. Resize window (CDDA needs 80x24 minimum)
tmux resize-window -t "$SESSION" -x 80 -y 24 2>/dev/null || true

# 3. Check current state
SCREEN=$(tmux capture-pane -t "$SESSION" -p)

# 4. If at main menu, navigate to playing state
if echo "$SCREEN" | grep -q "\[MOTD\]\|\[New Game\]\|\[Load\]"; then
    log "At main menu, starting new game..."
    
    # n -> character creation
    tmux send-keys -t "$SESSION" "n"
    sleep 2
    
    # Check if at character creation (Play Now! or similar)
    SCREEN=$(tmux capture-pane -t "$SESSION" -p)
    
    # Enter to proceed
    tmux send-keys -t "$SESSION" "Enter"
    sleep 2
    
    # Tab×6 to navigate through all tabs to confirmation
    log "Navigating through character creation..."
    for i in $(seq 1 6); do
        tmux send-keys -t "$SESSION" "Tab"
        sleep 0.8
    done
    sleep 1
    
    # Y to confirm
    tmux send-keys -t "$SESSION" "Y"
    sleep 3
fi

# 5. If in look-around mode (shows "e - Show extended description"), exit to main map
SCREEN=$(tmux capture-pane -t "$SESSION" -p)
if echo "$SCREEN" | grep -q "e - Show extended description"; then
    log "In look-around mode, exiting to main map..."
    tmux send-keys -t "$SESSION" "Escape"
    sleep 2
fi

# 6. Wait for game to be ready (wait for HUD with Date: and Place:)
log "Waiting for game to load..."
for i in $(seq 1 60); do
    sleep 1
    SCREEN=$(tmux capture-pane -t "$SESSION" -p)
    
    # Real game HUD: Date: and Place: on left side, @ anywhere on map
    HAS_DATE=$(echo "$SCREEN" | grep -c "^.*Date:.*[A-Z].*")
    HAS_PLACE=$(echo "$SCREEN" | grep -c "^.*Place:.*[a-z]")
    HAS_PLAYER=$(echo "$SCREEN" | grep -c "@")
    
    if [ "$HAS_DATE" -ge 1 ] && [ "$HAS_PLACE" -ge 1 ] && [ "$HAS_PLAYER" -ge 1 ]; then
        log "SUCCESS: Game is running (waited ${i}s)"
        echo "$SCREEN" > "$LOGDIR/00-game-started.txt"
        echo "Game started: $LOGDIR/00-game-started.txt"
        exit 0
    fi
    
    if [ $((i % 15)) -eq 0 ]; then
        log "Still waiting... (${i}s)"
    fi
done

log "WARNING: Game may not be ready after 60s"
SCREEN=$(tmux capture-pane -t "$SESSION" -p)
echo "$SCREEN" > "$LOGDIR/00-game-state.txt"
log "State saved: $LOGDIR/00-game-state.txt"
exit 1
