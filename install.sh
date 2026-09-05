#!/data/data/com.termux/files/usr/bin/bash
set -e

pkg update -y
apt-get upgrade -y -o Dpkg::Options::="--force-confnew"
pkg install -y python ffmpeg deno atomicparsley

python -m pip install -U yt-dlp --break-system-packages
python -m pip install mutagen --break-system-packages
python -m pip install curl_cffi --break-system-packages

mkdir -p "$HOME/bin"
cp termux-url-opener "$HOME/bin/termux-url-opener"
chmod 700 "$HOME/bin/termux-url-opener"

cp cookies.txt "$HOME/cookies.txt"
chmod 644 "$HOME/cookies.txt"

echo "Setup complete. Restart Termux once, then use Share -> Termux."
