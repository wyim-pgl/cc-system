#!/bin/bash
# Claude Code Agent → tmux monitor hook
# PostToolUse hook: Agent 호출 시 자동으로 tmux 대시보드 패널 생성/업데이트

export PATH="/data/gpfs/home/wyim/.local/bin:$PATH"

STATUS_DIR="${CLAUDE_AGENT_STATUS_DIR:-/tmp/claude_agent_status}"
DASHBOARD_PANE_FILE="$STATUS_DIR/.dashboard_pane"

mkdir -p "$STATUS_DIR"

# Read hook input from stdin
INPUT=$(cat)

# Parse agent info from JSON (PostToolUse format)
AGENT_NAME=$(echo "$INPUT" | jq -r '.tool_input.name // .tool_input.description // empty')
AGENT_ID=$(echo "$INPUT" | jq -r '.tool_response.agentId // empty')
DESCRIPTION=$(echo "$INPUT" | jq -r '.tool_input.description // "agent"')
STATUS=$(echo "$INPUT" | jq -r '.tool_response.status // "running"')

# Skip if no agent info
[ -z "$AGENT_NAME" ] && exit 0

TIMESTAMP=$(date '+%H:%M:%S')

cat > "$STATUS_DIR/${AGENT_NAME}.status" <<'HEADER'
# agent status file - values are quoted for safe sourcing
HEADER
cat >> "$STATUS_DIR/${AGENT_NAME}.status" <<EOF
name="${AGENT_NAME}"
id="${AGENT_ID}"
description="${DESCRIPTION}"
status="${STATUS}"
updated="${TIMESTAMP}"
EOF

# Check if we're in tmux
[ -z "$TMUX" ] && exit 0

# Check if dashboard pane already exists and is alive
if [ -f "$DASHBOARD_PANE_FILE" ]; then
    DASH_PANE=$(cat "$DASHBOARD_PANE_FILE")
    if tmux list-panes -t "$DASH_PANE" 2>/dev/null | grep -q .; then
        exit 0
    fi
fi

# Create dashboard pane (split bottom, 12 lines)
DASH_PANE=$(tmux split-window -v -l 12 -P -F '#{pane_id}' \
    "bash /data/gpfs/home/wyim/.claude/hooks/agent_dashboard.sh '$STATUS_DIR'")
echo "$DASH_PANE" > "$DASHBOARD_PANE_FILE"

exit 0
