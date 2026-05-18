#!/bin/bash
# XAUUSD Chart dari TradingView (via headless Chromium)
# Menghasilkan chart yang sama persis seperti di TradingView
# Usage: bash scripts/chart_tv.sh [interval] [filename]
#   interval: 5, 15, 60, 240 (default: 60)
#   filename: custom name (default: chart_tv_latest.png)

INTERVAL="${1:-60}"
CUSTOM="${2:-chart_tv_latest}"
FILENAME="analysis/${CUSTOM}.png"

WIDTH=1200
HEIGHT=700

# Create HTML with TradingView widget
HTML=$(cat << HTMLEOF
<!DOCTYPE html>
<html>
<head><meta charset="utf-8"></head>
<body style="margin:0;background:#131722;">
<div id="tv_chart"></div>
<script src="https://s3.tradingview.com/tv.js"></script>
<script>
new TradingView.widget({
  container_id: "tv_chart",
  symbol: "TVC:GOLD",
  interval: "${INTERVAL}",
  theme: "dark",
  style: "1",
  width: ${WIDTH},
  height: ${HEIGHT},
  locale: "en",
  toolbar_bg: "#131722",
  enable_publishing: false,
  hide_top_toolbar: true,
  hide_legend: false,
  save_image: false,
  studies: ["BB@tv-basicstudies", "RSI@tv-basicstudies", "StochasticRSI@tv-basicstudies"]
});
</script>
</body>
</html>
HTMLEOF
)

# Write HTML to temp file
TMPHTML=$(mktemp /tmp/tv_chart_XXXXXX.html)
echo "$HTML" > "$TMPHTML"

# Python script for Playwright
python3 << PYEOF
import sys, os, time, json, subprocess

html_file = "$TMPHTML"
output = "$FILENAME"

# Check if playwright available
try:
    from playwright.sync_api import sync_playwright
except ImportError:
    print("Installing playwright...")
    subprocess.run("pip install playwright -q", shell=True)
    subprocess.run("playwright install chromium 2>/dev/null", shell=True)
    from playwright.sync_api import sync_playwright

with sync_playwright() as p:
    browser = p.chromium.launch(headless=True)
    page = browser.new_page(viewport={"width": $WIDTH, "height": $HEIGHT})
    page.goto(f"file://{html_file}", wait_until="networkidle", timeout=30000)
    # Wait for chart rendering + data load
    time.sleep(10)
    page.screenshot(path=output, full_page=False)
    browser.close()

# Check file
size = os.path.getsize(output)
print(f"Chart saved: {output} ({size/1024:.0f}KB)")
PYEOF

rm -f "$TMPHTML"
