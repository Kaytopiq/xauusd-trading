#!/bin/bash
# XAUUSD Trade Logger
# Catat hasil trading ke file log markdown.
# Usage: bash scripts/log_trade.sh

LOG_FILE="data/trade_log.md"

if [ ! -f "$LOG_FILE" ]; then
    cat > "$LOG_FILE" << 'EOF'
# XAUUSD Trade Log

EOF
fi

echo "=== XAUUSD TRADE LOGGER ==="
echo ""

read -p "Direction (BUY/SELL): " DIR
read -p "Entry price: " ENTRY
read -p "Stop Loss: " SL
read -p "TP1: " TP1
read -p "TP2: " TP2
read -p "Outcome (TP1/TP2/SL/MANUAL): " OUTCOME
read -p "Net result (+/- points): " RESULT
read -p "Session (Asian/London/Overlap/NY): " SESSION
read -p "Setup type: " SETUP
read -p "Lesson (one sentence): " LESSON
read -p "Notes: " NOTES

TS=$(date -u +"%Y-%m-%d %H:%M UTC")

cat >> "$LOG_FILE" << EOF

### Trade - ${TS}
- **Direction:** ${DIR}
- **Setup:** ${SETUP}
- **Entry:** ${ENTRY} | **SL:** ${SL} | **TP1:** ${TP1} | **TP2:** ${TP2}
- **Outcome:** ${OUTCOME} | **Net:** ${RESULT} pts
- **Session:** ${SESSION}
- **Lesson:** ${LESSON}
- **Notes:** ${NOTES}
EOF

echo ""
echo "[SAVED] ${LOG_FILE}"
echo "Total trades logged: $(grep -c '^### Trade' "$LOG_FILE")"
