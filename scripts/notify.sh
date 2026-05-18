#!/bin/bash
# XAUUSD Notification System
# Kirim notifikasi ke: macOS + Telegram + WhatsApp (opsional)
# Usage: bash scripts/notify.sh "Pesan" [Title]

ENV_FILE="config/.env"
if [ -f "$ENV_FILE" ]; then
    set -a
    source "$ENV_FILE"
    set +a
fi

MESSAGE="${1:-XAUUSD Notification}"
TITLE="${2:-XAUUSD Monitor}"

# === macOS LOCAL ===
notify_mac() {
    if command -v osascript &>/dev/null; then
        osascript -e "display notification \"${MESSAGE}\" with title \"${TITLE}\""
        echo "  ✅ Local notification sent"
    fi
}

# === TELEGRAM ===
notify_telegram() {
    local token="${TG_BOT_TOKEN:-}"
    local chat_id="${TG_CHAT_ID:-}"

    if [ -z "$token" ] || [ -z "$chat_id" ]; then
        return 0
    fi

    local text="${TITLE}: ${MESSAGE}"
    local response=$(curl -s "https://api.telegram.org/bot${token}/sendMessage" \
      -d "chat_id=${chat_id}&text=${text}&parse_mode=Markdown" 2>/dev/null)

    if echo "$response" | python3 -c "import sys,json; d=json.load(sys.stdin); exit(0 if d.get('ok') else 1)" 2>/dev/null; then
        echo "  ✅ Telegram notification sent"
    else
        echo "  ⚠️  Telegram failed: $(echo $response | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('description','unknown'))" 2>/dev/null)"
    fi
}

# === WHATSAPP ===
notify_whatsapp() {
    local phone="${WHATSAPP_PHONE:-}"
    local api_key="${WHATSAPP_API_KEY:-}"
    if [ -z "$phone" ] || [ -z "$api_key" ]; then
        return 0
    fi

    local encoded_msg=$(python3 -c "import urllib.parse; print(urllib.parse.quote('''${MESSAGE}'''))" 2>/dev/null)
    if curl -s "https://api.callmebot.com/whatsapp.php?phone=${phone}&text=${encoded_msg}&apikey=${api_key}" \
      -o /dev/null -w "%{http_code}" 2>/dev/null | grep -q "200"; then
        echo "  ✅ WhatsApp sent to ${phone}"
    else
        echo "  ⚠️  WhatsApp failed"
    fi
}

# === MAIN ===
echo "--- Notification ---"
echo "  Title: ${TITLE}"
echo "  Message: ${MESSAGE}"

notify_mac
notify_telegram
notify_whatsapp
