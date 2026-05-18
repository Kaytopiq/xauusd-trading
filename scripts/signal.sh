#!/bin/bash
# XAUUSD Quick Signal Snapshot
# Langsung dari TradingView API JSON — parsing akurat
# Usage: bash scripts/signal.sh

ENV_FILE="config/.env"
if [ -f "$ENV_FILE" ]; then
    set -a
    source "$ENV_FILE"
    set +a
fi

TS=$(date '+%Y-%m-%d %H:%M:%S')
UTC_HOUR=$(date -u +%H)
DOW=$(date +%u)

echo "============================================"
echo "  XAUUSD SIGNAL SNAPSHOT  |  $TS"
echo "============================================"

# --- Session check ---
echo ""
if [ "$DOW" -ge 6 ]; then
    echo "  ⛔ WEEKEND — Markets closed / very low liquidity"
elif [ "$UTC_HOUR" -ge 21 ] && [ "$UTC_HOUR" -lt 22 ]; then
    echo "  ⛔ ROLLOVER (21-22 UTC) — HARD NO TRADE"
elif [ "$UTC_HOUR" -ge 13 ] && [ "$UTC_HOUR" -lt 17 ]; then
    echo "  ✅ LONDON-NY OVERLAP — Best for scalping"
elif [ "$UTC_HOUR" -ge 8 ] && [ "$UTC_HOUR" -lt 12 ]; then
    echo "  ✅ LONDON SESSION — Good liquidity"
elif [ "$UTC_HOUR" -ge 13 ] && [ "$UTC_HOUR" -lt 21 ]; then
    echo "  ✅ NY SESSION — Good liquidity"
elif [ "$UTC_HOUR" -ge 0 ] && [ "$UTC_HOUR" -lt 8 ]; then
    echo "  ⚠ ASIAN SESSION — Wider spreads"
else
    echo "  ⚠ OFF-HOURS — Low liquidity"
fi

# --- Fetch raw JSON from TradingView ---
RAW=$(curl -s "https://scanner.tradingview.com/cfd/scan" \
  -H "Content-Type: application/json" \
  -d '{"symbols":{"tickers":["TVC:GOLD"],"query":{"types":[]}},"columns":["close","open","high","low","change","change_abs","Recommend.All","RSI|5","Stoch.K|5","Stoch.D|5","CCI20|5","ATR|5","ADX|5","EMA5|5","EMA20|5","BB.upper|5","BB.lower|5","close|15","RSI|15","ATR|15","EMA5|15","EMA20|15","close|60","ATR|60"]}' 2>/dev/null)

echo "$RAW" | python3 -c "
import sys, json

