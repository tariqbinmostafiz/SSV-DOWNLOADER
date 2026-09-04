#!/data/data/com.termux/files/usr/bin/bash
set -e

pkg update -y
apt-get upgrade -y -o Dpkg::Options::="--force-confnew"
pkg install -y python ffmpeg deno atomicparsley
python -m pip install -U yt-dlp --break-system-packages
python -m pip install mutagen --break-system-packages

COOKIE_SRC="$HOME/storage/downloads/cookies.txt"
COOKIE_DEST="$HOME/cookies.txt"

if [ -f "$COOKIE_SRC" ]; then
    cp "$COOKIE_SRC" "$COOKIE_DEST"
    chmod 644 "$COOKIE_DEST"
fi

mkdir -p "$HOME/bin"
cat > "$HOME/bin/termux-url-opener" << 'SCRIPT_EOF'
#!/data/data/com.termux/files/usr/bin/bash

URL="$1"
SAVE_DIR="$HOME/storage/downloads/YouTube"
COOKIES="$HOME/cookies.txt"

ARCHIVE_DIR="$HOME/.config/ytdl-downloader"
mkdir -p "$ARCHIVE_DIR"

mkdir -p "$SAVE_DIR"

BOLD=$'\033[1m'
DIM=$'\033[2m'
RESET=$'\033[0m'
RED=$'\033[1;31m'
GREEN=$'\033[1;32m'
YELLOW=$'\033[1;33m'
BLUE=$'\033[1;34m'
MAGENTA=$'\033[1;35m'
CYAN=$'\033[1;36m'
WHITE=$'\033[1;37m'
GRAY=$'\033[0;90m'

BAR_WIDTH=18

clear_line() { printf "\r\033[K"; }

notify() {
    if command -v termux-notification >/dev/null 2>&1; then
        termux-notification -t "YouTube Downloader" -c "$1" >/dev/null 2>&1 || true
    fi
}

check_storage() {
    local target_dir="$1"
    local min_free_kb=512000
    local available_kb
    available_kb=$(df -Pk "$target_dir" 2>/dev/null | tail -1 | awk '{print $4}')
    if [ -n "$available_kb" ] && [ "$available_kb" -lt "$min_free_kb" ] 2>/dev/null; then
        printf "${RED}${BOLD}✗ Low storage — less than ~500MB free. Download stopped.${RESET}\n"
        read -p "Press Enter to close..." _
        exit 1
    fi
}

printf "${CYAN}╔═══════════════════════════════════════════╗${RESET}\n"
printf "${CYAN}║${RESET}  ${BOLD}${WHITE}📥 SHIFAT'S YouTube Downloader — FHD  ${RESET}   ${CYAN}║${RESET}\n"
printf "${CYAN}╚═══════════════════════════════════════════╝${RESET}\n\n"

if [ -z "$URL" ]; then
    printf "${RED}${BOLD}✗ No link received.${RESET}\n"
    read -p "Press Enter to close..." _
    exit 1
fi

COOKIE_ARGS=()
COOKIE_TMP=""
if [ -f "$COOKIES" ]; then
    COOKIE_TMP=$(mktemp)
    cp "$COOKIES" "$COOKIE_TMP" 2>/dev/null
    COOKIE_ARGS=(--cookies "$COOKIE_TMP")
    printf "${GREEN}${BOLD}╭──────────────────────────╮${RESET}\n"
    printf "${GREEN}${BOLD}│  🍪 Using saved cookies  │${RESET}\n"
    printf "${GREEN}${BOLD}╰──────────────────────────╯${RESET}\n\n"
else
    printf "${YELLOW}${BOLD}╭──────────────────────────────╮${RESET}\n"
    printf "${YELLOW}${BOLD}│  ⚠ No cookies.txt found      │${RESET}\n"
    printf "${YELLOW}${BOLD}╰──────────────────────────────╯${RESET}\n\n"
fi

