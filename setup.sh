#!/bin/bash
# XAUUSD Trading Project - Setup Script
# Usage: bash setup.sh

set -e

echo "============================================"
echo "  XAUUSD TRADING PROJECT SETUP"
echo "============================================"
echo ""

# Check dependencies
echo "🔍 Checking dependencies..."
DEPS_MISSING=0

for cmd in curl python3 bash git; do
    if command -v $cmd &>/dev/null; then
        echo "  ✅ $cmd found"
    else
        echo "  ❌ $cmd NOT FOUND"
        DEPS_MISSING=1
    fi
done

if [ $DEPS_MISSING -eq 1 ]; then
    echo ""
    echo "❌ Install missing dependencies first."
    exit 1
fi

# Make scripts executable
echo ""
echo "🔧 Making scripts executable..."
chmod +x scripts/*.sh run.sh setup.sh 2>/dev/null || true
echo "  ✅ Done"

# Create .env if not exists
echo ""
echo "📝 Checking config..."
if [ ! -f config/.env ]; then
    cp config/.env.example config/.env
    echo "  ✅ config/.env created (edit with your API keys)"
else
    echo "  ✅ config/.env already exists"
fi

# Create required folders
echo ""
echo "📁 Creating folders..."
mkdir -p analysis data
echo "  ✅ Done"

# Test TradingView API
echo ""
echo "📡 Testing data fetch..."
if curl -s "https://scanner.tradingview.com/cfd/scan" \
  -H "Content-Type: application/json" \
  -d '{"symbols":{"tickers":["TVC:GOLD"],"query":{"types":[]}},"columns":["close"]}' \
  2>/dev/null | python3 -c "import sys,json; d=json.load(sys.stdin); print('  ✅ TradingView API: OK') if d.get('data') else print('  ⚠️  No data')" 2>/dev/null; then
    :
else
    echo "  ⚠️  TradingView API test failed (might be network)"
fi

# Test Yahoo Finance
if curl -s "https://query1.finance.yahoo.com/v8/finance/chart/GC=F?interval=5m&range=1d" \
  -H "User-Agent: Mozilla/5.0" 2>/dev/null | python3 -c "import sys,json; d=json.load(sys.stdin); print('  ✅ Yahoo Finance: OK') if d.get('chart') else print('  ⚠️ Failed')" 2>/dev/null; then
    :
else
    echo "  ⚠️  Yahoo Finance test failed"
fi

# Git check
echo ""
echo "📦 Git status..."
if [ -d .git ]; then
    echo "  ✅ Git initialized"
    echo "  📝 $(git log --oneline | wc -l) commits"
else
    echo "  ⚠️  Not a git repo (run 'git init' if needed)"
fi

# Final message
echo ""
echo "============================================"
echo "  ✅ SETUP COMPLETE!"
echo "============================================"
echo ""
echo "Quick start:"
echo "  bash run.sh session       # Cek session"
echo "  bash run.sh signal        # Analisis harga"
echo "  bash run.sh monitor-loop  # Monitoring otomatis"
echo ""
echo "Edit config: config/.env"
echo "============================================"
