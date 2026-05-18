#!/bin/bash
# XAUUSD Trading Project - Runner Script
# Usage: bash run.sh [command]
# Commands:
#   price      - Fetch live price + indicators (TradingView, no key)
#   candles    - Fetch real-time candles (needs TWELVE_DATA_API_KEY)
#   gold       - Fetch fallback candles from Yahoo Finance (delayed, no key)
#   full       - Run all fetches and show analysis

SKILL_DIR=".agents/skills/xauusd-trading/scripts"
ENV_FILE="config/.env"

# Load .env if exists
if [ -f "$ENV_FILE" ]; then
    set -a
    source "$ENV_FILE"
    set +a
fi

case "${1:-help}" in
    price)
        echo "=== XAUUSD LIVE PRICE + INDICATORS ==="
        bash "$SKILL_DIR/fetch_price.sh"
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
        bash "$SKILL_DIR/fetch_gold.sh" "$INTERVAL" "$RANGE" "$COUNT"
        ;;
    full)
        echo "========================================"
        echo "  XAUUSD FULL ANALYSIS"
        echo "========================================"
        echo ""
        bash "$0" price
        echo ""
        bash "$0" gold 5m 1d 15
        echo ""
        echo "TIP: For real-time candles, set TWELVE_DATA_API_KEY in config/.env"
        ;;
    help|*)
        echo "XAUUSD Trading Runner"
        echo "Usage: bash run.sh [command]"
        echo ""
        echo "Commands:"
        echo "  price              Live price + RSI/MACD/Stoch/BB/ATR (no key)"
        echo "  candles [int] [n]  Real-time candles (needs API key)"
        echo "  gold [int] [ran]   Yahoo Finance fallback (no key, delayed)"
        echo "  full               Run everything"
        echo ""
        echo "Examples:"
        echo "  bash run.sh price"
        echo "  bash run.sh candles 5min 30"
        echo "  bash run.sh gold 5m 1d 20"
        echo "  bash run.sh full"
        ;;
esac
