#!/bin/bash
# Claude Code Agent Dashboard - tmux 패널에서 에이전트 상태를 실시간 표시
# agent_tmux_hook.sh에서 자동 호출됨

STATUS_DIR="${1:-/tmp/claude_agent_status}"
REFRESH=2  # seconds

# Colors
C_RESET='\033[0m'
C_BOLD='\033[1m'
C_GREEN='\033[32m'
C_YELLOW='\033[33m'
C_BLUE='\033[34m'
C_CYAN='\033[36m'
C_RED='\033[31m'
C_DIM='\033[2m'

# Spinner frames
SPIN=('⠋' '⠙' '⠹' '⠸' '⠼' '⠴' '⠦' '⠧' '⠇' '⠏')

frame=0
while true; do
    clear
    COLS=$(tput cols 2>/dev/null || echo 80)

    # Header
    echo -e "${C_BOLD}${C_CYAN}━━━ Claude Agent Team Dashboard ━━━${C_RESET}  ${C_DIM}$(date '+%H:%M:%S')${C_RESET}"
    echo ""

    # Count agents
    TOTAL=0
    RUNNING=0
    DONE=0

    if [ -d "$STATUS_DIR" ] && ls "$STATUS_DIR"/*.status &>/dev/null; then
        # Collect agents
        for f in "$STATUS_DIR"/*.status; do
            TOTAL=$((TOTAL + 1))
            source "$f"

            SPINNER=""
            STATUS_COLOR="$C_YELLOW"
            STATUS_ICON="..."

            if [ "$status" = "running" ]; then
                RUNNING=$((RUNNING + 1))
                SPINNER="${SPIN[$((frame % ${#SPIN[@]}))]}"
                STATUS_COLOR="$C_YELLOW"
                STATUS_ICON="$SPINNER running"
            elif [ "$status" = "completed" ]; then
                DONE=$((DONE + 1))
                STATUS_COLOR="$C_GREEN"
                STATUS_ICON="✓ done"
            elif [ "$status" = "error" ]; then
                STATUS_COLOR="$C_RED"
                STATUS_ICON="✗ error"
            fi

            printf "  ${C_BOLD}%-18s${C_RESET} ${STATUS_COLOR}%-12s${C_RESET} ${C_DIM}%s${C_RESET}\n" \
                "$name" "$STATUS_ICON" "$description"
        done
    else
        echo -e "  ${C_DIM}Waiting for agents...${C_RESET}"
    fi

    echo ""
    # Progress bar
    if [ $TOTAL -gt 0 ]; then
        PCT=$((DONE * 100 / TOTAL))
        BAR_WIDTH=$((COLS - 30))
        [ $BAR_WIDTH -gt 50 ] && BAR_WIDTH=50
        FILLED=$((DONE * BAR_WIDTH / TOTAL))
        EMPTY=$((BAR_WIDTH - FILLED))
        BAR=$(printf '%*s' "$FILLED" '' | tr ' ' '█')
        BAR_E=$(printf '%*s' "$EMPTY" '' | tr ' ' '░')
        echo -e "  ${C_BOLD}Progress:${C_RESET} [${C_GREEN}${BAR}${C_DIM}${BAR_E}${C_RESET}] ${C_BOLD}${DONE}/${TOTAL}${C_RESET} (${PCT}%)"
    fi

    # Auto-exit when all done
    if [ $TOTAL -gt 0 ] && [ $RUNNING -eq 0 ] && [ $DONE -eq $TOTAL ]; then
        echo -e "\n  ${C_GREEN}${C_BOLD}All agents completed!${C_RESET} ${C_DIM}(closing in 10s)${C_RESET}"
        sleep 10
        exit 0
    fi

    frame=$((frame + 1))
    sleep $REFRESH
done
