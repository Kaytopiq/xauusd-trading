# XAUUSD Trading Analysis

Proyek analisis harga emas (XAUUSD) real-time menggunakan OpenCode + TradingView + data market. Lengkap dengan monitoring otomatis, state detection, notifikasi, dan sinyal trading.

## Fitur

| Fitur | Deskripsi |
|-------|-----------|
| 📊 **Signal Snapshot** | 1 layar: harga, trend, momentum, volatility gate, key levels |
| 🎯 **Market Monitor** | State detection: NEUTRAL → WATCHING → CONSOLIDATING → SIGNAL |
| 🔄 **Auto Monitor Loop** | Monitoring otomatis tiap 60-120 detik, stop kalo SIGNAL |
| 📈 **Pine Scripts** | 3 strategi siap pakai di TradingView (SR scalper, momentum, template) |
| 🔔 **Notifikasi** | Local macOS notif + WhatsApp (via CallMeBot / webhook) |
| 📝 **Auto Report** | Setiap analisis otomatis tersimpan ke `analysis/` |
| 🚦 **Gate Check** | ATR, session, news, rollover — proteksi sebelum trading |
| 📋 **Trade Logger** | Catat hasil trading interaktif |

## Cara Install

```bash
# 1. Clone project
git clone <repo-url> xauusd-trading
cd xauusd-trading

# 2. Setup otomatis
bash setup.sh

# 3. Isi API key (opsional)
cp config/.env.example config/.env
# Edit config/.env, isi TWELVE_DATA_API_KEY dan WHATSAPP_PHONE jika perlu
```

## Cara Pakai

### Perintah Dasar

```bash
bash run.sh session       # Cek session market
bash run.sh signal        # Snapshot analisis lengkap
bash run.sh monitor       # State detection
bash run.sh news          # Cek gate berita besar
bash run.sh gold          # Candlestick Yahoo Finance
bash run.sh price         # Harga + indikator live
bash run.sh full          # Semua data + auto-save
bash run.sh log           # Catat hasil trading
```

### Monitoring Otomatis

```bash
bash run.sh monitor-loop  # Jalan terus sampai SIGNAL atau kamu stop
```

Script akan:
- Fetch data tiap 60-120 detik (sesuai state)
- Deteksi NEUTRAL / WATCHING / CONSOLIDATING / SIGNAL
- Kirim notifikasi ke macOS + WhatsApp (jika dikonfigurasi)
- Stop otomatis kalo SIGNAL terdeteksi

### Laporan Otomatis

```bash
bash run.sh report        # Generate laporan markdown ke analysis/
```

### Contoh Workflow Harian

```bash
# Pagi: cek kondisi market
bash run.sh session
bash run.sh news
bash run.sh signal

# Pantau terus
bash run.sh monitor-loop

# Kalo dapet sinyal, cek detail
bash run.sh signal

# Abis trading, catat hasil
bash run.sh log
```

## Notifikasi WhatsApp

Untuk notifikasi WhatsApp:

1. Buka WhatsApp → chat ke nomor **+34 603 21 25 97**
2. Kirim pesan: `I allow callmebot to send me messages`
3. Tunggu balasan berisi API key
4. Isi di `config/.env`:
   ```
   WHATSAPP_PHONE="62812xxxxxx"    # nomor kamu (kode negara tanpa +)
   WHATSAPP_API_KEY="xxxxx"         # API key dari CallMeBot
   ```

Atau kamu bisa pakai layanan WhatsApp API lain, tinggal ganti `WHATSAPP_URL` di `.env`.

## Struktur Project

```
xauusd-trading/
├── run.sh                    # Main runner
├── setup.sh                  # Setup otomatis
├── README.md                 # Dokumentasi
├── .gitignore
│
├── scripts/
│   ├── signal.sh             # Signal snapshot
│   ├── monitor.sh            # State detection
│   ├── monitor_loop.sh       # Auto monitoring loop
│   ├── session.sh            # Session checker
│   ├── news_gate.sh          # News gate checker
│   ├── notify.sh             # Notifikasi (local + WA)
│   ├── report.sh             # Auto report generator
│   ├── log_trade.sh          # Trade logger
│   └── setup.sh              # (fallback)
│
├── config/
│   ├── .env.example          # Template konfigurasi
│   └── skills-lock.json
│
├── pine/
│   ├── xauusd_scalping_template.pine
│   ├── xauusd_scalper_sr.pine
│   └── xauusd_scalper_momentum.pine
│
├── analysis/                 # Auto-saved analysis files
├── data/                     # Trade logs & data
└── .agents/                  # OpenCode skills
```

## Persyaratan

- Python 3
- curl
- bash 4+
- macOS (untuk local notification)

## Disclaimer

Ini untuk tujuan edukasi dan analisis. Bukan rekomendasi investasi. Trading emas memiliki risiko tinggi. Selalu gunakan paper trading dulu.
