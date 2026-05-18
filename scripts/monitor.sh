#!/bin/bash
# XAUUSD Market Monitor
# State detection: NEUTRAL / WATCHING / CONSOLIDATING / SIGNAL
# Usage: bash scripts/monitor.sh

ENV_FILE="config/.env"
if [ -f "$ENV_FILE" ]; then
    set -a
    source "$ENV_FILE"
    set +a
fi

UTC_HOUR=$(date -u +%H)
DOW=$(date +%u)
LOCAL_TS=$(date '+%Y-%m-%d %H:%M:%S')

# Save data to temp files
TV_TMP=$(mktemp)
YF_TMP=$(mktemp)

curl -s "https://scanner.tradingview.com/cfd/scan" \
  -H "Content-Type: application/json" \
  -d '{"symbols":{"tickers":["TVC:GOLD"],"query":{"types":[]}},"columns":["close","open","high","low","change","change_abs","Recommend.All","RSI|5","Stoch.K|5","Stoch.D|5","CCI20|5","ATR|5","ADX|5","EMA5|5","EMA20|5","BB.upper|5","BB.lower|5","MACD.macd|5","MACD.signal|5","MACD.hist|5","RSI|15","ATR|15","ATR|60"]}' > "$TV_TMP" 2>/dev/null

curl -s "https://query1.finance.yahoo.com/v8/finance/chart/GC=F?interval=5m&range=1d" \
  -H "User-Agent: Mozilla/5.0" > "$YF_TMP" 2>/dev/null

# Run analysis
python3 << EOF
import sys, json

with open("$TV_TMP") as fh:
    tv = json.load(fh)

if not tv.get('data'):
    print('ERROR: No data from TradingView. Market may be closed.')
    sys.exit(1)

r = tv['data'][0]['d']

def f(v): return f'{v:.2f}' if v is not None else 'N/A'
def f1(v): return f'{v:.1f}' if v is not None else 'N/A'

price = r[0]
rsi5  = r[7]; stoch_k = r[8]; stoch_d = r[9]
cci5  = r[10]; atr5 = r[11]; adx5 = r[12]
ema5  = r[13]; ema20 = r[14]
bb_u  = r[15]; bb_l = r[16]
macd_hist = r[19]; atr15 = r[21]

# GATES
gates_pass = True
gate_msgs = []

if $UTC_HOUR >= 21 and $UTC_HOUR < 22:
    gates_pass = False; gate_msgs.append('ROLLOVER (21-22 UTC)')
if $DOW >= 6:
    gates_pass = False; gate_msgs.append('WEEKEND')
if atr5 is not None and atr5 > 8:
    gates_pass = False; gate_msgs.append(f'ATR 5m={f(atr5)} > 8')
if atr15 is not None and atr15 > 20:
    gates_pass = False; gate_msgs.append(f'ATR 15m={f(atr15)} > 20')

# CONSOLIDATION
is_consolidating = False
consolidation_reasons = []

try:
    with open("$YF_TMP") as fh:
        yf_data = json.load(fh)
    quotes = yf_data['chart']['result'][0]['indicators']['quote'][0]
    highs, lows = quotes['high'], quotes['low']
    ranges = []
    for i in range(-5, 0):
        h, l = highs[i], lows[i]
        if h is not None and l is not None:
            ranges.append(h - l)
    if ranges:
        avg_r = sum(ranges) / len(ranges)
        if avg_r < 5:
            is_consolidating = True
            consolidation_reasons.append(f'Tight candles: avg {avg_r:.1f} pts')
except:
    pass

if macd_hist is not None and abs(macd_hist) < 0.10:
    is_consolidating = True
    consolidation_reasons.append(f'Flat MACD: {f(macd_hist)}')

if cci5 is not None and abs(cci5) < 30:
    is_consolidating = True
    consolidation_reasons.append(f'Low CCI: {f1(cci5)}')

# STATE
state = 'NEUTRAL'; state_emoji = '➖'
watching_reasons = []
signal_buy = False; signal_sell = False

if price and bb_l and bb_u and bb_l != bb_u:
    bb_pos = (price - bb_l) / (bb_u - bb_l)
    extreme_buy  = (stoch_k is not None and stoch_k < 10) or (cci5 is not None and cci5 < -100) or (rsi5 is not None and rsi5 < 30)
    extreme_sell = (stoch_k is not None and stoch_k > 90) or (cci5 is not None and cci5 > 100) or (rsi5 is not None and rsi5 > 70)
    if bb_pos < 0.02 and extreme_buy: signal_buy = True
    if bb_pos > 0.98 and extreme_sell: signal_sell = True

