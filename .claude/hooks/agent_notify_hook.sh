#!/bin/bash
# Claude Code Notification hook - 에이전트 완료/메시지 시 상태 업데이트
# Notification hook으로 등록하여 에이전트 idle/완료 시 대시보드 업데이트

STATUS_DIR="${CLAUDE_AGENT_STATUS_DIR:-/tmp/claude_agent_status}"

INPUT=$(cat)

# Check if this is a teammate notification
TEAMMATE=$(echo "$INPUT" | jq -r '.teammate_name // empty' 2>/dev/null)
[ -z "$TEAMMATE" ] && exit 0

STATUS_FILE="$STATUS_DIR/${TEAMMATE}.status"
[ ! -f "$STATUS_FILE" ] && exit 0

# Check notification type
TYPE=$(echo "$INPUT" | jq -r '.type // empty' 2>/dev/null)
TIMESTAMP=$(date '+%H:%M:%S')

if [ "$TYPE" = "agent_idle" ] || [ "$TYPE" = "shutdown" ]; then
    sed -i "s/^status=.*/status=completed/" "$STATUS_FILE"
    sed -i "s/^updated=.*/updated=$TIMESTAMP/" "$STATUS_FILE"
fi

exit 0
