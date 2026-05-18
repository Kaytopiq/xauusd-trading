#!/bin/bash
# XAUUSD Multi-Timeframe Dashboard
# Analisis 5m / 15m / 1h / 4h dalam satu tampilan
# Menggunakan TradingView scanner API (free, real-time)
# Usage: bash scripts/mtf_dashboard.sh

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
echo "  XAUUSD MTF DASHBOARD  |  $TS"
echo "============================================"

echo ""
if [ "$DOW" -ge 6 ]; then
    echo "  SESSION: ⛔ WEEKEND"
elif [ "$UTC_HOUR" -ge 21 ] && [ "$UTC_HOUR" -lt 22 ]; then
    echo "  SESSION: ⛔ ROLLOVER (21-22 UTC) — NO TRADE"
elif [ "$UTC_HOUR" -ge 13 ] && [ "$UTC_HOUR" -lt 17 ]; then
    echo "  SESSION: ✅ LONDON-NY OVERLAP — Best for scalping"
elif [ "$UTC_HOUR" -ge 8 ] && [ "$UTC_HOUR" -lt 12 ]; then
    echo "  SESSION: ✅ LONDON — Good liquidity"
elif [ "$UTC_HOUR" -ge 13 ] && [ "$UTC_HOUR" -lt 21 ]; then
    echo "  SESSION: ✅ NY — Good liquidity"
else
    echo "  SESSION: ⚠ ASIAN / OFF-HOURS"
fi

RAW=$(curl -s "https://scanner.tradingview.com/cfd/scan" \
  -H "Content-Type: application/json" \
  -d '{"symbols":{"tickers":["TVC:GOLD"],"query":{"types":[]}},"columns":[
    "close",
    "Recommend.All|5","RSI|5","Stoch.K|5","Stoch.D|5","CCI20|5","ATR|5","ADX|5","EMA5|5","EMA20|5","BB.upper|5","BB.lower|5",
    "Recommend.All|15","RSI|15","ATR|15","EMA5|15","EMA20|15","BB.upper|15","BB.lower|15",
    "Recommend.All|60","RSI|60","ATR|60","EMA5|60","EMA20|60","BB.upper|60","BB.lower|60",
    "Recommend.All|240","RSI|240","ATR|240","EMA5|240","EMA20|240","BB.upper|240","BB.lower|240"
  ]}' 2>/dev/null)

# Pass JSON via env var to avoid quoting issues
export TV_JSON="$RAW"
python3 << 'PYEOF'
import sys, json, os

raw = os.environ.get('TV_JSON', '')
if not raw:
    print('ERROR: No data from API')
    sys.exit(1)

try:
    data = json.loads(raw)
except json.JSONDecodeError as e:
    print(f'ERROR: {e}')
    sys.exit(1)

if not data.get('data'):
    print('ERROR: No data')
    sys.exit(1)

r = data['data'][0]['d']

def f(v):
    return f'{v:.2f}' if v is not None else '-'

def f1(v):
    return f'{v:.1f}' if v is not None else '-'

def trend_sym(e5, e20):
    if e5 is None or e20 is None: return '?'
    return '\U0001f7e2' if e5 > e20 else '\U0001f534' if e5 < e20 else '\u26aa'

def rsi_tag(v):
    if v is None: return ''
    if v > 70: return ' OB'
    if v < 30: return ' OS'
    if v > 60: return ' Bull'
    if v < 40: return ' Bear'
    return ''

def bb_pct(p, u, l):
    if p is None or u is None or l is None or u == l: return '-'
    return f'{(p-l)/(u-l)*100:.0f}%'

def rec_tag(v):
    if v is None: return '?'
    if v >= 0.5: return 'Strong Buy'
    if v >= 0.1: return 'Buy'
    if v > -0.1: return 'Neutral'
    if v > -0.5: return 'Sell'
    return 'Strong Sell'

price = r[0]
tf5  = {'rec':r[1],'rsi':r[2],'sk':r[3],'sd':r[4],'cci':r[5],'atr':r[6],'adx':r[7],'e5':r[8],'e20':r[9],'bu':r[10],'bl':r[11]}
tf15 = {'rec':r[12],'rsi':r[13],'atr':r[14],'e5':r[15],'e20':r[16],'bu':r[17],'bl':r[18]}
tf60 = {'rec':r[19],'rsi':r[20],'atr':r[21],'e5':r[22],'e20':r[23],'bu':r[24],'bl':r[25]}
tf240= {'rec':r[26],'rsi':r[27],'atr':r[28],'e5':r[29],'e20':r[30],'bu':r[31],'bl':r[32]}

print(f'\n  Price: ${f(price)}')
print()
print(f'  {"":>4} {"Trend":>10} {"RSI":>8} {"ATR":>8} {"BB Pos":>8}  {"Rec"}')
print(f'  {"────":>4} {"──────":>10} {"────":>8} {"────":>8} {"──────":>8}  {"───"}')

for name, t in [('5m',tf5),('15m',tf15),('1h',tf60),('4h',tf240)]:
    s = trend_sym(t['e5'], t['e20'])
    r = rsi_tag(t['rsi'])
    bp = bb_pct(price, t['bu'], t['bl'])
    print(f'  {name:>4}  {s:>3}{"":>7} {f1(t["rsi"]):>6}{r:<4} {f(t["atr"]):>8} {bp:>8}  {rec_tag(t["rec"])}')

print()
print('  ────────────────────────────────────────────')
bull = sum(1 for t in [tf5,tf15,tf60,tf240] if t['e5'] is not None and t['e20'] is not None and t['e5'] > t['e20'])
bear = sum(1 for t in [tf5,tf15,tf60,tf240] if t['e5'] is not None and t['e20'] is not None and t['e5'] < t['e20'])

if bull >= 3:
    print(f'  ALIGNMENT: {bull}/4 Bullish — Strong long bias')
elif bear >= 3:
    print(f'  ALIGNMENT: {bear}/4 Bearish — Strong short bias')
elif bull == 2 and bear == 2:
    print(f'  DIVERGENCE: 2 Bull / 2 Bear — Wait for direction')
elif bull >= 2:
    print(f'  ALIGNMENT: {bull}/4 Bull, {bear}/4 Bear — Mild long')
elif bear >= 2:
    print(f'  ALIGNMENT: {bear}/4 Bear, {bull}/4 Bull — Mild short')
else:
    print('  No clear alignment')

print(f'  Key: 4h rec = {rec_tag(tf240["rec"])}')

print()
print('  VOLATILITY:')
for name, t in [('5m',tf5),('15m',tf15),('1h',tf60),('4h',tf240)]:
    lim = {'5m':8,'15m':20,'1h':35,'4h':60}[name]
    a = t['atr']
    if a is not None:
        ok = 'OK' if a <= lim else 'HIGH'
        print(f'    {ok:>4} {name} ATR={f(a)} (max {lim})')
PYEOF
echo "============================================"
