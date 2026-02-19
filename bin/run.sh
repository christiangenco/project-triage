#!/usr/bin/env bash
set -e

SESSION="project-triage"
DIR="$(cd "$(dirname "$0")/.." && pwd)"

if tmux has-session -t "$SESSION" 2>/dev/null; then
  echo "Session '$SESSION' is already running."
  exit 0
fi

tmux new-session -d -s "$SESSION" -c "$DIR" "ruby app.rb"
echo "Started '$SESSION' (detached). Attach with: tmux attach -t $SESSION"
