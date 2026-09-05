# 📥 SHIFAT's SIMPLE VIDEO DOWNLOADER

**SSV DOWNLOADER** — download video or audio from YouTube, Instagram, TikTok, Facebook, X/Twitter, Reddit, Vimeo, Dailymotion, Twitch, Pinterest, Bilibili, and almost any other yt-dlp-supported site — straight from the Android **Share Sheet**. Tap Share, tap **Termux**, done. ✨

No separate app to open. No commands to type. Just tap and go.

```
╔═════════════════════════════════╗
║  SHIFAT' SIMPLE VIDEO DOWNLOADER ║
║      easy · fast · reliable      ║
╚═════════════════════════════════╝

  🔗 Instagram detected

╔═════════════════════════════════╗
║ 1. Video        [1080p]          ║
║ 2. Audio MP3    [Highest]        ║
║ 3. Choose Quality                ║
╚═════════════════════════════════╝

[██████████░░░░]  68% ⚡14.2MiB/s ⏱00:09
```

---

## ✨ Features

- 🌐 **Universal** — works on YouTube, Instagram, TikTok, Facebook, X/Twitter, Reddit, Vimeo, Dailymotion, Twitch, Pinterest, Bilibili, and any other site yt-dlp supports (auto-detects the platform and shows its name)
- 🎬 Full HD (up to 1080p) video, or 🎵 audio-only MP3 — one tap to choose
- 🎚️ **Dynamic quality** — automatically uses the best available resolution up to your default; falls back gracefully if your preferred quality isn't available
- ⚙️ **Choose Quality** option — pick from only the resolutions actually available for that link, saved as your new default
- 🎨 Clean, colorful, single-line live progress bar — no clutter, no scroll spam
- 🍪 Bypasses bot-detection using your own cookies
- 🖼️ Thumbnail embedded directly into the file (cover art for MP3, poster for MP4)
- 🏷️ Metadata embedded into audio files
- ⏸️ Resume support — interrupted downloads pick up where they left off
- 🔁 Auto-retry on temporary network failures
- 🗂️ Robust duplicate protection — the physical file is always the source of truth, not just a log
- ♻️ Self-healing — delete a downloaded file and it can be downloaded again automatically
- 💾 Storage check — stops before starting if your phone is nearly full
- 🔔 Optional Android notification when a download finishes (via Termux:API)
- 📁 Auto-organized folder structure — nothing to set up by hand
- ⚡ No "Press Enter" prompts — single key presses, auto-exits when done

---

## 📋 Requirements

- An Android phone with **Termux** installed — [get it from F-Droid](https://f-droid.org/packages/com.termux/) (not the outdated Play Store version)
- An internet connection
- ~250 MB free space for installed packages

---

## 🔐 Required Permissions

| Permission | Why it's needed | How to grant |
|---|---|---|
| 📂 **Storage access** | So Termux can read/write your cookies and downloaded files | Run `termux-setup-storage` once — tap **Allow** on the popup |
| 🪟 **Display pop-up windows / Autostart** | On Xiaomi/Poco (HyperOS/MIUI) devices, Android blocks apps from opening from the background unless this is explicitly allowed | **Settings → Apps → Termux → Permissions → "Display pop-up windows while running in background"** (or **Autostart**) |
| 🔋 **Unrestricted battery** | Prevents Android from killing the download mid-way when the screen is off | **Settings → Apps → Termux → Battery → No restrictions / Unrestricted** |
| 🔔 **Notifications** *(optional)* | Only needed for a "Download complete" notification | Install **Termux:API** from F-Droid |

> 💡 The pop-up/autostart permission is the one people miss most often — if "Termux" shows in the Share Sheet but tapping it does nothing, check this first.

---

## 🚀 Installation (One Command)

1. Install **Termux** from F-Droid, open it once.
2. Grant storage access (one manual step, can't be automated):
   ```bash
   termux-setup-storage
   ```
3. Run:
   ```bash
   pkg up -y
   pkg install git -y
   git clone https://github.com/tariqbinmostafiz/SSV-DOWNLOADER -b main --single-branch
   cd SSV-DOWNLOADER
   sh install.sh
   ```
4. **Restart Termux once** (close it fully from Recent Apps, reopen) so Android refreshes the Share Sheet.

That's it — `install.sh` installs every required package and sets up cookies + the downloader script with the correct permissions automatically.

> ⚠️ This repo includes a pre-filled `cookies.txt` for convenience across your own devices. Treat it like a shared password — only install this on devices/people you trust.

---

## ▶️ Usage

1. Open any supported app or site, find a video.
2. Tap **Share** → scroll the app list → tap **Termux**.
3. Choose:
   ```
   1. Video        [1080p]
   2. Audio MP3    [Highest]
   3. Choose Quality
   ```
   Auto-selects Video after 5 seconds if you don't pick — no Enter key needed anywhere.
4. Watch the live progress bar. The window closes itself when done.

**📺 Playlists:** sharing a playlist link downloads every item in it automatically.

---

## 📂 Output Folder Structure

```
/storage/emulated/0/Download/SSV DOWNLOAD/
├── <video files>.mp4
└── Audio/
    └── <audio files>.mp3
```

---

## 🔧 Troubleshooting

| Symptom | Likely Cause | Fix |
|---|---|---|
| "Termux" shown in Share Sheet but tapping it does nothing | Missing pop-up/autostart permission | See 🔐 Required Permissions above |
| "Termux" doesn't appear in the Share Sheet at all | Android hasn't refreshed share targets yet | Fully close and reopen Termux once, or reboot |
| `Sign in to confirm you're not a bot` / `HTTP 403 / 429` | Missing/expired cookies, or the site needs browser-impersonation | Re-export cookies; for TikTok/Reddit-style blocks, ensure `curl_cffi` is installed (included in `install.sh`) |
| Reddit shows as "Generic site" and fails | Reddit blocking the request before the platform can even be detected | Often needs cookies specific to that content; not always fixable |
| Download fails with no clear reason on screen | Full error log kept off-screen for a clean UI | Check the log path printed at the bottom of the failure box |
| Downloads stop when the screen turns off | Battery restriction still active | Set battery to Unrestricted (see above) |

---

## ⚠️ Known Limitations

- 📌 **Termux cannot be uninstalled** — the downloader's tools live inside Termux's own storage.
- 📌 Cookies in this repo are YouTube-specific by default; other platforms' private/login-required content won't download unless you add cookies for that site too.
- 📌 Live-stream downloading (capturing an in-progress broadcast) is not currently supported.
- 📌 Bot-detection and site-blocking measures change over time; fixes here reflect what works as of this writing.

---

## 🗂️ Files in This Repository

| File | Purpose |
|---|---|
| `install.sh` | One-shot installer — packages, cookies, and the downloader script |
| `termux-url-opener` | The Share-menu hook script that runs the downloads |
| `cookies.txt` | Exported session cookies (⚠️ sensitive — see warning above) |

---

<p align="center">Made for personal use by <b>SHIFAT</b> 🇧🇩</p> and <b>CLAUDE AI</b> 🔥</p>
