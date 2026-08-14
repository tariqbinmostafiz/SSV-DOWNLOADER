#!/data/data/com.termux/files/usr/bin/bash
# install.sh — One-shot setup for the YouTube Downloader (Termux Share-Menu Integration)
# Run this once on a fresh Termux install:
#   bash install.sh

set -e

echo "==================================================="
echo "  YouTube Downloader — Fresh Termux Setup"
echo "==================================================="
echo

echo "[1/6] Updating package lists..."
pkg update -y

echo "[2/6] Installing ffmpeg, python, deno..."
pkg install -y ffmpeg python deno

echo "[3/6] Installing/upgrading yt-dlp..."
pip install -U yt-dlp --break-system-packages

echo "[4/6] Granting storage access (a permission popup will appear — tap Allow)..."
termux-setup-storage
sleep 2

echo "[5/6] Creating ~/bin/termux-url-opener (Share-menu hook script)..."
mkdir -p "$HOME/bin"
cat > "$HOME/bin/termux-url-opener" << 'SCRIPT_EOF'
#!/data/data/com.termux/files/usr/bin/bash
# termux-url-opener
# Triggered from Android Share menu -> Termux.
# Colorful, professional, single-line live progress UI.

URL="$1"
# Target folder — /storage/emulated/0/A TRxSHIFAT/Media/YOUTUBE/
# Termux's ~/storage/shared is linked to /storage/emulated/0
SAVE_DIR="$HOME/storage/shared/A TRxSHIFAT/Media/YOUTUBE"
COOKIES="$HOME/cookies.txt"

# Creates the full folder structure if missing, does nothing if it already exists
mkdir -p "$SAVE_DIR"

# ── ANSI colors/styles ──
BOLD='\033[1m'
DIM='\033[2m'
RESET='\033[0m'
RED='\033[1;31m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
BLUE='\033[1;34m'
MAGENTA='\033[1;35m'
CYAN='\033[1;36m'
WHITE='\033[1;37m'
GRAY='\033[0;90m'

BAR_WIDTH=14

clear_line() { printf "\r\033[K"; }

printf "${CYAN}╔═══════════════════════════════════════════╗${RESET}\n"
printf "${CYAN}║${RESET}   ${BOLD}${WHITE}📥 YouTube Downloader — Full HD${RESET}      ${CYAN}║${RESET}\n"
printf "${CYAN}╚═══════════════════════════════════════════╝${RESET}\n\n"

if [ -z "$URL" ]; then
    printf "${RED}${BOLD}✗ No link received.${RESET}\n"
    read -p "Press Enter to close..." _
    exit 1
fi

printf "${BOLD}${BLUE}🔗 Link:${RESET} %s\n\n" "$URL"

# ── Ask: Video or Audio only ──
printf "${BOLD}${WHITE}Download as:${RESET}  ${GREEN}${BOLD}[1] Video (Full HD)${RESET}   ${MAGENTA}${BOLD}[2] Audio only (MP3)${RESET}\n"
printf "${DIM}${BOLD}(Auto-selects Video in 5 seconds if no key pressed)${RESET}\n"
read -t 5 -n 1 -p "> " MODE_CHOICE
echo
echo

if [ "$MODE_CHOICE" = "2" ]; then
    AUDIO_MODE=1
    printf "${MAGENTA}${BOLD}🎵 Audio-only mode selected${RESET}\n\n"
    FORMAT_ARGS=(-x --audio-format mp3 --audio-quality 0)
    SAVE_DIR="$SAVE_DIR/Audio"
    mkdir -p "$SAVE_DIR"
else
    AUDIO_MODE=0
    printf "${GREEN}${BOLD}🎬 Video mode selected${RESET}\n\n"
    FORMAT_ARGS=(-f "bestvideo[height<=1080]+bestaudio/best[height<=1080]" --merge-output-format mp4)
fi

COOKIE_ARGS=()
if [ -f "$COOKIES" ]; then
    COOKIE_ARGS=(--cookies "$COOKIES")
    printf "${GREEN}${BOLD}🍪 Using saved cookies${RESET}\n\n"
else
    printf "${YELLOW}${BOLD}⚠ No cookies.txt found — may hit bot-check${RESET}\n\n"
fi

TPL='download:PROGRESS_LINE %(progress.downloaded_bytes)s %(progress.total_bytes,progress.total_bytes_estimate)s %(progress.speed)s %(progress.eta)s'

human_size() {
    awk -v b="$1" 'BEGIN{
        if (b=="" || b=="None") { print "?"; exit }
        split("B KiB MiB GiB", u, " ")
        i=1
        while (b>=1024 && i<4) { b=b/1024; i++ }
        printf "%.1f%s", b, u[i]
    }'
}

