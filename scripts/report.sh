#!/bin/bash
# XAUUSD Auto Report Generator
# Generate laporan markdown ke analysis/
# Usage: bash scripts/report.sh

ENV_FILE="config/.env"
if [ -f "$ENV_FILE" ]; then
    set -a
    source "$ENV_FILE"
    set +a
fi

TS=$(date '+%Y-%m-%d %H:%M:%S')
DATE=$(date '+%Y-%m-%d')
FILE="analysis/report_${DATE}.md"

echo "📝 Generating report..."

# Run signal and capture output
SIGNAL_OUTPUT=$(bash scripts/signal.sh 2>/dev/null)

# Extract key values
PRICE=$(echo "$SIGNAL_OUTPUT" | grep 'Price:' | sed 's/.*Price: \$\([0-9.]*\).*/\1/')
SESSION=$(echo "$SIGNAL_OUTPUT" | grep -E '(LONDON-NY|LONDON|ASIAN|ROLLOVER)' | sed 's/.*✅ //;s/.*⚠ //')

TREND_LINE=$(echo "$SIGNAL_OUTPUT" | grep 'Trend')
RSI_LINE=$(echo "$SIGNAL_OUTPUT" | grep 'RSI:')
STOCH_LINE=$(echo "$SIGNAL_OUTPUT" | grep 'Stoch:')
CCI_LINE=$(echo "$SIGNAL_OUTPUT" | grep 'CCI:')
ATR_LINE=$(echo "$SIGNAL_OUTPUT" | grep 'ATR:')
BB_UPPER=$(echo "$SIGNAL_OUTPUT" | grep 'BB Upper' | sed 's/.*\$\([0-9.]*\).*/\1/')
BB_LOWER=$(echo "$SIGNAL_OUTPUT" | grep 'BB Lower' | sed 's/.*\$\([0-9.]*\).*/\1/')
STRUCTURE=$(echo "$SIGNAL_OUTPUT" | grep 'STRUCTURE:' -A1 | tail -1 | sed 's/^[[:space:]]*//;s/— //')
STATE=$(bash scripts/monitor.sh 2>/dev/null | grep 'STATE:' | sed 's/.*STATE: //;s/^[^ ]* //')

cat > "$FILE" << EOF
# XAUUSD Analysis Report — ${DATE}

**Generated:** ${TS}
**State:** ${STATE}
**Session:** ${SESSION}

## Market Data

| Item | Value |
|------|-------|
| Price | \$${PRICE} |
| Trend | ${TREND_LINE} |
| Structure | ${STRUCTURE} |
| BB Upper | \$${BB_UPPER} |
| BB Lower | \$${BB_LOWER} |

## Momentum

| Indicator | Value |
|-----------|-------|
| RSI | ${RSI_LINE} |
| Stoch | ${STOCH_LINE} |
| CCI | ${CCI_LINE} |
| ATR | ${ATR_LINE} |

## Analysis

${STRUCTURE}

## Signal Details

\`\`\`
${SIGNAL_OUTPUT}
\`\`\`

---
*Generated automatically by XAUUSD Trading Project*
EOF

echo "  ✅ Report saved to ${FILE}"

# Also notify
bash scripts/notify.sh "📊 XAUUSD Report generated - \$${PRICE}" "XAUUSD Report"
