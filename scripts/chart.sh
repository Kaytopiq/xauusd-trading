#!/bin/bash
# XAUUSD Chart Generator
# Generate candlestick chart dengan indikator (EMA, BB, volume)
# Usage: bash scripts/chart.sh [interval] [period] [save]
#   interval: 5m, 15m, 1h, 4h, 1d (default: 1h)
#   period: 5d, 10d, 1mo, 3mo, 6mo (default: 3d)
#   save: filename (opsional, auto jika tidak diisi)

ENV_FILE="config/.env"
if [ -f "$ENV_FILE" ]; then
    set -a
    source "$ENV_FILE"
    set +a
fi

INTERVAL="${1:-1h}"
PERIOD="${2:-3d}"
CUSTOM_NAME="${3:-}"

TS=$(date '+%Y%m%d_%H%M%S')

if [ -n "$CUSTOM_NAME" ]; then
    FILENAME="analysis/${CUSTOM_NAME}.png"
else
    FILENAME="analysis/chart_xauusd_${INTERVAL}_${TS}.png"
fi

python3 << EOF
import yfinance as yf
import mplfinance as mpf
import pandas as pd
import os

try:
    # Fetch data
    gold = yf.Ticker("GC=F")
    df = gold.history(period="$PERIOD", interval="$INTERVAL")
    
    if df.empty:
        print("❌ No data fetched")
        exit(1)
    
    # Ensure timezone-naive index for mplfinance
    if df.index.tz is not None:
        df.index = df.index.tz_localize(None)
    
    # Calculate indicators
    df['EMA5'] = df['Close'].ewm(span=5, adjust=False).mean()
    df['EMA20'] = df['Close'].ewm(span=20, adjust=False).mean()
    
    # Bollinger Bands
    df['BB_Mid'] = df['Close'].rolling(20).mean()
    bb_std = df['Close'].rolling(20).std()
    df['BB_Upper'] = df['BB_Mid'] + 2 * bb_std
    df['BB_Lower'] = df['BB_Mid'] - 2 * bb_std
    
    # Current price
    last_price = df['Close'].iloc[-1]
    last_date = df.index[-1].strftime('%Y-%m-%d %H:%M')
    
    # Custom style
    style = mpf.make_mpf_style(
        base_mpf_style='charles',
        rc={
            'figure.facecolor': '#1a1a2e',
            'axes.facecolor': '#16213e',
            'axes.edgecolor': '#0f3460',
            'axes.labelcolor': '#e8e8e8',
            'text.color': '#e8e8e8',
            'grid.color': '#0f3460',
            'grid.alpha': 0.3
        }
    )
    
    # Add EMAs and BB as extra plots
    ap = [
        mpf.make_addplot(df['EMA5'], color='#00d2ff', width=0.8, label='EMA5'),
        mpf.make_addplot(df['EMA20'], color='#ff6b6b', width=0.8, label='EMA20'),
        mpf.make_addplot(df['BB_Upper'], color='#ffd93d', width=0.5, alpha=0.5, label='BB Upper'),
        mpf.make_addplot(df['BB_Lower'], color='#ffd93d', width=0.5, alpha=0.5, label='BB Lower'),
    ]
    
    # Fill BB range
    ap.append(mpf.make_addplot(df['BB_Upper'], color='#ffd93d', width=0, alpha=0.1))
    ap.append(mpf.make_addplot(df['BB_Lower'], color='#ffd93d', width=0, alpha=0.1, fill_between=dict(y1=df['BB_Upper'].values, alpha=0.1, color='#ffd93d')))
    
    # Volume
    ap.append(mpf.make_addplot(df['Volume'], panel=2, color='#4a4a8a', width=0.8, alpha=0.3, ylabel='Volume'))
    
    # Chart title
    title = f'XAUUSD (Gold) - $INTERVAL interval [$PERIOD period]'
    
    # Plot
    fig, axes = mpf.plot(
        df,
        type='candle',
        style=style,
        title=title,
        volume=True,
        ylabel='Price ($)',
        addplot=ap,
        figsize=(11, 7),
        panel_ratios=(3, 1, 1),
        returnfig=True
    )
    
    # Add current price annotation
    axes[0].axhline(y=last_price, color='#ffd93d', linestyle='--', alpha=0.5, linewidth=1)
    axes[0].text(df.index[-1], last_price, f'  \${last_price:.2f}', 
                 color='#ffd93d', fontsize=10, verticalalignment='bottom')
    
    # Save
    os.makedirs('analysis', exist_ok=True)
    fig.savefig('$FILENAME', dpi=100, bbox_inches='tight')
    plt = fig  # keep reference
    import matplotlib.pyplot as plt
    plt.close(fig)
    
    print(f"✅ Chart saved: $FILENAME")
    print(f"📊 {last_date} | Price: \${last_price:.2f} | Candles: {len(df)}")
    
except Exception as e:
    print(f"❌ Error: {e}")
    exit(1)
EOF
