#!/bin/bash
# XAUUSD News Gate Checker
# Cek apakah ada event berita besar yang bisa mempengaruhi Gold.
# Usage: bash scripts/news_gate.sh

echo "=============================="
echo "  NEWS GATE CHECK"
echo "=============================="

# --- Day/Date Info ---
DOW=$(date +%u)          # 1=Mon .. 7=Sun
DOM=$(date +%d)          # Day of month
MONTH=$(date +%m)        # Month
YEAR=$(date +%Y)
WEEK=$(date +%V)         # ISO week number

echo "  Date: $(date '+%Y-%m-%d %A')"
echo ""

# --- Weekends ---
if [ "$DOW" -ge 6 ]; then
    echo "  ⛔ WEEKEND: Markets closed or very low liquidity"
    echo ""
fi

# --- NFP Check (First Friday of month) ---
# First Friday = month day 1-7 and day of week = 5 (Friday)
if [ "$DOM" -le 7 ] && [ "$DOW" -eq 5 ]; then
    echo "  ⛔ HIGH IMPACT: This could be NFP Friday!"
    echo "     NFP moves gold 30-50+ points. Skip scalping."
    echo ""
fi

# --- FOMC Check (typically Wed, 8 times/year) ---
# FOMC meetings: Jan, Mar, May, Jun, Jul, Sep, Nov, Dec (approximation)
# Usually around weeks 2-3
if [ "$DOW" -eq 3 ]; then  # Wednesday
    case "$MONTH" in
        01|03|05|06|07|09|11|12)
            echo "  ⛔ POSSIBLE FOMC WEEK: ${MONTH}/${YEAR}"
            echo "     Check if FOMC decision is today. Avoid trading."
            echo ""
            ;;
    esac
fi

# --- Major US events by month ---
echo "  Typical high-impact events this month:"
case "$MONTH" in
    01) echo "    - FOMC meeting (Jan)" 
        echo "    - US employment data (first week)" ;;
    02) echo "    - PCE / CPI data releases" ;;
    03) echo "    - FOMC meeting (Mar)"
        echo "    - Potential BOJ year-end" ;;
    04) echo "    - CPI / PPI releases" ;;
    05) echo "    - FOMC meeting (May)"
        echo "    - NFP (first Friday)" ;;
    06) echo "    - FOMC meeting (Jun)"
        echo "    - CPI mid-month" ;;
    07) echo "    - FOMC meeting (Jul)"
        echo "    - NFP (first Friday)" ;;
    08) echo "    - Jackson Hole symposium (late Aug)" ;;
    09) echo "    - FOMC meeting (Sep)"
        echo "    - NFP (first Friday)" ;;
    10) echo "    - CPI / PCE data" ;;
    11) echo "    - FOMC meeting (Nov)"
        echo "    - NFP (first Friday)" ;;
    12) echo "    - FOMC meeting (Dec)"
        echo "    - Triple witching (3rd Friday)" ;;
esac

# --- Current Market Time Check ---
UTC_HOUR=$(date -u +%H)
echo ""
echo "  Current UTC: $(date -u +'%H:%M')"
if [ "$UTC_HOUR" -ge 12 ] && [ "$UTC_HOUR" -lt 14 ]; then
    echo "  ⏰ US pre-market data releases common (12:30-13:30 UTC)"
elif [ "$UTC_HOUR" -ge 8 ] && [ "$UTC_HOUR" -lt 9 ]; then
    echo "  ⏰ London open - possible news spikes"
elif [ "$UTC_HOUR" -ge 13 ] && [ "$UTC_HOUR" -lt 14 ]; then
    echo "  ⏰ NY open - possible news spikes"
fi

echo ""
echo "  ⚠ Always check: https://forexfactory.com/calendar"
echo "=============================="