human_speed() {
    awk -v s="$1" 'BEGIN{
        if (s=="" || s=="None") { print "--"; exit }
        split("B/s KiB/s MiB/s GiB/s", u, " ")
        i=1
        while (s>=1024 && i<4) { s=s/1024; i++ }
        printf "%.1f%s", s, u[i]
    }'
}

human_eta() {
    awk -v e="$1" 'BEGIN{
        if (e=="" || e=="None") { print "--:--"; exit }
        e=int(e)
        m=int(e/60); s=e%60
        printf "%02d:%02d", m, s
    }'
}

percent_color() {
    local p="$1"
    if [ "$p" -lt 34 ]; then echo -e "$RED"
    elif [ "$p" -lt 70 ]; then echo -e "$YELLOW"
    else echo -e "$GREEN"
    fi
}

draw_bar() {
    local downloaded="$1" total="$2" speed="$3" eta="$4"
    local percent=0
    if [ -n "$total" ] && [ "$total" != "None" ] && [ "$total" != "0" ]; then
        percent=$(awk -v d="$downloaded" -v t="$total" 'BEGIN{ if(t>0) printf "%d", (d/t)*100; else print 0 }')
    fi
    [ "$percent" -gt 100 ] && percent=100

    local filled=$(( percent * BAR_WIDTH / 100 ))
    local empty=$(( BAR_WIDTH - filled ))
    local pcolor; pcolor=$(percent_color "$percent")

    local bar=""
    local i
    for ((i=0; i<filled; i++)); do bar+="█"; done
    for ((i=0; i<empty; i++)); do bar+="░"; done

    local dsize; dsize=$(human_size "$downloaded")
    local tsize; tsize=$(human_size "$total")
    local spd; spd=$(human_speed "$speed")
    local eta_str; eta_str=$(human_eta "$eta")

    # Everything on a single line — narrow width so it never wraps on
    # narrow phone screens, and \r (carriage return) reliably overwrites
    # the same spot instead of creating new lines.
    clear_line
    printf "${pcolor}[%s]${RESET}${WHITE}${BOLD}%3d%%${RESET} ${MAGENTA}${BOLD}⚡%s${RESET} ${CYAN}${BOLD}⏱%s${RESET}" \
        "$bar" "$percent" "$spd" "$eta_str"
}

STATUS_FILE=$(mktemp)
{
    yt-dlp \
        --remote-components ejs:github \
        --newline \
        --progress-template "$TPL" \
        "${COOKIE_ARGS[@]}" \
        "${FORMAT_ARGS[@]}" \
        -P "$SAVE_DIR" \
        -o "%(title)s.%(ext)s" \
        "$URL"
    echo $? > "$STATUS_FILE"
} | while IFS= read -r line; do
    case "$line" in
        PROGRESS_LINE*)
            set -- $line
            draw_bar "$2" "$3" "$4" "$5"
            ;;
        *)
            clear_line
            printf "\n${GRAY}%s${RESET}\n" "$line"
            ;;
    esac
done

printf "\n\n"
STATUS=$(cat "$STATUS_FILE" 2>/dev/null); rm -f "$STATUS_FILE"

if [ "$STATUS" = "0" ]; then
    printf "${GREEN}╔═══════════════════════════════════════════╗${RESET}\n"
    printf "${GREEN}║${RESET}  ${BOLD}${WHITE}✅ Download complete!${RESET}                     ${GREEN}║${RESET}\n"
    printf "${GREEN}╚═══════════════════════════════════════════╝${RESET}\n"
else
    printf "${RED}╔═══════════════════════════════════════════╗${RESET}\n"
    printf "${RED}║${RESET}  ${BOLD}${WHITE}❌ Download failed (code %s)${RESET}\n" "$STATUS"
    printf "${RED}╚═══════════════════════════════════════════╝${RESET}\n"
fi

read -p "Press Enter to close..." _
SCRIPT_EOF

chmod +x "$HOME/bin/termux-url-opener"

echo "[6/6] Done."
echo
echo "==================================================="
echo "  ✅ Setup complete!"
echo "==================================================="
echo
echo "One manual step remains (cannot be automated):"
echo "  -> Export your YouTube cookies as ~/cookies.txt"
echo "     (see README.md 'Cookies Setup' section)"
echo
echo "Without cookies.txt, downloads may still work for"
echo "many videos, but some will be blocked by YouTube's"
echo "bot-detection until cookies are added."
echo
echo "Once cookies.txt is in place, restart Termux once,"
echo "then test: open YouTube app -> Share -> Termux"
