#!/bin/bash
# XAUUSD Market Session Checker
# Cek session pasar apa yang sedang aktif dan apakah aman untuk trading.
# Usage: bash scripts/session.sh

# Get current UTC time
HOUR_UTC=$(date -u +%H)
MIN_UTC=$(date -u +%M)
TOTAL_MIN=$((10#$HOUR_UTC * 60 + 10#$MIN_UTC))

# Session definitions (UTC)
# Asian:   00:00 - 08:00  (0 - 480 min)
# London:  08:00 - 12:00  (480 - 720 min)
# Overlap: 12:00 - 16:00  (720 - 960 min)  -- actually 13:00-17:00 but close
# NY:      13:00 - 21:00  (780 - 1260 min)  -- starting more precisely
# Rollover: 21:00 - 22:00 (1260 - 1320 min)
# After:   22:00 - 00:00  (1320 - 1440 min)

# More precise: London 08-12, Overlap 13-17, NY 13-21, Asian 00-08, Rollover 21-22
# Actually let me use the skill's exact timings:
# - Best: London-NY overlap (13:00-17:00 UTC)
# - OK: London session (08:00-12:00 UTC), NY session (13:00-21:00 UTC)
# - Asian: wider spreads
# - Rollover (21:00-22:00 UTC): DO NOT TRADE (HARD gate)

if [ $TOTAL_MIN -ge 780 ] && [ $TOTAL_MIN -lt 1020 ]; then
    # 13:00 - 17:00
    SESSION="LONDON-NY OVERLAP"
    QUALITY="BEST"
    ADVISORY="Tightest spreads, best liquidity. Ideal for scalping."
elif [ $TOTAL_MIN -ge 480 ] && [ $TOTAL_MIN -lt 720 ]; then
    # 08:00 - 12:00
    SESSION="LONDON"
    QUALITY="OK"
    ADVISORY="Good liquidity. Spreads are reasonable."
elif [ $TOTAL_MIN -ge 780 ] && [ $TOTAL_MIN -lt 1260 ]; then
    # 13:00 - 21:00
    SESSION="NEW YORK"
    QUALITY="OK"
    ADVISORY="Good liquidity. Watch for US news events."
elif [ $TOTAL_MIN -ge 1260 ] && [ $TOTAL_MIN -lt 1320 ]; then
    # 21:00 - 22:00
    SESSION="ROLLOVER"
    QUALITY="HARD NO TRADE"
    ADVISORY="Stop hunts extremely common. Market makers sweep liquidity."
elif [ $TOTAL_MIN -ge 0 ] && [ $TOTAL_MIN -lt 480 ]; then
    # 00:00 - 08:00
    SESSION="ASIAN"
    QUALITY="WARN"
    ADVISORY="Wider spreads, lower volume. Scalping is harder."
else
    # 22:00 - 00:00 and 12:00-13:00 gap
    SESSION="OFF-HOURS / TRANSITION"
    QUALITY="WARN"
    ADVISORY="Low liquidity. Not ideal for scalping."
fi

echo "=============================="
echo "  MARKET SESSION CHECK"
echo "=============================="
echo "  UTC Time:  $(date -u +'%H:%M:%S')"
echo "  Local:     $(date +'%H:%M:%S')"
echo "  Session:   $SESSION"
echo "  Quality:   $QUALITY"
echo "  Note:      $ADVISORY"
echo "=============================="
