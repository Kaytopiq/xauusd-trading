#!/bin/bash
# XAUUSD Notification System
# Kirim notifikasi ke macOS + WhatsApp (jika dikonfigurasi)
# Usage: bash scripts/notify.sh "Pesan notifikasi" [title]

ENV_FILE="config/.env"
if [ -f "$ENV_FILE" ]; then
    set -a
    source "$ENV_FILE"
    set +a
fi

MESSAGE="${1:-XAUUSD Notification}"
TITLE="${2:-XAUUSD Monitor}"

# === macOS LOCAL NOTIFICATION ===
notify_mac() {
    if command -v osascript &>/dev/null; then
        osascript -e "display notification \"${MESSAGE}\" with title \"${TITLE}\""
        echo "  ✅ Local notification sent"
    fi
}

# === WHATSAPP NOTIFICATION ===
notify_whatsapp() {
    local phone="${WHATSAPP_PHONE:-}"
    local api_key="${WHATSAPP_API_KEY:-}"
    local url="${WHATSAPP_URL:-https://api.callmebot.com/whatsapp.php}"

    if [ -z "$phone" ] || [ -z "$api_key" ]; then
        return 0  # skip if not configured
    fi

    local encoded_msg=$(python3 -c "import urllib.parse; print(urllib.parse.quote('''${MESSAGE}'''))" 2>/dev/null)
    
    if curl -s "${url}?phone=${phone}&text=${encoded_msg}&apikey=${api_key}" \
      -o /dev/null -w "%{http_code}" 2>/dev/null | grep -q "200"; then
        echo "  ✅ WhatsApp notification sent to ${phone}"
    else
        echo "  ⚠️  WhatsApp notification failed"
    fi
}

# Main
echo "--- Notification ---"
echo "  Title: ${TITLE}"
echo "  Message: ${MESSAGE}"

notify_mac
notify_whatsapp
