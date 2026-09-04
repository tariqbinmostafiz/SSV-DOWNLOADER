# 📥 SHIFAT'S YouTube Downloader

Download YouTube videos in **Full HD** or audio as **MP3** — straight from the Android **Share Sheet**. Tap Share inside the YouTube app, tap **Termux**, done. ✨

No separate app to open. No commands to type. Just tap and go.

```
+---------------------------+
| Select Download Mode:     |
+---------------------------+
| 1. VIDEO MP4 1080p        |
| 2. AUDIO MP3 Highest      |
+---------------------------+

[██████████░░░░]  68% ⚡14.2MiB/s ⏱00:09
```

---

## ✨ Features

- 🎬 Full HD (≤1080p) video, or 🎵 audio-only MP3 — one tap to choose
- 🎨 Clean, colorful, single-line live progress bar — no clutter, no scroll spam
- 🍪 Bypasses YouTube's bot-detection using your own cookies
- 🖼️ Thumbnail embedded directly into the file (as cover art for MP3, as the poster for MP4)
- 🏷️ Metadata (title, artist, upload date) embedded into audio files
- ⏸️ Resume support — interrupted downloads pick up where they left off
- 🔁 Auto-retry on temporary network failures
- 🗂️ Duplicate protection — won't re-download the same video twice
- ♻️ Self-healing — if you delete a downloaded file, it can be downloaded again automatically
- 💾 Storage check — stops before starting if your phone is nearly full
- 🔔 Optional Android notification when a download finishes (via Termux:API)
- 📁 Auto-organized folder structure — nothing to set up by hand

---

## 📋 Requirements

- An Android phone with **Termux** installed — [get it from F-Droid](https://f-droid.org/packages/com.termux/) (not the outdated Play Store version)
- An internet connection
- ~200 MB free space for installed packages

---

## 🔐 Required Permissions

Before or during setup, grant these — the downloader won't work reliably without them:

| Permission | Why it's needed | How to grant |
|---|---|---|
| 📂 **Storage access** | So Termux can read/write files on your phone (cookies, downloads) | Run `termux-setup-storage` once — tap **Allow** on the popup |
| 🪟 **Display pop-up windows / Autostart** | On Xiaomi/Poco (HyperOS/MIUI) devices, Android blocks apps from opening from the background unless this is explicitly allowed — without it, tapping "Termux" in the Share Sheet may silently fail to open | Go to **Settings → Apps → Termux → Permissions → "Display pop-up windows while running in background"** (or **Autostart**) and enable it |
| 🔋 **Unrestricted battery** | Prevents Android from killing the download mid-way when the screen is off | **Settings → Apps → Termux → Battery → No restrictions / Unrestricted** |
| 🔔 **Notifications** *(optional)* | Only needed if you want a "Download complete" notification | Install **Termux:API** from F-Droid, and allow its notification permission |

> 💡 The pop-up/autostart permission is the one people miss most often — if the Share Sheet shows "Termux" but nothing happens when you tap it, check this first.

---

## 🚀 Installation (Fresh Device — One Script)

1. Install **Termux** from F-Droid and open it once.
2. Grant storage access — this one manual step can't be automated:
   ```bash
   termux-setup-storage
   ```
   Tap **Allow** on the popup.
3. Export your YouTube cookies (see [Cookies Setup](#-cookies-setup) below) and save the file as `cookies.txt` in your phone's **Download** folder.
4. Put `master-setup.sh` in your phone's **Download** folder too.
5. Run the single setup script:
   ```bash
   bash ~/storage/downloads/master-setup.sh
   ```

That's it. This one script installs every required package, copies your cookies into place with the right permissions, and deploys the downloader itself to `~/bin/termux-url-opener`.

6. **Restart Termux once** (close it fully from Recent Apps, reopen) so Android refreshes its Share Sheet targets.

---

## 🍪 Cookies Setup

YouTube blocks unauthenticated/automated requests with errors like *"Sign in to confirm you're not a bot"*. The fix: give the downloader your own logged-in session cookies.

1. On your phone, open a browser that supports extensions (e.g. **Kiwi Browser**).
2. Log into **youtube.com** in that browser.
3. Install the **"Get cookies.txt LOCALLY"** extension.
4. While on youtube.com, open the extension and tap **Export** — use the **youtube.com-only** export, not "Export All Cookies" (which would expose unrelated site sessions you don't need to share).
5. Save the file as `cookies.txt` in your **Download** folder, then run `master-setup.sh` (step 5 above), which copies it into place automatically.

> ⚠️ **Treat `cookies.txt` like a password.** It contains a live login session for your Google/YouTube account — don't share the file. Cookies may need re-exporting every few weeks if the session expires.

---

## ▶️ Usage

1. Open the YouTube app, find a video.
2. Tap **Share** → scroll the app list → tap **Termux**.
3. Choose a mode:
   ```
   [1] Video (Full HD)     [2] Audio only (MP3)
   ```
   Auto-selects Video after 5 seconds if you don't pick.
4. Watch the live progress bar. Press **Enter** when it finishes to close the window.

**📺 Playlists:** sharing a playlist link downloads every video in it automatically. If you share a single video *while a playlist is open* in the app, the link may silently include the whole playlist — back out of playlist view first if you only want one video.

---

## 📂 Output Folder Structure

```
/storage/emulated/0/Download/YouTube/
├── <video files>.mp4
└── Audio/
    └── <audio files>.mp3
```

Created automatically on first run — nothing to set up by hand.

---

## 🔧 Troubleshooting

| Symptom | Likely Cause | Fix |
|---|---|---|
| "Termux" shown in Share Sheet but tapping it does nothing | Missing pop-up/autostart permission | See 🔐 Required Permissions above |
| "Termux" doesn't appear in the Share Sheet at all | Android hasn't refreshed share targets yet | Fully close and reopen Termux once, or reboot the phone |
| `Sign in to confirm you're not a bot` / `HTTP 429` | Missing or expired cookies | Redo 🍪 Cookies Setup |
| Download fails with no clear reason on screen | Full error log kept off-screen for a clean UI | Check the log path printed at the bottom of the failure box |
| Downloads stop when the screen turns off | Battery restriction still active | See 🔐 Required Permissions — set battery to Unrestricted |

---

## ⚠️ Known Limitations

- 📌 **Termux cannot be uninstalled** — the downloader's tools live inside Termux's own storage and aren't relocatable.
- 📌 This isn't a standalone app — it depends on Termux's built-in Share Sheet integration feature.
- 📌 YouTube's bot-detection changes over time; the current cookie + challenge-solver setup works as of this writing but may need future adjustment.
- 📌 Live-stream downloading (capturing an in-progress broadcast) is not currently supported.

---

## 🗂️ Files in This Project

| File | Purpose |
|---|---|
| `master-setup.sh` | One-shot installer — packages, cookies, and the downloader script, all in one run |
| `~/bin/termux-url-opener` | The Share-menu hook script that actually runs the downloads |
| `~/cookies.txt` | Your exported YouTube session cookies (not included — you provide this) |

---

<p align="center">Made for personal use by <b>SHIFAT</b> 🇧🇩</p>
