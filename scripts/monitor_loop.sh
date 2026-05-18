#!/bin/bash
# XAUUSD Continuous Monitoring Loop
# Implementasi full dari SKILL.md monitoring mode
# Jalan terus sampai SIGNAL atau user hit Ctrl+C
# Usage: bash scripts/monitor_loop.sh

ENV_FILE="config/.env"
if [ -f "$ENV_FILE" ]; then
    set -a
    source "$ENV_FILE"
    set +a
fi

# Trap Ctrl+C
trap 'echo ""; echo "⏹  Monitoring stopped by user"; exit 0' INT TERM

SKILL_DIR=".agents/skills/xauusd-trading/scripts"
CYCLE=0
SIGNAL_WAS_SENT=0

echo ""
echo "╔══════════════════════════════════════════╗"
echo "║     XAUUSD MONITOR LOOP                  ║"
echo "║     Press Ctrl+C to stop                  ║"
echo "╚══════════════════════════════════════════╝"
echo ""

while true; do
    CYCLE=$((CYCLE + 1))
    TS=$(date '+%H:%M:%S')

    echo "──────────────────────────────────────────"
    echo "  Cycle #${CYCLE}  |  ${TS} UTC"
    echo "──────────────────────────────────────────"

    # Run monitor and capture state
    MONITOR_OUTPUT=$(bash scripts/monitor.sh 2>/dev/null)
    STATE=$(echo "$MONITOR_OUTPUT" | grep 'STATE:' | sed 's/.*STATE: //' | sed 's/^[^ ]* //')
    PRICE=$(echo "$MONITOR_OUTPUT" | grep 'Price:' | sed 's/.*\$\([0-9.]*\).*/\1/')
    TREND=$(echo "$MONITOR_OUTPUT" | grep 'Trend:' | sed 's/.*Trend: [^ ]* //')
    GATES_PASS=$(echo "$MONITOR_OUTPUT" | grep 'Gates PASS' | wc -l)

    # Show first few lines of monitor output
    echo "$MONITOR_OUTPUT" | head -30
    echo ""

    # State-based actions
    case "$STATE" in
        *SIGNAL*)
            if [ "$GATES_PASS" -gt 0 ]; then
                echo "🔔🔔🔔 SIGNAL DETECTED! 🔔🔔🔔"
                echo "  Price: \$$PRICE | Trend: $TREND"
                
                # Only notify once per signal
                if [ "$SIGNAL_WAS_SENT" -eq 0 ]; then
                    # Send detailed notification
                    MSG="XAUUSD SIGNAL - State: ${STATE} | Price: \$${PRICE} | Trend: ${TREND}"
                    bash scripts/notify.sh "$MSG" "🔔 XAUUSD SIGNAL"
                    
                    # Also run full signal
                    echo ""
                    echo "=== DETAILED SIGNAL ==="
                    bash scripts/signal.sh 2>/dev/null
                    echo ""
                    
                    # Generate report
                    bash scripts/report.sh 2>/dev/null
                    SIGNAL_WAS_SENT=1
                fi
                
                echo ""
                echo "⏸  Monitoring paused. Press Ctrl+C to stop,"
                echo "   or press Enter to continue monitoring..."
                read -r
                SIGNAL_WAS_SENT=0
                echo "  → Resuming..."
            else
                echo "⚠️  Signal but gates not passing (ATR too high / bad session)"
                echo "  ⏱  Waiting 60s..."
                SIGNAL_WAS_SENT=0
                sleep 60
            fi
            ;;
        *WATCHING*)
            echo "  ⏱  Watching... re-check in 60s"
            SIGNAL_WAS_SENT=0
            sleep 60
            ;;
        *CONSOLIDATING*)
            echo "  ⏱  Consolidating... re-check in 90s"
            SIGNAL_WAS_SENT=0
            sleep 90
            ;;
        *)
            echo "  ⏱  Neutral... re-check in 120s"
            SIGNAL_WAS_SENT=0
            sleep 120
            ;;
    esac
done