printf "${WHITE}${BOLD}+---------------------------+${RESET}\n"
printf "${WHITE}${BOLD}| Select Download Mode:     |${RESET}\n"
printf "${WHITE}${BOLD}+---------------------------+${RESET}\n"
printf "${WHITE}${BOLD}| ${GREEN}1. VIDEO MP4 1080p${WHITE}       |${RESET}\n"
printf "${WHITE}${BOLD}| ${MAGENTA}2. AUDIO MP3 Highest${WHITE}     |${RESET}\n"
printf "${WHITE}${BOLD}+---------------------------+${RESET}\n"
printf "${DIM}${BOLD}(Auto-selects Video in 5 seconds )${RESET}\n"
read -t 5 -n 1 -p "> " MODE_CHOICE
echo
echo

if [ "$MODE_CHOICE" = "2" ]; then
    printf "${MAGENTA}${BOLD}  🎵 Audio-only mode selected${RESET}\n\n"
    FORMAT_ARGS=(-x --audio-format mp3 --audio-quality 0 --embed-thumbnail --embed-metadata)
    ARCHIVE_FILE="$ARCHIVE_DIR/audio-archive.txt"
    MAP_FILE="$ARCHIVE_DIR/audio-map.txt"
    SAVE_DIR="$SAVE_DIR/Audio"
    mkdir -p "$SAVE_DIR"
else
    printf "${GREEN}${BOLD}   🎬 Video mode selected${RESET}\n\n"
    FORMAT_ARGS=(-f "bestvideo[height<=1080]+bestaudio/best[height<=1080]" --merge-output-format mp4 --embed-thumbnail)
    ARCHIVE_FILE="$ARCHIVE_DIR/video-archive.txt"
    MAP_FILE="$ARCHIVE_DIR/video-map.txt"
fi

check_storage "$SAVE_DIR"

touch "$ARCHIVE_FILE" "$MAP_FILE" 2>/dev/null
CHECK_ID=$(yt-dlp --get-id --no-warnings --playlist-items 1 --remote-components ejs:github "${COOKIE_ARGS[@]}" "$URL" 2>/dev/null | head -1)
if [ -n "$CHECK_ID" ] && grep -q "$CHECK_ID" "$ARCHIVE_FILE" 2>/dev/null; then
    STORED_NAME=$(awk -F'\t' -v id="$CHECK_ID" '$1==id{print $2; exit}' "$MAP_FILE" 2>/dev/null)
    if [ -n "$STORED_NAME" ] && [ ! -f "$SAVE_DIR/$STORED_NAME" ]; then
        sed -i "/$CHECK_ID/d" "$ARCHIVE_FILE" 2>/dev/null
        sed -i "/^$CHECK_ID"$'\t'"/d" "$MAP_FILE" 2>/dev/null
        printf "${YELLOW}${BOLD}↻ Previously downloaded file was removed — downloading again${RESET}\n\n"
    fi
fi

RELIABILITY_ARGS=(--continue --retries 10 --fragment-retries 10 --download-archive "$ARCHIVE_FILE")

MOVE_ARGS=(--exec "after_move:bash -c 'mv -- \"\$1\" \"\$2/\" && printf \"%s\\t%s\\n\" \"\$3\" \"\$(basename \"\$1\")\" >> \"\$4\"' _ %(filepath)q '$SAVE_DIR' %(id)q '$MAP_FILE'")


DOWNLOAD_TMP_DIR="$HOME/.cache/ytdl-tmp"
mkdir -p "$DOWNLOAD_TMP_DIR"

find "$DOWNLOAD_TMP_DIR" -type f -mmin +1440 -delete 2>/dev/null

TPL='download:PROGRESS_LINE %(progress.downloaded_bytes)s %(progress.total_bytes,progress.total_bytes_estimate)s %(progress.speed)s %(progress.eta)s'

LOG_FILE="$DOWNLOAD_TMP_DIR/last-run.log"

