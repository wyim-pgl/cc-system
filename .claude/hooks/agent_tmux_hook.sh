#!/bin/bash
# Claude Code Agent → tmux monitor hook
# PostToolUse hook: Agent 호출 시 자동으로 tmux 대시보드 패널 생성/업데이트
# 사용법: settings.json의 PostToolUse Agent matcher에 등록

STATUS_DIR="/tmp/claude_agent_status_$$"
STATUS_DIR="${CLAUDE_AGENT_STATUS_DIR:-/tmp/claude_agent_status}"
DASHBOARD_PANE_FILE="$STATUS_DIR/.dashboard_pane"

mkdir -p "$STATUS_DIR"

# Read tool result from stdin
INPUT=$(cat)

# Parse agent info from JSON
AGENT_NAME=$(echo "$INPUT" | jq -r '.tool_result // empty' | grep -oP 'name: \K[^\n]+' | head -1)
AGENT_ID=$(echo "$INPUT" | jq -r '.tool_result // empty' | grep -oP 'agent_id: \K[^\n]+' | head -1)
DESCRIPTION=$(echo "$INPUT" | jq -r '.tool_input.description // "agent"')
BACKGROUND=$(echo "$INPUT" | jq -r '.tool_input.run_in_background // false')

# Skip if not a successful agent spawn
[ -z "$AGENT_NAME" ] && exit 0

TIMESTAMP=$(date '+%H:%M:%S')

# Write agent status
cat > "$STATUS_DIR/${AGENT_NAME}.status" <<EOF
name=$AGENT_NAME
id=$AGENT_ID
description=$DESCRIPTION
background=$BACKGROUND
status=running
started=$TIMESTAMP
updated=$TIMESTAMP
EOF

# Check if we're in tmux
[ -z "$TMUX" ] && exit 0

# Check if dashboard pane already exists
if [ -f "$DASHBOARD_PANE_FILE" ]; then
    DASH_PANE=$(cat "$DASHBOARD_PANE_FILE")
    # Verify pane still exists
    if tmux list-panes -t "$DASH_PANE" 2>/dev/null | grep -q .; then
        # Dashboard already running, just update status file (dashboard watches it)
        exit 0
    fi
fi

# Create dashboard pane (split bottom, 12 lines)
DASH_PANE=$(tmux split-window -v -l 12 -P -F '#{pane_id}' \
    "bash /data/gpfs/home/wyim/.claude/hooks/agent_dashboard.sh '$STATUS_DIR'")
echo "$DASH_PANE" > "$DASHBOARD_PANE_FILE"

exit 0
