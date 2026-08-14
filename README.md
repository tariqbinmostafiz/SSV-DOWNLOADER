# 📥 YouTube Downloader — Termux Share-Menu Integration

Download YouTube videos (Full HD) or audio (MP3) straight from the Android
**Share Sheet** — tap Share inside the YouTube app, tap **Termux**, done.
No separate app to open, no typing commands. Runs entirely on-device via
[Termux](https://termux.dev) + [yt-dlp](https://github.com/yt-dlp/yt-dlp).

```
[██████████░░░░]  68% ⚡14.2MiB/s ⏱00:09
```

---

## ✨ Features

- Trigger downloads directly from YouTube's native Share menu
- Full HD (≤1080p) video, or audio-only MP3 mode (interactive prompt)
- Live, single-line, color-coded progress bar (red → yellow → green)
- Bypasses YouTube bot-detection using your own browser cookies
- Auto-creates and saves into a fixed folder structure
- Playlist links download the whole playlist automatically
- Zero background daemons — runs live in the foreground so you can watch it

---

## 📋 Requirements

- Android device with **Termux** installed ([F-Droid](https://f-droid.org/packages/com.termux/) build recommended — not the outdated Play Store version)
- Internet connection
- ~150 MB free space for installed packages

---

## 🚀 Installation (Fresh Device — One Command)

1. Install Termux from F-Droid, open it once.
2. Download `install.sh` (provided alongside this README) onto your phone,
   or copy its full contents.
3. In Termux, run:

   ```bash
   bash install.sh
   ```

   This single command will, in order:
   - Update Termux's package lists
   - Install `ffmpeg`, `python`, `deno`
   - Install/upgrade `yt-dlp` via pip
   - Grant storage access (`termux-setup-storage` — tap **Allow** on the popup)
   - Create `~/bin/termux-url-opener` (the Share-menu hook script)
   - Make it executable

4. Restart Termux once (close it fully from Recent Apps, reopen) so Android
   refreshes its list of Share-menu targets.

That's it for the automated part. One manual step remains — see below.

---

## 🍪 Cookies Setup (Manual — Required to Avoid Bot-Detection)

YouTube blocks unauthenticated/automated requests with errors like
`Sign in to confirm you're not a bot` or `HTTP 429`. The fix is to give
yt-dlp your own logged-in session cookies.

1. On your phone, open a Chromium-based mobile browser that supports
   extensions (e.g. **Kiwi Browser**).
2. Log into **youtube.com** in that browser.
3. Install the **"Get cookies.txt LOCALLY"** extension.
4. While on youtube.com, open the extension and tap **Export**
   (use the **youtube.com-only** export — *not* "Export All Cookies",
   which would include unrelated site sessions you don't need to expose).
5. Save the exported file, then move/copy it into Termux as exactly:

   ```
   ~/cookies.txt
   ```

   Example, if it landed in your Downloads folder:
   ```bash
   cp ~/storage/downloads/cookies.txt ~/cookies.txt
   ```

> ⚠️ **Treat `cookies.txt` like a password.** It contains a live login
> session for your Google/YouTube account. Don't share the file. If you
> ever want to invalidate it, sign out of that browser session from your
> Google Account settings.

Cookies may need to be re-exported every few weeks if YouTube invalidates
the session.

---

## ▶️ Usage

1. Open the YouTube app, find a video.
2. Tap **Share**.
3. Scroll the app list and tap **Termux**.
4. A terminal opens showing:
   ```
   Download as:  [1] Video (Full HD)   [2] Audio only (MP3)
   (Auto-selects Video in 5 seconds if no key pressed)
   ```
5. Press `1` (or wait 5 seconds) for video, or `2` for audio-only.
6. Watch the live progress bar. Press **Enter** when done to close.

**Playlists:** sharing a playlist link downloads every video in it
automatically. Note: if you share a single video *while a playlist is
open* in the YouTube app, the link may silently include `&list=...` and
download the whole playlist instead of just that one video — close out
of playlist view first if you only want one video.

---

## 📂 Output Folder Structure

```
/storage/emulated/0/A TRxSHIFAT/Media/YOUTUBE/
├── <video files, .mp4>
└── Audio/
    └── <audio files, .mp3>
```

This structure is created automatically on first run if it doesn't
already exist — nothing to set up manually.

---

## 🔧 Troubleshooting

| Symptom | Likely Cause | Fix |
|---|---|---|
| "Termux" doesn't appear in the Share Sheet | Android hasn't refreshed share targets yet | Fully close and reopen Termux once, or reboot the phone |
| `Sign in to confirm you're not a bot` / `HTTP 429` | Missing/expired cookies | Redo the [Cookies Setup](#-cookies-setup-manual--required-to-avoid-bot-detection) steps |
| `n challenge solving failed` / `Only images are available` | yt-dlp's JS-challenge solver script wasn't fetched | Already handled by `--remote-components ejs:github` in the script; if it still happens, run `yt-dlp -U` and `pkg upgrade deno` |
| Download fails with no clear error | yt-dlp or deno out of date | `pip install -U yt-dlp --break-system-packages` |
| Script says "No link received" | Some apps share differently than expected | Try sharing directly from the YouTube app rather than a browser tab |

Check the last run's full log by scrolling up in the Termux session — the
script prints all yt-dlp output above the progress bar.

---

## ⚠️ Known Limitations

- **Termux cannot be uninstalled** — yt-dlp/ffmpeg/deno live inside
  Termux's app-private storage and are not relocatable to another folder
  due to hardcoded install-prefix paths in how they're built.
- This is not a standalone app; it depends on Termux being installed and
  its Share-menu integration feature.
- YouTube's bot-detection and JS-challenge systems change over time — the
  current fixes (cookies + `--remote-components ejs:github`) resolve
  things as of this writing, but may need future adjustment.

---

## 🗂️ Files in This Project

| File | Purpose |
|---|---|
| `install.sh` | One-shot installer for a fresh Termux setup |
| `~/bin/termux-url-opener` | The actual Share-menu hook script (created by `install.sh`) |
| `~/cookies.txt` | Your exported YouTube session cookies (manual step, not included) |