LAST_STAGE=""
ERROR_FILE=$(mktemp)
show_stage() {
    local stage="$1"
    if [ -n "$stage" ] && [ "$stage" != "$LAST_STAGE" ]; then
        clear_line
        printf "\n%s\n\n" "$stage"
        LAST_STAGE="$stage"
    fi
}
classify_line() {
    local line="$1"
    case "$line" in
        *"Extracting URL"*)
            show_stage "${CYAN}${BOLD}   🔎 Extracting video${RESET}" ;;
        *"Downloading webpage"*|*"Downloading"*"player"*"API JSON"*|*"Downloading player "*|*"Downloading initial data"*|*"Downloading iframe"*|*"Solving JS challenges"*)
            show_stage "${CYAN}${BOLD}   🧩 Preparing stream${RESET}" ;;
        *"[download] Destination:"*|*"Downloading 1 format"*|*"Downloading "*"format(s)"*)
            show_stage "${BLUE}${BOLD}   📥 Downloading${RESET}" ;;
        *"[Merger] Merging formats"*)
            show_stage "${MAGENTA}${BOLD}   🔧 Merging video & audio${RESET}" ;;
        *"[EmbedThumbnail]"*|*"ThumbnailsConvertor"*|*"thumbnail"*)
            show_stage "${YELLOW}${BOLD}   🖼 Embedding thumbnail${RESET}" ;;
        *"[Metadata]"*|*"metadata"*)
            show_stage "${YELLOW}${BOLD}   🏷 Embedding metadata${RESET}" ;;
        *"[Exec]"*)
            show_stage "${GREEN}${BOLD}   📦 Finalizing${RESET}" ;;
        *"has already been recorded in the archive"*)
            show_stage "${GREEN}${BOLD}✅ Already downloaded — skipping${RESET}" ;;
        *"ERROR:"*)
            echo "$line" > "$ERROR_FILE" ;;
        *) : ;;
    esac
}

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
        "${RELIABILITY_ARGS[@]}" \
        "${MOVE_ARGS[@]}" \
        -P "$DOWNLOAD_TMP_DIR" \
        -o "%(title)s.%(ext)s" \
        "$URL"
    echo $? > "$STATUS_FILE"
} | tee "$LOG_FILE" | while IFS= read -r line; do
    case "$line" in
        PROGRESS_LINE*)
            set -- $line
            draw_bar "$2" "$3" "$4" "$5"
            ;;
        *)
            classify_line "$line"
            ;;
    esac
done

printf "\n\n"
STATUS=$(cat "$STATUS_FILE" 2>/dev/null); rm -f "$STATUS_FILE"
LAST_ERROR=$(cat "$ERROR_FILE" 2>/dev/null); rm -f "$ERROR_FILE"
[ -n "$COOKIE_TMP" ] && rm -f "$COOKIE_TMP"

if [ "$STATUS" = "0" ]; then
    printf "${GREEN}╔═══════════════════════════════════════════╗${RESET}\n"
    printf "${GREEN}║${RESET}        ${BOLD}${WHITE}✅  DOWNLOAD COMPLETE${RESET}                ${GREEN}║${RESET}\n"
    printf "${GREEN}╚═══════════════════════════════════════════╝${RESET}\n"
    notify "✅ Download complete"
else
    printf "${RED}╔═══════════════════════════════════════════╗${RESET}\n"
    printf "${RED}║${RESET}         ${BOLD}${WHITE}❌  DOWNLOAD FAILED${RESET}                 ${RED}║${RESET}\n"
    printf "${RED}╚═══════════════════════════════════════════╝${RESET}\n"
    if [ -n "$LAST_ERROR" ]; then
        SHORT_REASON=$(printf '%s' "$LAST_ERROR" | sed -E 's/^ERROR: \[[a-z]+\] [^:]*: //')
        printf "${DIM}${RED}Reason: %s${RESET}\n" "$SHORT_REASON"
    fi
    printf "${DIM}Full details: %s${RESET}\n" "$LOG_FILE"
    notify "❌ Download failed"
fi

read -p "Press Enter to close..." _
SCRIPT_EOF
chmod 700 "$HOME/bin/termux-url-opener"

echo "Setup complete."