try:
    data = json.load(sys.stdin)
    if not data.get('data'):
        print('ERROR: No data')
        sys.exit(1)
    
    r = data['data'][0]['d']
    
    def f(v): return f'{v:.2f}' if v is not None else 'N/A'
    def f1(v): return f'{v:.1f}' if v is not None else 'N/A'
    
    price = r[0]
    chg_pct = r[4]
    chg_abs = r[5]
    rec = r[6]
    
    # 5m data
    rsi5 = r[7]
    stoch_k5 = r[8]
    stoch_d5 = r[9]
    cci5 = r[10]
    atr5 = r[11]
    adx5 = r[12]
    ema5_5 = r[13]
    ema20_5 = r[14]
    bb_u5 = r[15]
    bb_l5 = r[16]
    
    # 15m data
    close15 = r[17]
    rsi15 = r[18]
    atr15 = r[19]
    ema5_15 = r[20]
    ema20_15 = r[21]
    
    # 1h data
    atr60 = r[23]
    
    # TV Rec tag
    if rec is not None:
        if rec >= 0.5: tag = 'STRONG BUY'
        elif rec >= 0.1: tag = 'BUY'
        elif rec > -0.1: tag = 'NEUTRAL'
        elif rec > -0.5: tag = 'SELL'
        else: tag = 'STRONG SELL'
    else:
        tag = 'N/A'
    
    print()
    print(f'  Price: \${f(price)}  |  {f1(chg_pct)}% (\${f(chg_abs)})  |  TV: {tag} ({rec:+.2f})')
    
    # Trend
    print()
    if ema5_5 is not None and ema20_5 is not None:
        if ema5_5 > ema20_5:
            trend = 'BULLISH'
            trend_sym = '🟢'
        elif ema5_5 < ema20_5:
            trend = 'BEARISH'
            trend_sym = '🔴'
        else:
            trend = 'FLAT'
            trend_sym = '⚪'
        print(f'  Trend (5m): {trend_sym} {trend}  (EMA5={f(ema5_5)}, EMA20={f(ema20_5)})')
    else:
        print(f'  Trend (5m): N/A')
    
    # Momentum
    print()
    print('  MOMENTUM (5m):')
    
    rsi_tag = ''
    if rsi5 is not None:
        if rsi5 < 30: rsi_tag = ' [OVERSOLD]'
        elif rsi5 > 70: rsi_tag = ' [OVERBOUGHT]'
        elif rsi5 < 40: rsi_tag = ' [Bearish]'
        elif rsi5 > 60: rsi_tag = ' [Bullish]'
    print(f'    RSI:   {f1(rsi5)}{rsi_tag}')
    
    stoch_tag = ''
    if stoch_k5 is not None:
        if stoch_k5 < 10: stoch_tag = ' [EXTREME OVERSOLD]'
        elif stoch_k5 > 90: stoch_tag = ' [EXTREME OVERBOUGHT]'
        elif stoch_k5 < 20: stoch_tag = ' [Oversold]'
        elif stoch_k5 > 80: stoch_tag = ' [Overbought]'
    print(f'    Stoch: K={f1(stoch_k5)} D={f1(stoch_d5)}{stoch_tag}')
    
    cci_tag = ''
    if cci5 is not None:
        if cci5 < -100: cci_tag = ' [OVERSOLD]'
        elif cci5 > 100: cci_tag = ' [OVERBOUGHT]'
        elif cci5 < -50: cci_tag = ' [Bearish]'
        elif cci5 > 50: cci_tag = ' [Bullish]'
    print(f'    CCI:   {f1(cci5)}{cci_tag}')
    
    adx_tag = 'RANGING'
    adx_sym = '⚪'
    if adx5 is not None:
        if adx5 > 25:
            adx_tag = 'TRENDING'
            adx_sym = '📊'
        elif adx5 > 20:
            adx_tag = 'WEAK TREND'
    print(f'    ADX:   {f1(adx5)} {adx_sym} {adx_tag}')
    
    # Extreme Score (from SKILL.md)
    score_long = 0
    score_short = 0
    if stoch_k5 is not None:
        if stoch_k5 < 10: score_long += 1
        if stoch_k5 > 90: score_short += 1
    if cci5 is not None:
        if cci5 < -100: score_long += 1
        if cci5 > 100: score_short += 1
    if rsi5 is not None:
        if rsi5 < 30: score_long += 1
        if rsi5 > 70: score_short += 1
    
    if score_long >= 2:
        print(f'    🟢 HIGH PROB BOUNCE ({score_long}/3 extreme indicators)')
    elif score_short >= 2:
        print(f'    🔴 HIGH PROB REJECT ({score_short}/3 extreme indicators)')
    elif score_long >= 1:
        print(f'    🟢 mild bounce bias ({score_long}/3 extreme indicators)')
    elif score_short >= 1:
        print(f'    🔴 mild reject bias ({score_short}/3 extreme indicators)')
    
    # Volatility Gate
    print()
    print('  VOLATILITY GATE:')
    if atr5 is not None:
        if atr5 > 8:
            print(f'    ⛔ 5m ATR={f(atr5)} > 8 — 5pt SL is risky')
        else:
            print(f'    ✅ 5m ATR={f(atr5)} ≤ 8 — OK for scalping')
    if atr15 is not None:
        if atr15 > 20:
            print(f'    ⛔ 15m ATR={f(atr15)} > 20 — market too wild')
        else:
            print(f'    ✅ 15m ATR={f(atr15)} ≤ 20')
    if atr60 is not None:
        print(f'    1h ATR={f(atr60)}')
    
    # Key Levels
    print()
    print('  KEY LEVELS:')
    print(f'    BB Upper: \${f(bb_u5)}')
    print(f'    BB Lower: \${f(bb_l5)}')
    if price is not None and bb_l5 is not None and bb_u5 is not None and bb_l5 != bb_u5:
        pos = (price - bb_l5) / (bb_u5 - bb_l5) * 100
        print(f'    Price Position: {pos:.0f}% from BB Lower')
    
    # Multi-timeframe alignment
    print()
    print('  TIMEFRAME ALIGNMENT:')
    tf_long = 0
    tf_short = 0
    
    if ema5_5 is not None and ema20_5 is not None:
        if ema5_5 > ema20_5: tf_long += 1
        else: tf_short += 1
    if ema5_15 is not None and ema20_15 is not None:
        if ema5_15 > ema20_15: tf_long += 1
        else: tf_short += 1
    
    if tf_long == 2:
        print('    🟢 5m + 15m ALIGNED BULLISH')
    elif tf_short == 2:
        print('    🔴 5m + 15m ALIGNED BEARISH')
    else:
        print('    ⚠ 5m + 15m MISALIGNED — wait for alignment')
    
    # Structure summary (BB position)
    print()
    print('  STRUCTURE:')
    if price is not None and bb_u5 is not None and bb_l5 is not None and bb_l5 != bb_u5:
        pos = (price - bb_l5) / (bb_u5 - bb_l5)
        if pos < 0.15:
            print('    📈 Price near BB Lower — potential support bounce')
        elif pos > 0.85:
            print('    📉 Price near BB Upper — potential resistance reject')
        elif pos > 0.4 and pos < 0.6:
            print('    ➖ Price mid-BB range — no clear level')
        elif pos < 0.4:
            print('    📈 Lower BB half — bearish momentum')
        else:
            print('    📉 Upper BB half — bullish momentum')
    
    print()
    print('============================================')
    
except Exception as e:
    print(f'Error: {e}', file=sys.stderr)
    sys.exit(1)
"
