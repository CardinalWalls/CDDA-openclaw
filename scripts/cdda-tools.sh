#!/usr/bin/env bash
# CDDA Agent Tools - Clean Abstraction Layer
# Agent calls these functions, never touches raw keys or raw output
# Key principle: return RAW output, never filter

SESSION="${CDDA_SESSION:-cdda-text}"
LOG_DIR="${CDDA_LOG_DIR:-/home/indows/projects/cdda-moonbit-workspace/project-rebuild/03-agent-play-harness/runs}"
TIMESTAMP="${CDDA_TIMESTAMP:-$(date +%Y%m%d-%H%M%S)}"

# Internal: send key
send_key() {
    local key="$1"
    tmux send-keys -t "$SESSION" "$key"
    sleep 0.8
}

# Internal: capture FULL screen (raw)
capture() {
    tmux capture-pane -t "$SESSION" -p
}

# Internal: get player position line
get_position() {
    capture | grep '@' | head -1
}

# Internal: get time
get_time() {
    capture | grep 'Time:' | head -1
}

# Internal: get place
get_place() {
    capture | grep 'Place:' | head -1
}

# ============================================
# CLEAN TOOLS - Agent uses these
# All return RAW output
# ============================================

# Look around - returns FULL screen
look_around() {
    send_key "x"
    sleep 1.5
    capture
}

# Extended description - returns FULL screen
extended_description() {
    send_key "e"
    sleep 1
    capture
}

# Check inventory - returns FULL screen
check_inventory() {
    send_key "i"
    sleep 1
    capture
}

# Check character sheet - returns FULL screen
check_character() {
    send_key "@"
    sleep 1
    capture
}

# List nearby items - returns FULL screen
list_items() {
    send_key "*"
    sleep 1
    capture
}

# Move west - returns BEFORE + AFTER + TIME
move_west() {
    local before=$(get_position)
    send_key "h"
    sleep 1.5
    local after=$(get_position)
    local time=$(get_time)
    echo "=== MOVE WEST ==="
    echo "Before: $before"
    echo "After: $after"
    echo "Time: $time"
    echo "================"
}

# Move east
move_east() {
    local before=$(get_position)
    send_key "l"
    sleep 1.5
    local after=$(get_position)
    local time=$(get_time)
    echo "=== MOVE EAST ==="
    echo "Before: $before"
    echo "After: $after"
    echo "Time: $time"
    echo "================"
}

# Move north
move_north() {
    local before=$(get_position)
    send_key "k"
    sleep 1.5
    local after=$(get_position)
    local time=$(get_time)
    echo "=== MOVE NORTH ==="
    echo "Before: $before"
    echo "After: $after"
    echo "Time: $time"
    echo "================="
}

# Move south
move_south() {
    local before=$(get_position)
    send_key "j"
    sleep 1.5
    local after=$(get_position)
    local time=$(get_time)
    echo "=== MOVE SOUTH ==="
    echo "Before: $before"
    echo "After: $after"
    echo "Time: $time"
    echo "================="
}

# Wait - pass turn
wait_turn() {
    send_key "."
    sleep 1
    local time=$(get_time)
    echo "Time after wait: $time"
}

# Open door
open_door() {
    send_key "o"
    sleep 1
    capture
}

# Close door
close_door() {
    send_key "c"
    sleep 1
    capture
}

# Pick up item
pick_up() {
    send_key ","
    sleep 1
    capture
}

# Wear item
wear_item() {
    send_key "W"
    sleep 1
    capture
}

# Wield item
wield_item() {
    send_key "w"
    sleep 1
    capture
}

# Check overmap
check_overmap() {
    send_key "m"
    sleep 1
    capture
}

# Check messages
check_messages() {
    send_key "?"
    sleep 1
    capture
}

# Exit to main map
exit_to_map() {
    send_key "Escape"
    sleep 1
    capture
}

# Save game
save_game() {
    send_key "s"
    sleep 1
    capture
}

# Get status - structured summary
get_status() {
    echo "=== CDDA STATUS ==="
    echo "Time: $(get_time)"
    echo "Place: $(get_place)"
    echo "Position: $(get_position)"
    echo "==================="
    echo ""
    echo "=== RAW STATUS PANEL ==="
    capture | grep -E "Str:|Dex:|Int:|Per:|HP|Speed:|Stam:|Pain:|Thirst:|Hunger:|Wield:|Date:|Time:|Place:" | head -15
    echo "========================"
}

# ============================================
# REPL MODE - runs in tools session
# Uses eval to call functions properly
# ============================================

REPL() {
    mkdir -p "$LOG_DIR"
    local log_file="$LOG_DIR/${TIMESTAMP}-clean-demo.md"
    local round=1
    
    echo "CDDA Tools REPL ready"
    echo "Type function name to execute, 'status' for full status, 'log' for log file, 'quit' to exit"
    echo ""
    
    while true; do
        echo -n "> "
        read cmd
        
        if [ "$cmd" = "quit" ] || [ "$cmd" = "exit" ]; then
            echo "Goodbye"
            break
        fi
        
        if [ "$cmd" = "log" ]; then
            echo "Log: $log_file"
            continue
        fi
        
        if [ "$cmd" = "status" ]; then
            get_status
            continue
        fi
        
        if [ -z "$cmd" ]; then
            continue
        fi
        
        # Use eval to call the function
        local result
        result=$(eval "$cmd" 2>&1)
        
        # Print result
        echo "$result"
        
        # Auto-log to file
        {
            echo "---"
            echo "[Round $round] $cmd"
            echo "$result"
        } >> "$log_file"
        
        round=$((round + 1))
    done
}

# ============================================
# DISPATCH
# ============================================

CMD="${1:-}"
shift || true

case "$CMD" in
    REPL)              REPL "$@" ;;
    look_around)        look_around "$@" ;;
    extended_description) extended_description "$@" ;;
    check_inventory)    check_inventory "$@" ;;
    check_character)   check_character "$@" ;;
    list_items)         list_items "$@" ;;
    move_west)          move_west "$@" ;;
    move_east)          move_east "$@" ;;
    move_north)         move_north "$@" ;;
    move_south)         move_south "$@" ;;
    wait_turn)          wait_turn "$@" ;;
    open_door)          open_door "$@" ;;
    close_door)         close_door "$@" ;;
    pick_up)            pick_up "$@" ;;
    wear_item)          wear_item "$@" ;;
    wield_item)         wield_item "$@" ;;
    check_overmap)      check_overmap "$@" ;;
    exit_to_map)        exit_to_map "$@" ;;
    save_game)          save_game "$@" ;;
    get_status)         get_status "$@" ;;
    send_key)           send_key "$@" ;;
    capture)            capture "$@" ;;
    get_position)      get_position "$@" ;;
    get_time)           get_time "$@" ;;
    get_place)          get_place "$@" ;;
    *) echo "Unknown command: $CMD"
       echo "Available: look_around, extended_description, check_inventory, check_character, list_items"
       echo "            move_west, move_east, move_north, move_south, wait_turn"
       echo "            open_door, close_door, pick_up, wear_item, wield_item"
       echo "            check_overmap, exit_to_map, save_game, get_status, capture"
       echo "            REPL (interactive mode)"
       ;;
esac
