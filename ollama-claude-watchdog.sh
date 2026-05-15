#!/bin/bash
# Ollama Claude Watchdog
# Auto-pauses Ollama when Claude is idle, resumes when Claude is active

IDLE_THRESHOLD=5        # CPU% below this = Claude idle
CHECK_INTERVAL=10       # seconds between checks
IDLE_GRACE=30           # seconds idle before pausing Ollama
LOG="/tmp/ollama-watchdog.log"

idle_seconds=0
ollama_paused=false

claude_cpu() {
    ps aux | grep -i "Claude\|claude" | grep -v grep | awk '{sum += $3} END {print int(sum)}'
}

pause_ollama() {
    if ! $ollama_paused; then
        /usr/local/bin/ollama stop qwen2.5:7b 2>/dev/null
        /usr/local/bin/ollama stop llama3:latest 2>/dev/null
        ollama_paused=true
        echo "$(date '+%H:%M:%S') PAUSED (Claude idle ${idle_seconds}s)" >> "$LOG"
    fi
}

resume_ollama() {
    if $ollama_paused; then
        ollama_paused=false
        echo "$(date '+%H:%M:%S') RESUMED (Claude active)" >> "$LOG"
    fi
}

echo "$(date) Watchdog started" >> "$LOG"

while true; do
    cpu=$(claude_cpu)

    if [ "$cpu" -gt "$IDLE_THRESHOLD" ]; then
        idle_seconds=0
        resume_ollama
    else
        idle_seconds=$((idle_seconds + CHECK_INTERVAL))
        if [ "$idle_seconds" -ge "$IDLE_GRACE" ]; then
            pause_ollama
        fi
    fi

    sleep "$CHECK_INTERVAL"
done
