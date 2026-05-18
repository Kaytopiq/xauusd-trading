#!/bin/bash
# XAUUSD Trading Project - Runner Script
# Usage: bash run.sh [command]

SKILL_DIR=".agents/skills/xauusd-trading/scripts"
ENV_FILE="config/.env"

if [ -f "$ENV_FILE" ]; then
    set -a
    source "$ENV_FILE"
    set +a
fi

save_output() {
    local cmd="$1"
    local ts=$(date +%Y%m%d_%H%M%S)
    local file="analysis/${cmd}_${ts}.txt"
    cat > "$file"
    echo "[SAVED] $file"
}

case "${1:-help}" in
    price)
        echo "=== XAUUSD LIVE PRICE + INDICATORS ==="
        bash "$SKILL_DIR/fetch_price.sh" | tee >(save_output "price")
        ;;
    candles)
        INTERVAL="${2:-5min}"
        COUNT="${3:-15}"
        echo "=== XAUUSD CANDLES ($INTERVAL, last $COUNT) ==="
        bash "$SKILL_DIR/fetch_candles.sh" "$INTERVAL" "$COUNT"
        ;;
    gold)
        INTERVAL="${2:-5m}"
        RANGE="${3:-1d}"
        COUNT="${4:-10}"
        echo "=== XAUUSD YAHOO FALLBACK ($INTERVAL, $RANGE) ==="
        bash "$SKILL_DIR/fetch_gold.sh" "$INTERVAL" "$RANGE" "$COUNT" | tee >(save_output "gold")
        ;;
    session)
        bash scripts/session.sh
        ;;
    signal)
        bash scripts/signal.sh "${2:-save}"
        ;;
    news)
        bash scripts/news_gate.sh
        ;;
    log)
        bash scripts/log_trade.sh
        ;;
    monitor)
        bash scripts/monitor.sh | tee >(save_output "monitor")
        ;;
    monitor-loop|loop)
        bash scripts/monitor_loop.sh
        ;;
    report)
        bash scripts/report.sh
        ;;
    review)
        bash scripts/review_weekly.sh
        ;;
    chart)
        INTERVAL="${2:-1h}"
        PERIOD="${3:-3d}"
        bash scripts/chart.sh "$INTERVAL" "$PERIOD"
        ;;
    notify)
        shift
        bash scripts/notify.sh "$@"
        ;;
    setup)
        bash setup.sh
        ;;
    full)
        ts=$(date +%Y%m%d_%H%M%S)
        file="analysis/full_${ts}.txt"
        echo "========================================"
        echo "  XAUUSD FULL ANALYSIS — $(date)"
        echo "========================================"
        echo ""
        bash scripts/session.sh
        echo ""
        echo "--- PRICE & INDICATORS ---"
        bash "$SKILL_DIR/fetch_price.sh"
        echo ""
        echo "--- YAHOO FALLBACK (15 candles) ---"
        bash "$SKILL_DIR/fetch_gold.sh" 5m 1d 15
        echo ""
        echo "TIP: For real-time candles, set TWELVE_DATA_API_KEY in config/.env"
        echo "========================================" > "$file"
        echo "  XAUUSD FULL ANALYSIS — $(date)" >> "$file"
        echo "========================================" >> "$file"
        bash "$0" session >> "$file" 2>/dev/null
        echo "" >> "$file"
        bash "$SKILL_DIR/fetch_price.sh" >> "$file" 2>/dev/null
        echo "" >> "$file"
        bash "$SKILL_DIR/fetch_gold.sh" 5m 1d 15 >> "$file" 2>/dev/null
        echo "[SAVED] $file"
        ;;
    help|*)
        echo "XAUUSD Trading Runner"
        echo "Usage: bash run.sh [command]"
        echo ""
        echo "Commands:"
        echo "  price              Live price + RSI/MACD/Stoch/BB/ATR (no key)"
        echo "  candles [int] [n]  Real-time candles (needs API key)"
        echo "  gold [int] [ran]   Yahoo Finance fallback (no key, delayed)"
        echo "  session            Check market session"
        echo "  signal             Quick signal snapshot + auto-save"
        echo "  news               News/economic calendar gate check"
        echo "  log                Log a trade result"
        echo "  monitor            Market state detection (NEUTRAL/WATCHING/SIGNAL)"
        echo "  monitor-loop       🔄 Continuous monitoring (runs until SIGNAL)"
        echo "  report             📄 Generate analysis report + chart"
        echo "  review             📊 Weekly review from trade log"
        echo "  chart [int] [per]  📈 Generate candlestick chart (default: 1h 3d)"
        echo "  notify [msg]       🔔 Send notification (local + WhatsApp)"
        echo "  setup              ⚙️  One-click environment setup"
        echo "  full               Run everything + save to analysis/"
        echo ""
        echo "Examples:"
        echo "  bash run.sh monitor-loop"
        echo "  bash run.sh signal"
        echo "  bash run.sh report"
        echo "  bash run.sh session"
        echo "  bash run.sh news"
        echo "  bash run.sh full"
        echo "  bash run.sh gold 5m 1d 20"
        ;;
esac