if signal_buy or signal_sell:
    state = 'SIGNAL'; state_emoji = '🔔'
elif is_consolidating:
    state = 'CONSOLIDATING'; state_emoji = '💤'
else:
    if price and bb_l and bb_u and bb_l != bb_u:
        bp = (price - bb_l) / (bb_u - bb_l)
        if bp < 0.15: watching_reasons.append(f'Near BB Lower ({bp:.0%})')
        elif bp > 0.85: watching_reasons.append(f'Near BB Upper ({bp:.0%})')
    if stoch_k is not None and (stoch_k < 20 or stoch_k > 80):
        watching_reasons.append(f'Stoch {f1(stoch_k)}')
    if cci5 is not None and (cci5 < -100 or cci5 > 100):
        watching_reasons.append(f'CCI {f1(cci5)}')
    if rsi5 is not None and (rsi5 < 35 or rsi5 > 65):
        watching_reasons.append(f'RSI {f1(rsi5)}')
    if watching_reasons:
        state = 'WATCHING'; state_emoji = '👀'

# BIAS
s_lo = 0; s_sh = 0
if stoch_k is not None and stoch_k < 10: s_lo += 1
if stoch_k is not None and stoch_k > 90: s_sh += 1
if cci5 is not None and cci5 < -100: s_lo += 1
if cci5 is not None and cci5 > 100: s_sh += 1
if rsi5 is not None and rsi5 < 30: s_lo += 1
if rsi5 is not None and rsi5 > 70: s_sh += 1

bias, b_emoji = 'NEUTRAL', '⚪'
if s_lo > s_sh: bias, b_emoji = 'LONG BIAS', '🟢'
elif s_sh > s_lo: bias, b_emoji = 'SHORT BIAS', '🔴'

trend, t_emoji = 'FLAT', '➖'
if ema5 is not None and ema20 is not None:
    if ema5 > ema20: trend, t_emoji = 'BULLISH', '🟢'
    elif ema5 < ema20: trend, t_emoji = 'BEARISH', '🔴'

# OUTPUT
print(f'+------------------------------------------+')
print(f'  XAUUSD MONITOR  |  ${LOCAL_TS}')
print(f'+------------------------------------------+')
print(f'')
print(f'  STATE: {state_emoji} {state}')
print(f'  Price: \${f(price)}  |  Trend: {t_emoji} {trend}  |  Bias: {b_emoji} {bias}')
print(f'')

if state == 'SIGNAL':
    if signal_buy: print(f'  🟢 BUY: BB lower + extreme oversold')
    if signal_sell: print(f'  🔴 SELL: BB upper + extreme overbought')
elif state == 'WATCHING':
    for r in watching_reasons: print(f'    • {r}')
elif state == 'CONSOLIDATING':
    for r in consolidation_reasons: print(f'    • {r}')

print(f'')
print(f'  INDICATORS (5m):')
print(f'    RSI: {f1(rsi5):>6}  Stoch: K={f1(stoch_k):>5} D={f1(stoch_d):>5}')
print(f'    CCI: {f1(cci5):>6}  ADX:   {f1(adx5):>6}')
print(f'    ATR: {f(atr5):>6}  MACDh: {f(macd_hist):>6}')
print(f'    EMA: {f(ema5):>6} / {f(ema20):>6}')
print(f'    BB:  \${f(bb_u):>7} ~ \${f(price):>7} ~ \${f(bb_l):>7}')
print(f'')
print(f'  EXTREME: LONG {s_lo}/3  SHORT {s_sh}/3')
print(f'')

if gates_pass:
    print(f'  ✅ Gates PASS')
else:
    for g in gate_msgs: print(f'  ❌ {g}')

print(f'')
if state == 'SIGNAL' and gates_pass:
    print(f'  >>> ENTRY DETECTED <<<')
    print(f'  bash run.sh signal')
elif state == 'WATCHING':
    print(f'  ⏱ Wait 60s')
elif state == 'CONSOLIDATING':
    print(f'  ⏱ Wait 120s')
else:
    print(f'  ⏱ Wait 120s')
print(f'')
EOF

rm -f "$TV_TMP" "$YF_TMP"
