#!/bin/bash
# XAUUSD Weekly Review Generator
# Baca trade log, generate ringkasan mingguan
# Usage: bash scripts/review_weekly.sh

LOG_FILE="data/trade_log.md"
DATE=$(date '+%Y-%m-%d')
WEEK=$(date +%V)
YEAR=$(date +%Y)

if [ ! -f "$LOG_FILE" ]; then
    echo "❌ Belum ada trade log di $LOG_FILE"
    echo "   Catat trading dulu: bash run.sh log"
    exit 1
fi

echo "========================================="
echo "  XAUUSD WEEKLY REVIEW — Week $WEEK, $YEAR"
echo "========================================="
echo ""

# Count trades
TOTAL=$(grep -c '^### Trade' "$LOG_FILE")
echo "📊 Total trades logged: $TOTAL"
echo ""

if [ "$TOTAL" -eq 0 ]; then
    echo "Belum ada trading. Mulai catat dengan: bash run.sh log"
    exit 0
fi

# Parse trades
python3 << EOF
import re
from datetime import datetime

with open("$LOG_FILE") as f:
    content = f.read()

# Split into individual trades
trades = re.split(r'(?=^### Trade)', content, flags=re.MULTILINE)[1:]

total = len(trades)
wins = 0
losses = 0
total_pts = 0.0

for t in trades:
    # Parse result
    result_match = re.search(r'\*\*Outcome:\*\* (\w+)', t)
    pts_match = re.search(r'\*\*Net:\*\* ([+-]?\d+\.?\d*)', t)
    
    if result_match:
        outcome = result_match.group(1)
        if outcome == 'TP1' or outcome == 'TP2':
            wins += 1
        elif outcome == 'SL':
            losses += 1
    
    if pts_match:
        total_pts += float(pts_match.group(1))

print(f"  ✅ Wins:  {wins}")
print(f"  ❌ Losses: {losses}")
print(f"  Win Rate: {wins/total*100:.0f}%" if total > 0 else "  Win Rate: -")

if total > 0:
    print(f"  Total P&L: {total_pts:+.1f} pts")
    avg_win = total_pts / total if total > 0 else 0
    print(f"  Avg/Trade: {avg_win:+.1f} pts")

print()
print("---")
print()

# Parse session stats
sessions = {}
for t in trades:
    session_match = re.search(r'\*\*Session:\*\* (\w+)', t)
    if session_match:
        s = session_match.group(1)
        sessions[s] = sessions.get(s, 0) + 1

if sessions:
    print("📅 By Session:")
    for s, c in sorted(sessions.items(), key=lambda x: -x[1]):
        print(f"  {s}: {c} trades")

# Parse setup type
setups = {}
for t in trades:
    setup_match = re.search(r'\*\*Setup:\*\* (.+)', t)
    if setup_match:
        st = setup_match.group(1).strip()
        setups[st] = setups.get(st, 0) + 1

if setups:
    print()
    print("🎯 By Setup Type:")
    for st, c in sorted(setups.items(), key=lambda x: -x[1]):
        print(f"  {st}: {c} trades")

# Parse lessons
print()
print("📝 Lessons Learned:")
for t in trades:
    lesson_match = re.search(r'\*\*Lesson:\*\* (.+)', t)
    if lesson_match:
        print(f"  • {lesson_match.group(1).strip()}")
EOF

echo ""
echo "========================================="
echo ""
echo "Simpan hasil review ini ke analysis/?"
echo "  y/n"
